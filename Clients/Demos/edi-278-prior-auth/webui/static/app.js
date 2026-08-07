async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
}

function setStatus(msg, isError) {
  const el = document.getElementById("status");
  el.textContent = msg || "";
  el.style.color = isError ? "#fca5a5" : "";
}

function renderFiles(containerId, viewId, files) {
  const list = document.getElementById(containerId);
  const view = document.getElementById(viewId);
  list.innerHTML = "";
  if (!files.length) {
    view.textContent = "(none yet)";
    return;
  }
  files.slice(0, 16).forEach((f, i) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.textContent = f.name;
    btn.addEventListener("click", () => {
      [...list.querySelectorAll("button")].forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      view.textContent = f.content;
    });
    list.appendChild(btn);
    if (i === 0) {
      btn.classList.add("active");
      view.textContent = f.content;
    }
  });
}

function renderAuth(rows) {
  const view = document.getElementById("auth-view");
  if (!rows || !rows.length) {
    view.textContent = "(no AuthRequest rows — is SQL up?)";
    return;
  }
  const lines = rows.map((r) => {
    const name = `${r.PatientLastName || ""},${r.PatientFirstName || ""}`.replace(/,$/, "");
    const dx = r.DiagnosisCode || "(none)";
    return `${r.AuthTraceNumber}\t ${r.ProcedureCode}\t dx=${dx}\t att=${r.AttachmentFlag}\t status=${r.Status}\t ${name}`;
  });
  view.textContent = lines.join("\n");
}

async function refresh() {
  const [approved, denied, incomplete, pended, responses, notices] = await Promise.all([
    getJson("/api/approved"),
    getJson("/api/denied"),
    getJson("/api/incomplete"),
    getJson("/api/pended"),
    getJson("/api/responses"),
    getJson("/api/ehr-notices"),
  ]);
  renderFiles("approved-list", "approved-view", approved.files || []);
  renderFiles("denied-list", "denied-view", denied.files || []);
  renderFiles("incomplete-list", "incomplete-view", incomplete.files || []);
  renderFiles("pended-list", "pended-view", pended.files || []);
  renderFiles("response-list", "response-view", responses.files || []);
  renderFiles("oru-list", "oru-view", notices.files || []);
}

async function refreshAuth() {
  const data = await getJson("/api/auth-requests");
  renderAuth(data.rows || []);
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const select = document.getElementById("sample");
  (data.files || []).forEach((f) => {
    const opt = document.createElement("option");
    opt.value = f.name;
    opt.textContent = f.name;
    select.appendChild(opt);
  });
  select.addEventListener("change", () => {
    const name = select.value;
    const match = (data.files || []).find((f) => f.name === name);
    document.getElementById("edi").value = match ? match.content : "";
  });
  if (data.files && data.files[0]) {
    select.value = data.files[0].name;
    document.getElementById("edi").value = data.files[0].content;
  }
}

document.getElementById("inject-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const sample = document.getElementById("sample").value;
  const edi = document.getElementById("edi").value;
  setStatus("Submitting…");
  try {
    const result = await getJson("/api/inject", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sample, edi }),
    });
    setStatus(`Dropped ${result.file}. Waiting for decisions…`);
    await getJson("/api/wait-results?total=4&timeout=120");
    setStatus("Prior-auth outputs ready");
    await Promise.all([refresh(), refreshAuth()]);
  } catch (err) {
    setStatus(err.message || String(err), true);
  }
});

document.getElementById("refresh-btn").addEventListener("click", () => {
  refresh().catch((err) => setStatus(err.message, true));
});
document.getElementById("refresh-auth-btn").addEventListener("click", () => {
  refreshAuth().catch((err) => setStatus(err.message, true));
});

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

let routesLoaded = false;

function bindRouteViewerResize() {
  if (window.__routeViewerResizeBound) return;
  window.__routeViewerResizeBound = true;
  window.addEventListener("message", (ev) => {
    const data = ev.data || {};
    if (data.type !== "route-viewer-size") return;
    const frame = document.getElementById("route-viewer-frame");
    if (!frame || !data.height) return;
    const minH = Math.max(360, Math.floor(window.innerHeight - 120));
    const h = Math.max(Math.ceil(data.height), minH);
    frame.style.height = `${h}px`;
    frame.style.minHeight = `${h}px`;
  });
}

async function loadRoutesTab() {
  const select = document.getElementById("route-select");
  const frame = document.getElementById("route-viewer-frame");
  const status = document.getElementById("routes-status");
  if (!select || !frame) return;
  const layout = "pipeline";
  bindRouteViewerResize();
  if (!routesLoaded) {
    const data = await getJson("/api/v2/routes");
    select.innerHTML = (data.routes || [])
      .map((r) => `<option value="${escapeHtml(r.id)}">${escapeHtml(r.name || r.dir)}</option>`)
      .join("");
    routesLoaded = true;
    select.addEventListener("change", () => {
      if (!select.value) return;
      frame.style.height = "";
      frame.style.minHeight = "";
      frame.src =
        `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}` +
        `&mode=docs&layout=${layout}&config=compact&groups=1&collapse=all`;
    });
  }
  if (select.options.length) {
    frame.style.height = "";
    frame.style.minHeight = "";
    frame.src =
      `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}` +
      `&mode=docs&layout=${layout}&config=compact&groups=1&collapse=all`;
    if (status) status.textContent = `${select.options.length} route(s)`;
  } else if (status) {
    status.textContent = "No route.v2.xml yet";
  }
}

function bindMainTabs() {
  const tabs = [...document.querySelectorAll(".main-tab")];
  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      const id = tab.getAttribute("data-main-tab");
      tabs.forEach((t) => {
        const on = t === tab;
        t.classList.toggle("active", on);
        t.setAttribute("aria-selected", on ? "true" : "false");
      });
      ["demo", "routes", "xslt", "info"].forEach((name) => {
        const panel = document.getElementById(`tab-${name}`);
        if (panel) panel.hidden = name !== id;
      });
      const nav = document.getElementById("demo-nav");
      if (nav) nav.style.display = id === "demo" ? "" : "none";
      if (id === "routes") {
        loadRoutesTab().catch((err) => {
          const status = document.getElementById("routes-status");
          if (status) status.textContent = err.message || String(err);
        });
      }
      if (id === "xslt") loadXslt().catch(() => {});
    });
  });
}

async function loadXslt() {
  const data = await getJson("/api/v2/xslt");
  const list = document.getElementById("xslt-list");
  const view = document.getElementById("xslt-view");
  if (!list) return;
  list.innerHTML = "";
  const files = data.files || [];
  if (!files.length) {
    view.textContent = "(none)";
    return;
  }
  for (const [i, f] of files.entries()) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.textContent = f.path || f.name;
    btn.addEventListener("click", async () => {
      [...list.querySelectorAll("button")].forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      const res = await fetch(`/api/v2/xslt/content?path=${encodeURIComponent(f.path)}`);
      view.textContent = await res.text();
    });
    list.appendChild(btn);
    if (i === 0) btn.click();
  }
}

bindMainTabs();
loadSamples()
  .then(() => Promise.all([refresh(), refreshAuth()]))
  .catch((err) => setStatus(err.message, true));
