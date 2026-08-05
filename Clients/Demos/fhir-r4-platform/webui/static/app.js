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

const CORE6 = new Set(["Patient", "Practitioner", "Organization", "Observation", "Encounter", "Condition"]);

function buildSearchQueryFromHelpers() {
  const parts = [];
  document.querySelectorAll("#search-helpers [data-sp]").forEach((el) => {
    const v = (el.value || "").trim();
    if (v) parts.push(`${encodeURIComponent(el.dataset.sp)}=${encodeURIComponent(v)}`);
  });
  return parts.join("&");
}

function syncSearchHelpersVisibility() {
  const rt = document.getElementById("resourceType").value;
  const box = document.getElementById("search-helpers");
  const hint = document.getElementById("search-hint");
  const show = CORE6.has(rt);
  if (box) box.style.display = show ? "grid" : "none";
  if (hint) hint.style.display = show ? "block" : "none";
}

document.getElementById("resourceType").addEventListener("change", syncSearchHelpersVisibility);
document.querySelectorAll("#search-helpers [data-sp]").forEach((el) => {
  el.addEventListener("change", () => {
    const built = buildSearchQueryFromHelpers();
    if (built) document.getElementById("query").value = built;
  });
  el.addEventListener("input", () => {
    const built = buildSearchQueryFromHelpers();
    document.getElementById("query").value = built;
  });
});
syncSearchHelpersVisibility();

document.getElementById("btn-token").addEventListener("click", async () => {
  const status = document.getElementById("status");
  status.textContent = "Fetching Keycloak token…";
  try {
    const data = await getJson("/api/oauth/token", { method: "POST" });
    if (!data.ok || !data.token) throw new Error(data.error || "No access_token");
    document.getElementById("bearer").value = data.token;
    status.textContent = "Token ready (client_credentials)";
  } catch (e) {
    status.textContent = e.message;
  }
});

document.getElementById("btn-invoke").addEventListener("click", async () => {
  const status = document.getElementById("status");
  status.textContent = "Calling…";
  try {
    let query = document.getElementById("query").value;
    const method = document.getElementById("method").value;
    if (method === "GET" && !document.getElementById("id").value) {
      const built = buildSearchQueryFromHelpers();
      if (built) query = built;
    }
    const payload = {
      method,
      resourceType: document.getElementById("resourceType").value,
      id: document.getElementById("id").value,
      query,
      sample: document.getElementById("sample").value,
      body: document.getElementById("body").value,
      proxy: document.getElementById("proxy").checked,
      bearer: document.getElementById("bearer").value,
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

document.getElementById("btn-txn").addEventListener("click", async () => {
  const status = document.getElementById("status");
  try {
    const data = await getJson("/api/samples");
    const f = (data.files || []).find((x) => x.name === "Bundle_transaction_patient_obs.json");
    if (!f) throw new Error("Bundle_transaction_patient_obs.json not found");
    document.getElementById("method").value = "POST";
    document.getElementById("resourceType").value = "Bundle";
    document.getElementById("id").value = "";
    document.getElementById("query").value = "";
    document.getElementById("body").value = f.content || "";
    document.getElementById("sample").value = f.name;
    status.textContent = "Loaded transaction Bundle sample — click Invoke";
  } catch (e) {
    status.textContent = e.message;
  }
});

function showTab(tab) {
  document.querySelectorAll(".tab").forEach((b) => b.classList.toggle("active", b.dataset.tab === tab));
  document.getElementById("tab-demo").hidden = tab !== "demo";
  document.getElementById("tab-routes").hidden = tab !== "routes";
  const info = document.getElementById("tab-info");
  if (info) info.hidden = tab !== "info";
  const tests = document.getElementById("tab-tests");
  if (tests) tests.hidden = tab !== "tests";
  const xslt = document.getElementById("tab-xslt");
  if (xslt) xslt.hidden = tab !== "xslt";
  document.body.classList.toggle("routes-mode", tab === "routes" || tab === "xslt");
  if (tab === "routes") loadRoutesTab().catch((e) => (document.getElementById("routes-status").textContent = e.message));
  if (tab === "xslt") loadXsltTab().catch(() => {});
  if (tab === "tests") loadTestsTab().catch((e) => {
    const s = document.getElementById("tests-summary");
    if (s) s.textContent = e.message;
  });
}
document.querySelectorAll(".tab").forEach((b) => b.addEventListener("click", () => showTab(b.dataset.tab)));

async function loadTestsTab() {
  const body = document.getElementById("tests-body");
  const summary = document.getElementById("tests-summary");
  if (!body) return;
  const data = await getJson("/api/v2/tests/results");
  if (!data.ok) {
    body.innerHTML = `<tr><td colspan="5" class="muted">${escapeHtml(data.message || "No results")}</td></tr>`;
    if (summary) summary.textContent = data.message || "No results yet";
    return;
  }
  const s = data.summary || {};
  if (summary) {
    summary.textContent = `pass ${s.pass || 0} · fail ${s.fail || 0} · error ${s.error || 0} · skip ${s.skip || 0} · ${data.finished_at || ""}`;
  }
  const rows = (data.results || []).map((r) => {
    const st = escapeHtml(r.status || "");
    return `<tr class="test-${st}">
      <td><strong>${st.toUpperCase()}</strong></td>
      <td>${escapeHtml(r.suite || "")}</td>
      <td>${escapeHtml(r.name || "")}</td>
      <td>${escapeHtml(r.message || "")}</td>
      <td>${escapeHtml(String(r.duration_ms ?? ""))}</td>
    </tr>`;
  });
  body.innerHTML = rows.join("") || `<tr><td colspan="5" class="muted">Empty result set</td></tr>`;
}

const btnTestsRefresh = document.getElementById("btn-tests-refresh");
if (btnTestsRefresh) {
  btnTestsRefresh.addEventListener("click", () => {
    loadTestsTab().catch((e) => {
      const s = document.getElementById("tests-summary");
      if (s) s.textContent = e.message;
    });
  });
}

let routesLoaded = false;

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
  const select = document.getElementById("route-select");
  const frame = document.getElementById("route-viewer-frame");
  const status = document.getElementById("routes-status");
  const layout = "pipeline";
  bindRouteViewerResize();
  if (!routesLoaded) {
    const data = await getJson("/api/v2/routes");
    select.innerHTML = (data.routes || []).map((r) => `<option value="${r.id}">${escapeHtml(r.name)}</option>`).join("");
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
