const presets = Object.fromEntries((window.ELIG_PRESETS || []).map((p) => [p.id, p]));

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
}

function applyPreset(id) {
  const p = presets[id] || presets.aaa;
  ["MemberId", "LastName", "FirstName", "BirthDate", "Gender"].forEach((k) => {
    const el = document.getElementById(k);
    if (el) el.value = p[k] || "";
  });
}

function renderList(el, items) {
  if (!items || !items.length) {
    el.innerHTML = "<p class='muted'>None yet</p>";
    return;
  }
  el.innerHTML = items
    .map(
      (i) =>
        `<article><strong>${escapeHtml(i.name)}</strong><div class="muted">${i.bytes || 0} bytes</div><pre>${escapeHtml(
          i.preview || ""
        )}</pre></article>`
    )
    .join("");
}

async function refreshArtifacts() {
  const data = await getJson("/api/status");
  renderList(document.getElementById("list-requests"), data.requests || []);
  renderList(document.getElementById("list-270"), data.edi270 || []);
  renderList(document.getElementById("list-271"), data.edi271 || []);
  renderList(document.getElementById("list-responses"), data.responses || []);
}

function findStep(steps, name) {
  return (steps || []).find((s) => s.step === name);
}

function showResult(data) {
  const banner = document.getElementById("result-banner");
  const summary = data.summary || {};
  const theater = summary.theater || "";
  if (theater === "aaa_error") {
    const aaa = (summary.aaa && summary.aaa[0]) || {};
    banner.innerHTML = `<div class="theater-aaa"><span class="pill bad">AAA REJECT</span>
      <p><strong>${escapeHtml(aaa.rejectReasonLabel || "Eligibility rejected")}</strong>
      (AAA03=${escapeHtml(aaa.rejectReason || "?")}, follow-up=${escapeHtml(aaa.followUp || "?")})</p>
      <p class="muted">${escapeHtml(summary.message || "")}</p>
      <p>Try the <em>OK001</em> preset for a successful 271 with EB benefits.</p></div>`;
  } else if (theater === "success" || summary.status === "active") {
    const bens = (summary.benefits || [])
      .map((b) => `<li>${escapeHtml(b.label || b.eb01)} <span class="muted">(${escapeHtml(b.eb01)}/${escapeHtml(b.eb02 || "")}/${escapeHtml(b.eb03 || "")})</span></li>`)
      .join("");
    banner.innerHTML = `<div class="theater-ok"><span class="pill good">ACTIVE</span>
      <p><strong>${escapeHtml(summary.firstName || "")} ${escapeHtml(summary.lastName || "")}</strong>
      · Member ${escapeHtml(summary.memberId || "")}</p>
      <ul>${bens || "<li>No EB rows parsed</li>"}</ul>
      <p class="muted">${escapeHtml(summary.message || "")}</p></div>`;
  } else {
    banner.innerHTML = `<pre>${escapeHtml(JSON.stringify(summary, null, 2))}</pre>`;
  }

  const req = findStep(data.steps, "request_xml");
  const s270 = findStep(data.steps, "build_270");
  const s271 = findStep(data.steps, "payer_271");
  const sum = findStep(data.steps, "parse_271");
  document.getElementById("step-request").textContent = (req && req.body) || "—";
  document.getElementById("step-270").textContent = (s270 && s270.body) || "—";
  document.getElementById("step-271").textContent = (s271 && s271.body) || "—";
  document.getElementById("step-summary").textContent =
    (sum && sum.body) || JSON.stringify(summary, null, 2) || "—";
}

document.getElementById("preset").addEventListener("change", (e) => applyPreset(e.target.value));
applyPreset(document.getElementById("preset").value);

document.getElementById("btn-check").addEventListener("click", async () => {
  const status = document.getElementById("status");
  status.textContent = "Checking eligibility…";
  const body = {
    MemberId: document.getElementById("MemberId").value,
    LastName: document.getElementById("LastName").value,
    FirstName: document.getElementById("FirstName").value,
    BirthDate: document.getElementById("BirthDate").value,
    Gender: document.getElementById("Gender").value,
    ServiceTypeCode: document.getElementById("ServiceTypeCode").value || "30",
  };
  try {
    const res = await fetch("/api/check-eligibility", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!res.ok || !data.ok) {
      status.textContent = data.error || "Check failed";
      if (data.steps) showResult(data);
      return;
    }
    status.textContent = "Done";
    showResult(data);
    refreshArtifacts().catch(() => {});
  } catch (e) {
    status.textContent = e.message;
  }
});

document.getElementById("btn-refresh").addEventListener("click", () => {
  refreshArtifacts().catch((e) => {
    document.getElementById("status").textContent = e.message;
  });
});

function showTab(tab) {
  document.querySelectorAll(".tab").forEach((b) => {
    const on = b.dataset.tab === tab;
    b.classList.toggle("active", on);
    b.setAttribute("aria-selected", on ? "true" : "false");
  });
  document.getElementById("tab-demo").hidden = tab !== "demo";
  document.getElementById("tab-routes").hidden = tab !== "routes";
  const xslt = document.getElementById("tab-xslt");
  if (xslt) xslt.hidden = tab !== "xslt";
  const info = document.getElementById("tab-info");
  if (info) info.hidden = tab !== "info";
  document.body.classList.toggle("routes-mode", tab === "routes" || tab === "xslt");
  if (tab === "routes") loadRoutesTab().catch((e) => (document.getElementById("routes-status").textContent = e.message));
  if (tab === "xslt") loadXsltTab().catch(() => {});
}

document.querySelectorAll(".tab").forEach((btn) => btn.addEventListener("click", () => showTab(btn.dataset.tab)));

let routesLoaded = false;
let activeRouteId = "";

async function loadRoutesTab() {
  const status = document.getElementById("routes-status");
  const select = document.getElementById("route-select");
  const frame = document.getElementById("route-viewer-frame");
  const layout = "pipeline";
  if (!routesLoaded) {
    const data = await getJson("/api/v2/routes");
    select.innerHTML = (data.routes || [])
      .map((r) => `<option value="${r.id}">${escapeHtml(r.name)}</option>`)
      .join("");
    routesLoaded = true;
    select.addEventListener("change", () => {
      activeRouteId = select.value;
      frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(activeRouteId)}&mode=docs&layout=${layout}&config=changed`;
    });
  }
  if (select.options.length) {
    activeRouteId = select.value;
    frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(activeRouteId)}&mode=docs&layout=${layout}&config=changed`;
    status.textContent = `${select.options.length} route(s)`;
  } else {
    status.textContent = "No route.v2.xml yet — run tools/convert_routes_to_v2.py";
  }
}

async function loadXsltTab() {
  const select = document.getElementById("xslt-select");
  const view = document.getElementById("xslt-view");
  const status = document.getElementById("xslt-status");
  if (!select || select.dataset.loaded === "1") return;
  const data = await getJson("/api/v2/xslt");
  select.innerHTML = (data.files || [])
    .map((f) => `<option value="${escapeHtml(f.path)}">${escapeHtml(f.path)}</option>`)
    .join("");
  select.dataset.loaded = "1";
  async function show() {
    const path = select.value;
    if (!path) return;
    const res = await fetch(`/api/v2/xslt/content?path=${encodeURIComponent(path)}`);
    view.textContent = await res.text();
    status.textContent = path;
    const pathEl = document.getElementById("xslt-path");
    if (pathEl) pathEl.textContent = path;
  }
  select.addEventListener("change", () => show().catch((e) => (status.textContent = e.message)));
  await show();
}

refreshArtifacts().catch(() => {});
