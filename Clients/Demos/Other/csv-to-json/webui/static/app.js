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
  const [json, archive] = await Promise.all([
    getJson("/api/json"),
    getJson("/api/archive"),
  ]);
  renderFiles("json-list", "json-view", json.files || []);
  renderFiles("archive-list", "archive-view", archive.files || []);
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
    document.getElementById("csv").value = match ? match.content : "";
  });
}

document.getElementById("inject-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const sample = document.getElementById("sample").value;
  const csv = document.getElementById("csv").value;
  setStatus("Submitting…");
  try {
    const result = await getJson("/api/inject", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sample, csv }),
    });
    setStatus(`Dropped ${result.file}. Waiting for JSON…`);
    const waited = await getJson(
      `/api/wait-json?file=${encodeURIComponent(result.file)}&timeout=60`
    );
    setStatus(`Wrote ${waited.file?.name || "JSON"}`);
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
  const layout = "pipeline";
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
      frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=${layout}&config=changed`;
    });
  }
  if (select.options.length) {
    frame.style.height = "";
    frame.style.minHeight = "";
    frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=${layout}&config=changed`;
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
    document.getElementById("tab-demo").hidden = tab !== "demo";
    document.getElementById("tab-routes").hidden = tab !== "routes";
    const xslt = document.getElementById("tab-xslt");
    if (xslt) xslt.hidden = tab !== "xslt";
    const info = document.getElementById("tab-info");
    if (info) info.hidden = tab !== "info";
    document.body.classList.toggle("routes-mode", tab === "routes" || tab === "xslt");
    const nav = document.getElementById("demo-nav");
    if (nav) nav.hidden = tab !== "demo";
    if (tab === "routes") {
      loadRoutesTab().catch((err) => {
        const status = document.getElementById("routes-status");
        if (status) status.textContent = err.message || String(err);
      });
    }
  });
});

bindRouteViewerResize();
loadSamples().catch(console.error);
refresh().catch(console.error);
