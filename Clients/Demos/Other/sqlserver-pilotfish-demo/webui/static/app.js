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
  el.style.color = isError ? "var(--err, #b42318)" : "";
}

function renderCaptures(rows) {
  const tbody = document.querySelector("#captures-table tbody");
  if (!tbody) return;
  tbody.innerHTML = "";
  (rows || []).forEach((row) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `<td>${row.CaptureId}</td><td>${row.ClientName || ""}</td><td>${row.DocumentType || ""}</td><td>${row.Status || ""}</td><td>${row.CapturePayload || ""}</td>`;
    tbody.appendChild(tr);
  });
}

async function refreshCaptures() {
  const data = await getJson("/api/captures");
  const meta = document.getElementById("captures-meta");
  if (!data.ok) {
    if (meta) meta.textContent = data.error || "SQL not ready";
    renderCaptures([]);
    return data;
  }
  if (meta) meta.textContent = `${data.count} row(s) in dbo.Captures`;
  renderCaptures(data.rows);
  return data;
}

async function refreshXml() {
  const data = await getJson("/api/xml");
  const meta = document.getElementById("xml-meta");
  const view = document.getElementById("xml-view");
  if (!data.content) {
    if (meta) meta.textContent = "Waiting for the first poll…";
    if (view) view.textContent = "";
    return data;
  }
  if (meta) meta.textContent = `captures_export.xml · ${data.bytes} bytes · ${data.mtime || ""}`;
  if (view) view.textContent = data.content;
  return data;
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
      frame.style.height = "";
      frame.style.minHeight = "";
      frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=pipeline&config=changed`;
    });
  }
  if (select.options.length) {
    frame.style.height = "";
    frame.style.minHeight = "";
    frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=pipeline&config=changed`;
    if (status) status.textContent = `${select.options.length} route(s)`;
  } else if (status) {
    status.textContent = "No route.v2.xml yet";
  }
}

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => {
    const tab = btn.dataset.mainTab;
    document.querySelectorAll(".main-tab").forEach((b) => {
      b.classList.toggle("active", b === btn);
      b.setAttribute("aria-selected", b === btn ? "true" : "false");
    });
    const demo = document.getElementById("tab-demo");
    const routes = document.getElementById("tab-routes");
    const timing = document.getElementById("tab-timing");
    const info = document.getElementById("tab-info");
    if (demo) demo.hidden = tab !== "demo";
    if (routes) routes.hidden = tab !== "routes";
    if (timing) timing.hidden = tab !== "timing";
    if (info) info.hidden = tab !== "info";
    document.body.classList.toggle("routes-mode", tab === "routes");
    const nav = document.getElementById("demo-nav");
    if (nav) nav.hidden = tab !== "demo";
    if (tab === "routes") {
      const frame = document.getElementById("route-viewer-frame");
      if (window.__pfTheaterRecording || (frame && /[?&]replayStep=/.test(frame.src || ""))) {
        return;
      }
      loadRoutesTab().catch((err) => {
        const status = document.getElementById("routes-status");
        if (status) status.textContent = err.message || String(err);
      });
    }
  });
});

const form = document.getElementById("insert-form");
if (form) {
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const fd = new FormData(form);
    setStatus("Inserting…");
    try {
      const result = await getJson("/api/insert", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          clientName: fd.get("clientName"),
          documentType: fd.get("documentType"),
          status: fd.get("status"),
          payload: fd.get("payload"),
        }),
      });
      setStatus(`Inserted CaptureId ${result.captureId}. Next poll will rewrite the XML.`);
      await refreshCaptures();
    } catch (err) {
      setStatus(err.message || String(err), true);
    }
  });
}

document.getElementById("refresh-btn")?.addEventListener("click", () => {
  refreshCaptures().catch((err) => setStatus(err.message, true));
});
document.getElementById("xml-refresh-btn")?.addEventListener("click", () => {
  refreshXml().catch((err) => setStatus(err.message, true));
});

bindRouteViewerResize();
refreshCaptures().catch(() => {});
refreshXml().catch(() => {});
setInterval(() => {
  refreshCaptures().catch(() => {});
  refreshXml().catch(() => {});
}, 4000);
