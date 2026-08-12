async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const err = new Error(data.error || res.statusText || "Request failed");
    err.status = res.status;
    err.data = data;
    throw err;
  }
  return data;
}

function renderFiles(listId, viewId, files) {
  const list = document.getElementById(listId);
  const view = document.getElementById(viewId);
  if (!list || !view) return;
  list.innerHTML = "";
  if (!files.length) {
    list.innerHTML = '<p class="muted">No files yet.</p>';
    view.textContent = "";
    return;
  }
  files.forEach((f, idx) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "file-btn";
    btn.textContent = `${f.name} (${f.size || 0}b)`;
    btn.addEventListener("click", () => {
      view.textContent = f.content || "";
      if (window.hljs && viewId.includes("debug")) {
        view.className = "viewer language-xml";
        window.hljs.highlightElement(view);
      }
    });
    list.appendChild(btn);
    if (idx === 0) {
      view.textContent = f.content || "";
    }
  });
}

async function refreshResults() {
  const [qcare, archive, debug] = await Promise.all([
    getJson("/api/qcare"),
    getJson("/api/archive"),
    getJson("/api/debug"),
  ]);
  renderFiles("qcare-list", "qcare-view", qcare.files || []);
  renderFiles("archive-list", "archive-view", archive.files || []);
  renderFiles("debug-list", "debug-view", debug.files || []);
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const sel = document.getElementById("sample");
  (data.files || []).forEach((f) => {
    const opt = document.createElement("option");
    opt.value = f.name;
    opt.textContent = f.name;
    sel.appendChild(opt);
  });
  sel.addEventListener("change", () => {
    const match = (data.files || []).find((f) => f.name === sel.value);
    document.getElementById("edi").value = match ? match.content : "";
  });
  if (sel.options.length > 1) {
    sel.selectedIndex = 1;
    sel.dispatchEvent(new Event("change"));
  }
}

document.getElementById("inject-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const status = document.getElementById("status");
  const sample = document.getElementById("sample").value;
  const edi = document.getElementById("edi").value;
  status.textContent = "Submitting…";
  try {
    const result = await getJson("/api/inject", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sample, edi }),
    });
    status.textContent = `Dropped ${result.file}; waiting for QCare…`;
    await getJson(
      `/api/wait-qcare?file=${encodeURIComponent(result.file)}&timeout=90`
    );
    status.textContent = "QCare file ready.";
    await refreshResults();
  } catch (err) {
    status.textContent = err.message || String(err);
  }
});

document.getElementById("refresh-btn").addEventListener("click", () => {
  refreshResults().catch(console.error);
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
    const tab = btn.getAttribute("data-main-tab");
    document.querySelectorAll(".main-tab").forEach((b) => {
      b.classList.toggle("active", b === btn);
      b.setAttribute("aria-selected", b === btn ? "true" : "false");
    });
    ["demo", "routes", "xslt", "timing", "info"].forEach((id) => {
      const el = document.getElementById(id === "demo" ? "tab-demo" : `tab-${id}`);
      if (el) el.hidden = id !== tab;
    });
    const nav = document.getElementById("demo-nav");
    if (nav) nav.style.display = tab === "demo" ? "" : "none";
    document.body.classList.toggle("routes-mode", tab === "routes" || tab === "xslt");
    if (tab === "routes") {
      loadRoutesTab().catch((err) => {
        const status = document.getElementById("routes-status");
        if (status) status.textContent = err.message || String(err);
      });
    }
  });
});

async function loadXslt() {
  const list = document.getElementById("xslt-list");
  const view = document.getElementById("xslt-view");
  if (!list || !view) return;
  try {
    const data = await getJson("/api/v2/xslt");
    list.innerHTML = "";
    (data.files || []).forEach((f, idx) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "file-btn";
      btn.textContent = f.path;
      btn.addEventListener("click", async () => {
        const res = await fetch(`/api/v2/xslt/content?path=${encodeURIComponent(f.path)}`);
        view.textContent = await res.text();
      });
      list.appendChild(btn);
      if (idx === 0) btn.click();
    });
  } catch (e) {
    list.innerHTML = `<p class="muted">${e.message}</p>`;
  }
}

loadSamples().catch(console.error);
refreshResults().catch(console.error);
loadXslt().catch(console.error);
