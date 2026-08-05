async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
}

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function renderList(el, items) {
  if (!items.length) {
    el.innerHTML = "<p class='muted'>None yet</p>";
    return;
  }
  el.innerHTML = items
    .map(
      (i) =>
        `<article><strong>${escapeHtml(i.name)}</strong><div class="muted">${escapeHtml(
          i.device || ""
        )} ${escapeHtml(i.controlId || "")}</div><pre>${escapeHtml(i.preview || "")}</pre></article>`
    )
    .join("");
}

async function refresh() {
  const data = await getJson("/api/status");
  renderList(document.getElementById("list-inbound"), data.inbound || []);
  renderList(document.getElementById("list-outbound"), data.outbound || []);
  renderList(document.getElementById("list-received"), data.ehrReceived || []);
}

document.getElementById("btn-refresh").addEventListener("click", () => {
  refresh().catch((e) => {
    document.getElementById("send-status").textContent = e.message;
  });
});

document.querySelectorAll(".btn-sim").forEach((btn) => {
  btn.addEventListener("click", async () => {
    const status = document.getElementById("send-status");
    const ackOut = document.getElementById("ack-out");
    status.textContent = "Sending device ORU…";
    try {
      const data = await getJson("/api/simulate-device", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ device: btn.dataset.device }),
      });
      ackOut.textContent = data.ack || "(empty ACK)";
      status.textContent = `Simulated ${data.device?.name || btn.dataset.device}`;
      setTimeout(() => refresh().catch(() => {}), 800);
    } catch (e) {
      status.textContent = e.message;
    }
  });
});

let routesLoaded = false;
let activeRouteId = "";

function showTab(tab) {
  document.querySelectorAll(".tab").forEach((b) => {
    const on = b.dataset.tab === tab;
    b.classList.toggle("active", on);
    b.setAttribute("aria-selected", on ? "true" : "false");
  });
  const demo = document.getElementById("tab-demo");
  const routes = document.getElementById("tab-routes");
  const xslt = document.getElementById("tab-xslt");
  const info = document.getElementById("tab-info");
  demo.hidden = tab !== "demo";
  routes.hidden = tab !== "routes";
  if (xslt) xslt.hidden = tab !== "xslt";
  if (info) info.hidden = tab !== "info";
  document.body.classList.toggle("routes-mode", tab === "routes" || tab === "xslt");
  if (tab === "routes") {
    loadRoutesTab().catch((e) => {
      document.getElementById("routes-status").textContent = e.message;
    });
  }
  if (tab === "xslt") {
    loadXsltTab().catch((e) => {
      const s = document.getElementById("xslt-status");
      if (s) s.textContent = e.message;
    });
  }
}

document.querySelectorAll(".tab").forEach((b) => {
  b.addEventListener("click", () => showTab(b.dataset.tab));
});

function loadRouteFrame(routeId) {
  bindRouteViewerResize();
  activeRouteId = routeId || "";
  const frame = document.getElementById("route-viewer-frame");
  if (!routeId) {
    frame.src = "about:blank";
    return;
  }
  const layout = "pipeline";
  frame.style.height = "";
  frame.style.minHeight = "";
  frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(routeId)}&mode=docs&layout=${encodeURIComponent(layout)}&cols=4&config=changed`;
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
    const h = Math.max(Math.ceil(data.height), minH);
    frame.style.height = `${h}px`;
    frame.style.minHeight = `${h}px`;
  });
}

async function loadRoutesTab() {
  bindRouteViewerResize();
  const status = document.getElementById("routes-status");
  const select = document.getElementById("route-select");
  if (!routesLoaded) {
    status.textContent = "Loading routes…";
    const data = await getJson("/api/v2/routes");
    const list = data.routes || [];
    select.innerHTML = "";
    if (!list.length) {
      status.textContent = "No route.v2.xml found.";
      loadRouteFrame("");
      return;
    }
    list.forEach((r) => {
      const opt = document.createElement("option");
      opt.value = r.id;
      opt.textContent = r.name || r.dir;
      select.appendChild(opt);
    });
    select.addEventListener("change", () => {
      loadRouteFrame(select.value);
      status.textContent = "";
    });
    routesLoaded = true;
  }
  if (select.value) loadRouteFrame(select.value);
  else if (select.options.length) {
    select.selectedIndex = 0;
    loadRouteFrame(select.value);
  }
  status.textContent = "";
}

refresh().catch(() => {});


/* XSLT viewer */
let xsltLoaded = false;
let activeXsltPath = "";

function formatBytes(n) {
  const x = Number(n) || 0;
  if (x < 1024) return `${x} B`;
  if (x < 1024 * 1024) return `${(x / 1024).toFixed(1)} KB`;
  return `${(x / (1024 * 1024)).toFixed(1)} MB`;
}

async function selectXsltFile(rel, meta) {
  const pathEl = document.getElementById("xslt-path");
  const metaEl = document.getElementById("xslt-meta");
  const codeEl = document.getElementById("xslt-code");
  const status = document.getElementById("xslt-status");
  if (!pathEl || !codeEl) return;
  activeXsltPath = rel || "";
  document.querySelectorAll(".xslt-file-list button").forEach((b) => {
    b.classList.toggle("active", b.dataset.path === rel);
  });
  pathEl.textContent = rel || "Select an XSLT file";
  metaEl.textContent = meta ? `${meta.route ? meta.route + " · " : ""}${formatBytes(meta.bytes)}` : "";
  if (!rel) {
    codeEl.textContent = "";
    return;
  }
  status.textContent = "Loading…";
  const res = await fetch(`/api/v2/xslt/content?path=${encodeURIComponent(rel)}`);
  const text = await res.text();
  if (!res.ok) throw new Error(text || res.statusText);
  codeEl.textContent = text;
  status.textContent = "";
}

async function loadXsltTab() {
  const listEl = document.getElementById("xslt-file-list");
  const status = document.getElementById("xslt-status");
  if (!listEl) return;
  if (!xsltLoaded) {
    status.textContent = "Loading…";
    const data = await getJson("/api/v2/xslt");
    const files = data.files || [];
    listEl.innerHTML = "";
    if (!files.length) {
      status.textContent = "No .xsl / .xslt files under routes.";
      return;
    }
    files.forEach((f) => {
      const li = document.createElement("li");
      const btn = document.createElement("button");
      btn.type = "button";
      btn.dataset.path = f.path;
      btn.innerHTML = `<strong>${f.name}</strong><span>${f.route || "routes"}</span>`;
      btn.addEventListener("click", () => {
        selectXsltFile(f.path, f).catch((e) => {
          status.textContent = e.message;
        });
      });
      li.appendChild(btn);
      listEl.appendChild(li);
    });
    xsltLoaded = true;
    status.textContent = `${files.length} file${files.length === 1 ? "" : "s"}`;
    await selectXsltFile(files[0].path, files[0]);
    return;
  }
  if (activeXsltPath) {
    const btn = listEl.querySelector(`button[data-path="${CSS.escape(activeXsltPath)}"]`);
    if (btn) btn.classList.add("active");
  }
}

if (location.hash === "#xslt") showTab("xslt");
