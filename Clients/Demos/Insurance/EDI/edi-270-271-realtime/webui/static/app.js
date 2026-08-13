async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
}

function setStatus(msg, isError) {
  const el = document.getElementById("status");
  if (!el) return;
  el.textContent = msg || "";
  el.classList.toggle("is-error", !!isError);
}

function applyPreset() {
  const sel = document.getElementById("preset");
  const opt = sel && sel.selectedOptions[0];
  if (!opt) return;
  const map = {
    MemberId: "member",
    LastName: "last",
    FirstName: "first",
    BirthDate: "dob",
    Gender: "gender",
  };
  Object.entries(map).forEach(([id, key]) => {
    const el = document.getElementById(id);
    if (el) el.value = opt.dataset[key] || "";
  });
}

function showBanner(summary) {
  const el = document.getElementById("result-banner");
  if (!el) return;
  const status = (summary && summary.status) || "";
  if (status === "rejected") {
    const aaa = (summary.aaa && summary.aaa[0]) || {};
    el.className = "theater-aaa";
    el.textContent = `AAA ${aaa.rejectReason || ""} — ${aaa.rejectReasonLabel || "rejected"}`;
  } else if (status === "active") {
    el.className = "theater-ok";
    el.textContent = summary.message || "Member is active.";
  } else {
    el.className = "";
    el.textContent = "";
  }
}

function bindRouteViewerResize() {
  if (window.__routeViewerResizeBound) return;
  window.__routeViewerResizeBound = true;
  window.addEventListener("message", (ev) => {
    const data = ev.data || {};
    if (data.type !== "route-viewer-size") return;
    const frame = document.getElementById("route-viewer-frame");
    if (!frame || !data.height) return;
    const minH = Math.max(360, Math.floor(window.innerHeight - 120));
    frame.style.height = `${Math.max(Math.ceil(data.height), minH)}px`;
  });
}

let routesLoaded = false;

async function loadRoutesTab() {
  const select = document.getElementById("route-select");
  const frame = document.getElementById("route-viewer-frame");
  const status = document.getElementById("routes-status");
  if (!select || !frame) return;
  bindRouteViewerResize();
  if (!routesLoaded) {
    const data = await getJson("/api/v2/routes");
    select.innerHTML = (data.routes || [])
      .map((r) => `<option value="${r.id}">${r.name}</option>`)
      .join("");
    routesLoaded = true;
    select.addEventListener("change", () => {
      if (!select.value) return;
      frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=pipeline&config=changed`;
    });
  }
  if (select.options.length) {
    frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=pipeline&config=changed`;
    if (status && !document.body.classList.contains("pf-live-construction")) {
      status.textContent = `${select.options.length} route(s)`;
    }
  }
}

function showTab(tab) {
  document.querySelectorAll(".main-tab").forEach((b) => {
    const on = b.dataset.mainTab === tab;
    b.classList.toggle("active", on);
    b.setAttribute("aria-selected", on ? "true" : "false");
  });
  ["demo", "routes", "timing", "info"].forEach((id) => {
    const el = document.getElementById(`tab-${id}`);
    if (el) el.hidden = tab !== id;
  });
  document.body.classList.toggle("routes-mode", tab === "routes");
  if (tab === "routes") {
    loadRoutesTab().catch((err) => {
      const status = document.getElementById("routes-status");
      if (status) status.textContent = err.message || String(err);
    });
  }
}

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => showTab(btn.dataset.mainTab));
});

const preset = document.getElementById("preset");
if (preset) {
  preset.addEventListener("change", applyPreset);
  applyPreset();
}

const form = document.getElementById("check-form");
if (form) {
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    setStatus("Checking eligibility (one round-trip)…");
    try {
      const body = {
        MemberId: document.getElementById("MemberId").value,
        LastName: document.getElementById("LastName").value,
        FirstName: document.getElementById("FirstName").value,
        BirthDate: document.getElementById("BirthDate").value,
        Gender: document.getElementById("Gender").value,
      };
      const result = await getJson("/api/check-eligibility", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const byStep = Object.fromEntries((result.steps || []).map((s) => [s.step, s.body || ""]));
      document.getElementById("step-request").textContent = byStep.request_xml || "—";
      document.getElementById("step-270").textContent = byStep.build_270 || "—";
      document.getElementById("step-271").textContent = byStep.payer_271 || "—";
      document.getElementById("step-summary").textContent = JSON.stringify(result.summary || {}, null, 2);
      showBanner(result.summary);
      const ms = result.elapsedMs != null ? ` ${result.elapsedMs} ms.` : "";
      setStatus(result.ok ? `Done.${ms}` : "Check failed.");
    } catch (err) {
      setStatus(err.message || String(err), true);
    }
  });
}

async function loadHealth() {
  const note = document.getElementById("health-note");
  if (!note) return;
  try {
    const h = await getJson("/api/health");
    note.textContent = `${h.eip ? "EIP up" : "EIP starting"} · ${h.payer ? "payer up" : "payer starting"}`;
  } catch (err) {
    note.textContent = err.message || String(err);
  }
}

loadHealth();
setInterval(loadHealth, 8000);
