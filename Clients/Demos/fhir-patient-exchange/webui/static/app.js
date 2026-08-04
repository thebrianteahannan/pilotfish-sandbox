async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok && data.error) throw new Error(data.error);
  return data;
}

function setStatus(id, msg, isError) {
  const el = document.getElementById(id);
  if (!el) return;
  el.textContent = msg || "";
  el.style.color = isError ? "#fca5a5" : "";
}

function showHttp(result) {
  const view = document.getElementById("http-view");
  const body = result.body || "";
  let pretty = body;
  try {
    pretty = JSON.stringify(JSON.parse(body), null, 2);
  } catch (_) {
    /* keep raw */
  }
  view.textContent = [
    `${result.status || "?"} ${result.url || ""}`,
    result.error ? `error: ${result.error}` : "",
    "",
    pretty || "(empty body)",
  ]
    .filter((line, i, arr) => !(line === "" && arr[i - 1] === ""))
    .join("\n");
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

function renderMessages(messages) {
  const wrap = document.getElementById("messages-table");
  if (!messages.length) {
    wrap.innerHTML = "<p>No rows yet.</p>";
    return;
  }
  const rows = messages
    .map(
      (m) => `<tr>
      <td>${m.ResourceRowId}</td>
      <td>${m.ResourceType || ""}</td>
      <td>${m.ResourceId || ""}</td>
      <td>${m.PatientId || ""}</td>
      <td><strong>${m.ValidationStatus || ""}</strong></td>
    </tr>`
    )
    .join("");
  wrap.innerHTML = `<table>
    <thead><tr><th>Id</th><th>Type</th><th>Resource</th><th>MRN</th><th>Status</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>`;
}

async function refresh() {
  const [messages, store] = await Promise.all([getJson("/api/resources"), getJson("/api/fhir-store")]);
  renderMessages(messages.messages || []);
  renderFiles("store-list", "store-view", store.files || []);
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
    const hit = (data.files || []).find((f) => f.name === select.value);
    document.getElementById("fhir").value = hit ? hit.content : "";
    try {
      const id = hit ? JSON.parse(hit.content).id : "";
      if (id) document.getElementById("resourceId").value = id;
    } catch (_) {
      /* ignore */
    }
  });
}

document.getElementById("refresh-btn").addEventListener("click", () => {
  refresh().catch((e) => setStatus("create-status", e.message, true));
});

document.getElementById("create-form").addEventListener("submit", async (ev) => {
  ev.preventDefault();
  const btn = document.getElementById("create-btn");
  btn.disabled = true;
  setStatus("create-status", "POST /Patient …");
  try {
    const fd = new FormData(ev.target);
    const payload = Object.fromEntries(fd.entries());
    const result = await getJson("/api/fhir/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    showHttp(result);
    setStatus(
      "create-status",
      result.status ? `HTTP ${result.status}` : result.error || "No response",
      !result.ok
    );
    try {
      const id = JSON.parse(result.body || "{}").id;
      if (id) document.getElementById("resourceId").value = id;
    } catch (_) {
      /* ignore */
    }
    await refresh();
  } catch (e) {
    setStatus("create-status", e.message, true);
  } finally {
    btn.disabled = false;
  }
});

document.getElementById("read-form").addEventListener("submit", async (ev) => {
  ev.preventDefault();
  const btn = document.getElementById("read-btn");
  btn.disabled = true;
  const id = document.getElementById("resourceId").value.trim();
  setStatus("read-status", `GET /Patient/${id} …`);
  try {
    const result = await getJson(`/api/fhir/read/${encodeURIComponent(id)}`);
    showHttp(result);
    setStatus("read-status", result.status ? `HTTP ${result.status}` : result.error || "No response", !result.ok);
    await refresh();
  } catch (e) {
    setStatus("read-status", e.message, true);
  } finally {
    btn.disabled = false;
  }
});

let routesLoaded = false;

function setMainTab(tab) {
  document.querySelectorAll(".main-tab").forEach((b) => {
    const on = b.dataset.mainTab === tab;
    b.classList.toggle("active", on);
    b.setAttribute("aria-selected", on ? "true" : "false");
  });
  document.getElementById("tab-demo").hidden = tab !== "demo";
  document.getElementById("tab-routes").hidden = tab !== "routes";
  const xslt = document.getElementById("tab-xslt");
  if (xslt) xslt.hidden = tab !== "xslt";
  document.body.classList.toggle("routes-mode", tab === "routes" || tab === "xslt");
  const nav = document.getElementById("demo-nav");
  if (nav) nav.hidden = tab !== "demo";
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

function loadRouteFrame(routeId) {
  const frame = document.getElementById("route-viewer-frame");
  if (!routeId) {
    frame.src = "about:blank";
    return;
  }
  const layout = document.getElementById("route-layout")?.value || "pipeline";
  frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(routeId)}&layout=${encodeURIComponent(layout)}&cols=4`;
}

async function loadRoutesTab() {
  const status = document.getElementById("routes-status");
  const select = document.getElementById("route-select");
  if (!routesLoaded) {
    status.textContent = "Loading routes…";
    const data = await getJson("/api/v2/routes");
    const list = data.routes || [];
    select.innerHTML = "";
    if (!list.length) {
      status.textContent = "No route.v2.xml found.";
      return;
    }
    list.forEach((r) => {
      const opt = document.createElement("option");
      opt.value = r.id;
      opt.textContent = r.name || r.dir;
      select.appendChild(opt);
    });
    select.addEventListener("change", () => loadRouteFrame(select.value));
    document.getElementById("route-layout").addEventListener("change", () => {
      if (select.value) loadRouteFrame(select.value);
    });
    routesLoaded = true;
    status.textContent = `${list.length} route${list.length === 1 ? "" : "s"}`;
  }
  if (select.value) loadRouteFrame(select.value);
}

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => setMainTab(btn.dataset.mainTab));
});

loadSamples().catch(() => {});
refresh().catch((e) => setStatus("create-status", e.message, true));
setInterval(() => refresh().catch(() => {}), 20000);
if (location.hash === "#routes") setMainTab("routes");
else if (location.hash === "#xslt") setMainTab("xslt");

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
  }
}
