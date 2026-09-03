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
  el.style.color = isError ? "#fca5a5" : "";
}

function renderFiles(containerId, viewId, files) {
  const list = document.getElementById(containerId);
  const view = document.getElementById(viewId);
  if (!list || !view) return;
  list.innerHTML = "";
  if (!files.length) {
    view.textContent = "(none yet)";
    return;
  }
  files.slice(0, 12).forEach((f, i) => {
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

async function refresh() {
  const data = await getJson("/api/results");
  renderFiles("edi-list", "edi-view", data.edi || []);
  const extra = [...(data.csv || []), ...(data.kickout || [])];
  renderFiles("csv-list", "csv-view", extra);
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const select = document.getElementById("sample");
  const box = document.getElementById("file-text");
  const direction = document.getElementById("direction");
  (data.files || []).forEach((f) => {
    const opt = document.createElement("option");
    opt.value = f.name;
    opt.textContent = f.name;
    select.appendChild(opt);
  });
  select.addEventListener("change", () => {
    const match = (data.files || []).find((f) => f.name === select.value);
    box.value = match && match.content ? match.content : "";
    if (match && (match.kind === "edi" || match.kind === "834")) {
      direction.value = "reverse";
    }
  });
}

document.getElementById("inject-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const sample = document.getElementById("sample").value;
  const text = document.getElementById("file-text").value;
  const direction = document.getElementById("direction").value;
  setStatus("Submitting…");
  try {
    const result = await getJson("/api/inject", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sample, text, direction, fileName: sample }),
    });
    const kind = direction === "reverse" ? "csv" : "edi";
    setStatus(`Dropped ${result.file}. Waiting for ${kind}…`);
    const waited = await getJson(
      `/api/wait-out?kind=${encodeURIComponent(kind)}&file=${encodeURIComponent(result.file)}&timeout=75`
    );
    setStatus(`Wrote ${waited.file?.name || kind}`);
    await refresh();
  } catch (err) {
    setStatus(err.message || String(err), true);
  }
});

document.getElementById("refresh-btn").addEventListener("click", () => {
  refresh().catch((err) => setStatus(err.message, true));
});

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
      frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=pipeline&config=compact`;
    });
  }
  if (select.options.length) {
    frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=pipeline&config=compact`;
    if (status) status.textContent = `${select.options.length} route(s)`;
  } else if (status) {
    status.textContent = "No route.v2.xml yet";
  }
}

async function loadXsltTab() {
  const data = await getJson("/api/v2/xslt");
  const list = document.getElementById("xslt-list");
  const view = document.getElementById("xslt-view");
  if (!list) return;
  list.innerHTML = "";
  for (const f of data.files || []) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.textContent = f.name;
    btn.addEventListener("click", async () => {
      const res = await fetch(`/api/v2/xslt/content?path=${encodeURIComponent(f.path)}`);
      view.textContent = await res.text();
    });
    list.appendChild(btn);
  }
  if ((data.files || []).length) list.querySelector("button")?.click();
}

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => {
    const tab = btn.dataset.mainTab;
    document.querySelectorAll(".main-tab").forEach((b) => {
      b.classList.toggle("active", b === btn);
      b.setAttribute("aria-selected", b === btn ? "true" : "false");
    });
    ["demo", "routes", "xslt", "timing", "info"].forEach((id) => {
      const el = document.getElementById(`tab-${id}`);
      if (el) el.hidden = tab !== id;
    });
    const nav = document.getElementById("demo-nav");
    if (nav) nav.hidden = tab !== "demo";
    document.body.classList.toggle("routes-mode", tab === "routes");
    if (tab === "routes") loadRoutesTab().catch(console.error);
    if (tab === "xslt") loadXsltTab().catch(console.error);
  });
});

bindRouteViewerResize();
loadSamples().catch(console.error);
refresh().catch(console.error);
