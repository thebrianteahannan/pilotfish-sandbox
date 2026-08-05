async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
}

function setStatus(msg, isError) {
  const el = document.getElementById("status");
  el.textContent = msg || "";
  el.style.color = isError ? "#a33" : "";
}

let snipTab = "html";
let activeSnip = null;

function showSnipTab(tab) {
  snipTab = tab;
  document.querySelectorAll(".snip-tab").forEach((b) => {
    b.classList.toggle("active", b.dataset.tab === tab);
  });
  const frame = document.getElementById("snip-html");
  const raw = document.getElementById("snip-view");
  if (tab === "html") {
    frame.hidden = false;
    raw.hidden = true;
  } else {
    frame.hidden = true;
    raw.hidden = false;
  }
}

function selectSnip(file) {
  activeSnip = file;
  const raw = document.getElementById("snip-view");
  const frame = document.getElementById("snip-html");
  raw.textContent = file.content || "(empty)";
  frame.src = `/api/snip-report?name=${encodeURIComponent(file.name)}`;
  showSnipTab(snipTab);
}

function renderFiles(containerId, viewId, files, onSelect) {
  const list = document.getElementById(containerId);
  const view = document.getElementById(viewId);
  list.innerHTML = "";
  if (!files.length) {
    if (view) view.textContent = "(none yet)";
    if (onSelect) {
      document.getElementById("snip-html").removeAttribute("src");
      document.getElementById("snip-html").srcdoc = "<p style='font-family:sans-serif;padding:1rem;color:#666'>(none yet)</p>";
    }
    return;
  }
  files.forEach((f, i) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.textContent = f.name;
    btn.addEventListener("click", () => {
      [...list.querySelectorAll("button")].forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      if (onSelect) onSelect(f);
      else view.textContent = f.content;
    });
    list.appendChild(btn);
    if (i === 0) {
      btn.classList.add("active");
      if (onSelect) onSelect(f);
      else view.textContent = f.content;
    }
  });
}

function renderClaims(claims) {
  const wrap = document.getElementById("claims-table");
  if (!claims.length) {
    wrap.innerHTML = "<p>No claims yet.</p>";
    return;
  }
  const rows = claims
    .map(
      (c) => `<tr>
      <td>${c.ClaimId}</td>
      <td>${c.ClaimNumber}</td>
      <td>${c.LastName}, ${c.FirstName}</td>
      <td>${c.ClaimAmount}</td>
      <td>${c.DiagnosisCode}</td>
      <td><strong>${c.Status}</strong></td>
    </tr>`
    )
    .join("");
  wrap.innerHTML = `<table>
    <thead><tr><th>Id</th><th>Number</th><th>Patient</th><th>Amount</th><th>Dx</th><th>Status</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>`;
}

async function refresh() {
  const [edi, snip, claims] = await Promise.all([
    getJson("/api/edi"),
    getJson("/api/snip"),
    getJson("/api/claims"),
  ]);
  renderFiles("edi-list", "edi-view", edi.files || []);
  renderFiles("snip-list", "snip-view", snip.files || [], selectSnip);
  renderClaims(claims.claims || []);
}

document.querySelectorAll(".snip-tab").forEach((btn) => {
  btn.addEventListener("click", () => showSnipTab(btn.dataset.tab));
});

document.getElementById("refresh-btn").addEventListener("click", () => {
  refresh().catch((e) => setStatus(e.message, true));
});

document.getElementById("claim-form").addEventListener("submit", async (ev) => {
  ev.preventDefault();
  const btn = document.getElementById("submit-btn");
  btn.disabled = true;
  setStatus("Submitting…");
  try {
    const fd = new FormData(ev.target);
    const payload = Object.fromEntries(fd.entries());
    payload.claimAmount = Number(payload.claimAmount);
    const created = await getJson("/api/claims", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    setStatus(`Claim ${created.claimId} PENDING — waiting for EDI…`);
    const waited = await getJson(`/api/wait-edi/${created.claimId}?timeout=120`);
    setStatus(`Ready: ${waited.edi.name}`);
    await refresh();
  } catch (e) {
    setStatus(e.message, true);
  } finally {
    btn.disabled = false;
  }
});

refresh().catch((e) => setStatus(e.message, true));
setInterval(() => refresh().catch(() => {}), 20000);

let routesLoaded = false;
let activeRouteId = "";

function setMainTab(tab) {
  document.querySelectorAll(".main-tab").forEach((b) => {
    const on = b.dataset.mainTab === tab;
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
  activeRouteId = routeId || "";
  const frame = document.getElementById("route-viewer-frame");
  if (!routeId) {
    frame.src = "about:blank";
    return;
  }
  const layout = "pipeline";
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
      status.textContent = "No route.v2.xml found under ROUTES_DIR.";
      loadRouteFrame("");
      return;
    }
    list.forEach((r) => {
      const opt = document.createElement("option");
      opt.value = r.id;
      opt.textContent = r.name || r.dir;
      select.appendChild(opt);
    });
    select.addEventListener("change", () => {
      loadRouteFrame(select.value);
      status.textContent = "";
    });
    routesLoaded = true;
    status.textContent = `${list.length} route${list.length === 1 ? "" : "s"}`;
  }
  if (select.value) loadRouteFrame(select.value);
}

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => setMainTab(btn.dataset.mainTab));
});

if (location.hash === "#routes") setMainTab("routes");
else if (location.hash === "#xslt") setMainTab("xslt");



/* XSLT viewer */
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
    return;
  }
  if (activeXsltPath) {
    const btn = listEl.querySelector(`button[data-path="${CSS.escape(activeXsltPath)}"]`);
    if (btn) btn.classList.add("active");
  }
}
