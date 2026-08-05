async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok && data.error) throw new Error(data.error);
  return data;
}

function escapeHtml(s) {
  return String(s).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const sel = document.getElementById("sample");
  (data.files || []).forEach((f) => {
    const o = document.createElement("option");
    o.value = f.name;
    o.textContent = f.name;
    sel.appendChild(o);
  });
  sel.addEventListener("change", () => {
    const f = (data.files || []).find((x) => x.name === sel.value);
    if (f) document.getElementById("body").value = f.content || "";
  });
}

async function refreshSql() {
  const data = await getJson("/api/resources");
  document.getElementById("sql-rows").textContent = JSON.stringify(data.messages || data, null, 2);
}

document.getElementById("btn-refresh").addEventListener("click", () => refreshSql().catch((e) => (document.getElementById("status").textContent = e.message)));

document.getElementById("btn-meta").addEventListener("click", () => {
  document.getElementById("method").value = "GET";
  document.getElementById("resourceType").value = "metadata";
  document.getElementById("id").value = "";
  document.getElementById("btn-invoke").click();
});

document.getElementById("btn-invoke").addEventListener("click", async () => {
  const status = document.getElementById("status");
  status.textContent = "Calling…";
  try {
    const payload = {
      method: document.getElementById("method").value,
      resourceType: document.getElementById("resourceType").value,
      id: document.getElementById("id").value,
      query: document.getElementById("query").value,
      sample: document.getElementById("sample").value,
      body: document.getElementById("body").value,
      proxy: document.getElementById("proxy").checked,
    };
    const data = await getJson("/api/fhir/invoke", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    status.textContent = `HTTP ${data.status || 0} ${data.ok ? "OK" : "ERR"} · ${data.url || ""}`;
    let pretty = data.body || data.error || "";
    try {
      pretty = JSON.stringify(JSON.parse(pretty), null, 2);
    } catch (_) {}
    document.getElementById("result").textContent = pretty;
    refreshSql().catch(() => {});
  } catch (e) {
    status.textContent = e.message;
  }
});

document.getElementById("btn-outbound").addEventListener("click", async () => {
  const status = document.getElementById("status");
  try {
    const data = await getJson("/api/outbound/enqueue", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });
    status.textContent = `Enqueued ${data.file} → Route 2 polls input/outbound (GET ${data.url})`;
  } catch (e) {
    status.textContent = e.message;
  }
});

function showTab(tab) {
  document.querySelectorAll(".tab").forEach((b) => b.classList.toggle("active", b.dataset.tab === tab));
  document.getElementById("tab-demo").hidden = tab !== "demo";
  document.getElementById("tab-routes").hidden = tab !== "routes";
  const xslt = document.getElementById("tab-xslt");
  if (xslt) xslt.hidden = tab !== "xslt";
  document.body.classList.toggle("routes-mode", tab === "routes" || tab === "xslt");
  if (tab === "routes") loadRoutesTab().catch((e) => (document.getElementById("routes-status").textContent = e.message));
  if (tab === "xslt") loadXsltTab().catch(() => {});
}
document.querySelectorAll(".tab").forEach((b) => b.addEventListener("click", () => showTab(b.dataset.tab)));

let routesLoaded = false;
async function loadRoutesTab() {
  const select = document.getElementById("route-select");
  const frame = document.getElementById("route-viewer-frame");
  const layout = document.getElementById("route-layout");
  const status = document.getElementById("routes-status");
  if (!routesLoaded) {
    const data = await getJson("/api/v2/routes");
    select.innerHTML = (data.routes || []).map((r) => `<option value="${r.id}">${escapeHtml(r.name)}</option>`).join("");
    routesLoaded = true;
    const reload = () => {
      if (!select.value) return;
      frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=${layout.value}&config=changed`;
    };
    select.addEventListener("change", reload);
    layout.addEventListener("change", reload);
  }
  if (select.options.length) {
    frame.src = `/static/route-viewer/index.html?route=${encodeURIComponent(select.value)}&mode=docs&layout=${layout.value}&config=changed`;
    status.textContent = `${select.options.length} route(s)`;
  } else status.textContent = "No route.v2.xml yet";
}

async function loadXsltTab() {
  const select = document.getElementById("xslt-select");
  if (!select || select.dataset.loaded === "1") return;
  const data = await getJson("/api/v2/xslt");
  select.innerHTML = (data.files || []).map((f) => `<option value="${escapeHtml(f.path)}">${escapeHtml(f.path)}</option>`).join("");
  select.dataset.loaded = "1";
  async function show() {
    const path = select.value;
    if (!path) return;
    const res = await fetch(`/api/v2/xslt/content?path=${encodeURIComponent(path)}`);
    document.getElementById("xslt-view").textContent = await res.text();
    document.getElementById("xslt-status").textContent = path;
    const el = document.getElementById("xslt-path");
    if (el) el.textContent = path;
  }
  select.addEventListener("change", () => show().catch(() => {}));
  await show();
}

loadSamples().catch(() => {});
refreshSql().catch(() => {});
