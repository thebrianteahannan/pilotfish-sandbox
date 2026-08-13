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

function msgIndex(name) {
  const m = String(name || "").match(/^msg-(\d+)$/i);
  return m ? Number(m[1]) : null;
}

function renderMessages(files) {
  const list = document.getElementById("queue-list");
  const view = document.getElementById("queue-view");
  if (!list || !view) return;
  list.innerHTML = "";
  if (!files.length) {
    view.textContent = "(none yet)";
    return;
  }
  const ordered = [...files].sort((a, b) => {
    const na = msgIndex(a.name);
    const nb = msgIndex(b.name);
    if (na != null && nb != null) return na - nb;
    return 0;
  });
  ordered.slice(0, 12).forEach((f, i) => {
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
  const data = await getJson("/api/queue");
  const meta = document.getElementById("queue-meta");
  if (!data.ready) {
    if (meta) meta.textContent = "Queue not declared yet — send a POST first.";
    renderMessages([]);
    return data;
  }
  if (meta) meta.textContent = `${data.queue} · ${data.messageCount} message(s)`;
  renderMessages(data.messages || []);
  return data;
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const select = document.getElementById("sample");
  const body = document.getElementById("body");
  if (!select || !body) return;
  (data.files || []).forEach((f) => {
    const opt = document.createElement("option");
    opt.value = f.name;
    opt.textContent = f.name;
    select.appendChild(opt);
  });
  select.addEventListener("change", () => {
    const name = select.value;
    const match = (data.files || []).find((f) => f.name === name);
    body.value = match ? match.content : body.value;
  });
  if (data.files && data.files[0]) {
    select.value = data.files[0].name;
    body.value = data.files[0].content;
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

const form = document.getElementById("inject-form");
if (form) {
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const sample = document.getElementById("sample").value;
    const body = document.getElementById("body").value;
    setStatus("Posting…");
    try {
      const before = await refresh();
      const prevCount = Number((before && before.messageCount) || 0);
      const result = await getJson("/api/inject", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sample, body }),
      });
      setStatus(`EIP ${result.status}. ${result.bytes} bytes published.`);
      for (let i = 0; i < 10; i++) {
        const queued = await refresh();
        if (queued && Number(queued.messageCount || 0) > prevCount) break;
        await new Promise((r) => setTimeout(r, 400));
      }
    } catch (err) {
      setStatus(err.message || String(err), true);
    }
  });
}

const refreshBtn = document.getElementById("refresh-btn");
if (refreshBtn) {
  refreshBtn.addEventListener("click", () => {
    refresh().catch((err) => setStatus(err.message, true));
  });
}

bindRouteViewerResize();
loadSamples().catch(console.error);
refresh().catch(() => {});
