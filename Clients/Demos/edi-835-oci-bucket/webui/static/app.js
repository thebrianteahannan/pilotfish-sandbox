async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
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

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

let autoRefreshTimer = null;
let lastOciNames = "";

async function refresh() {
  const data = await getJson("/api/status");
  renderList(document.getElementById("list-archive"), data.archive || []);
  renderList(document.getElementById("list-staged"), data.staged || []);
  renderList(document.getElementById("list-json"), data.json || []);
  const ociFiles = data.ociFiles || [];
  renderList(document.getElementById("list-oci"), ociFiles);

  const api = data.ociApi || {};
  const meta = document.getElementById("oci-meta");
  const badge = document.getElementById("oci-live-badge");
  const refreshMeta = document.getElementById("refresh-meta");
  const stamp = new Date().toLocaleTimeString();
  if (refreshMeta) refreshMeta.textContent = `Updated ${stamp}`;

  if (meta) {
    if (api.ok === false) {
      meta.textContent = `OCI list failed: ${api.error || "unknown error"} (${api.endpoint || ""} / ${api.namespace || ""}/${api.bucket || ""})`;
    } else {
      meta.textContent = `${ociFiles.length} object(s) in ${api.namespace || "floci-local"}/${api.bucket || "edi-835-payments"} @ ${api.endpoint || "floci"} · ${stamp}`;
    }
  }

  const names = ociFiles.map((o) => o.name).join("|");
  if (badge) {
    if (names && names !== lastOciNames) {
      badge.classList.add("pulse");
      badge.textContent = "NEW";
      setTimeout(() => {
        badge.classList.remove("pulse");
        badge.textContent = "LIVE";
      }, 2500);
    } else {
      badge.textContent = "LIVE";
    }
  }
  lastOciNames = names;
  return data;
}

function setAutoRefresh(on) {
  if (autoRefreshTimer) {
    clearInterval(autoRefreshTimer);
    autoRefreshTimer = null;
  }
  if (on) {
    autoRefreshTimer = setInterval(() => {
      refresh().catch(() => {});
    }, 2000);
  }
}

document.getElementById("btn-refresh").addEventListener("click", () => {
  refresh().catch((e) => {
    document.getElementById("upload-status").textContent = e.message;
  });
});

const autoRefreshEl = document.getElementById("auto-refresh");
if (autoRefreshEl) {
  setAutoRefresh(autoRefreshEl.checked);
  autoRefreshEl.addEventListener("change", () => setAutoRefresh(autoRefreshEl.checked));
}

document.getElementById("btn-upload").addEventListener("click", async () => {
  const status = document.getElementById("upload-status");
  const out = document.getElementById("upload-out");
  status.textContent = "Uploading to SFTP…";
  try {
    const sample = document.getElementById("sample").value;
    const data = await getJson("/api/upload-sftp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sample }),
    });
    out.textContent = JSON.stringify(data, null, 2);
    status.textContent = "Uploaded — wait for SFTP poll (~10s) then refresh";
    setTimeout(() => refresh().catch(() => {}), 12000);
  } catch (e) {
    status.textContent = e.message;
  }
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
      const el = document.getElementById("xslt-status");
      if (el) el.textContent = e.message;
    });
  }
}

document.querySelectorAll(".tab").forEach((btn) => {
  btn.addEventListener("click", () => showTab(btn.dataset.tab));
});

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
      frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(
        activeRouteId
      )}&mode=docs&layout=${layout}&config=changed`;
    });
  }
  if (select.options.length) {
    activeRouteId = select.value;
    frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(
      activeRouteId
    )}&mode=docs&layout=${layout}&config=changed`;
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
  }
  select.addEventListener("change", () => show().catch((e) => (status.textContent = e.message)));
  await show();
}

refresh().catch(() => {});
