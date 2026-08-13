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
  try {
    const results = await getJson("/api/results");
    renderFiles("resp-list", "resp-view", results.responses || []);
    renderFiles("found-list", "found-view", results.found || []);
    renderFiles("nf-list", "nf-view", results.not_found || []);
  } catch (_) {
    /* optional until EIP writes */
  }
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const select = document.getElementById("sample");
  const content = document.getElementById("content");
  if (!select || !content) return;
  (data.files || []).forEach((f) => {
    const opt = document.createElement("option");
    opt.value = f.name;
    opt.textContent = f.name;
    select.appendChild(opt);
  });
  select.addEventListener("change", () => {
    const match = (data.files || []).find((f) => f.name === select.value);
    content.value = match ? match.content : "";
  });
  const preferred = (data.files || []).find((f) => f.name.includes("803")) || (data.files || [])[0];
  if (preferred) {
    select.value = preferred.name;
    content.value = preferred.content;
  }
}

async function loadHealth() {
  const note = document.getElementById("health-note");
  if (!note) return;
  try {
    const h = await getJson("/api/health");
    note.textContent = h.eip ? "EIP up" : "EIP starting";
  } catch (err) {
    note.textContent = err.message || String(err);
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
    if (status && !document.body.classList.contains("pf-live-construction")) {
      status.textContent = `${select.options.length} route(s)`;
    }
  } else if (status && !document.body.classList.contains("pf-live-construction")) {
    status.textContent = "No route.v2.xml yet";
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
  const nav = document.getElementById("demo-nav");
  if (nav) nav.hidden = tab !== "demo";
  document.body.classList.toggle("routes-mode", tab === "routes");
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
}

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => showTab(btn.dataset.mainTab));
});

const form = document.getElementById("inject-form");
if (form) {
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const sample = document.getElementById("sample").value;
    const content = document.getElementById("content").value;
    setStatus("Dropping 276…");
    try {
      const result = await getJson("/api/inject", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sample, content }),
      });
      setStatus(`Dropped ${result.file}. Waiting for 277…`);
      try {
        await getJson("/api/wait-results?contains=ABCXYZ1&timeout=90");
        setStatus("277 and found bucket landed.");
      } catch (err) {
        setStatus(err.message || "Timeout — check EIP logs", true);
      }
      await refresh();
    } catch (err) {
      setStatus(err.message || String(err), true);
    }
  });
}

document.getElementById("reset-btn")?.addEventListener("click", async () => {
  setStatus("Resetting…");
  try {
    await getJson("/api/reset", { method: "POST" });
    setStatus("Outputs cleared.");
    await refresh();
  } catch (err) {
    setStatus(err.message || String(err), true);
  }
});

document.getElementById("refresh-btn")?.addEventListener("click", () => {
  refresh().catch((err) => setStatus(err.message, true));
});

bindRouteViewerResize();
loadHealth();
loadSamples().then(refresh).catch((err) => setStatus(err.message, true));
setInterval(() => {
  loadHealth();
  refresh().catch(() => {});
}, 5000);
