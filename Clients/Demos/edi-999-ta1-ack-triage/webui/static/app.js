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
  files.slice(0, 16).forEach((f, i) => {
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
  const [accepted, rejected, error, reports] = await Promise.all([
    getJson("/api/accepted"),
    getJson("/api/rejected"),
    getJson("/api/error"),
    getJson("/api/reports"),
  ]);
  renderFiles("accepted-list", "accepted-view", accepted.files || []);
  renderFiles("rejected-list", "rejected-view", rejected.files || []);
  renderFiles("error-list", "error-view", error.files || []);
  renderFiles("reports-list", "reports-view", reports.files || []);
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
    const name = select.value;
    const match = (data.files || []).find((f) => f.name === name);
    content.value = match ? match.content : "";
  });
  if (data.files && data.files[0]) {
    select.value = data.files[0].name;
    content.value = data.files[0].content;
  }
}

async function loadHealth() {
  const note = document.getElementById("health-note");
  if (!note) return;
  try {
    const h = await getJson("/api/health");
    note.textContent = h.note || `Inbound ready: ${h.inbound_exists}. EIP: ${h.eip_url}`;
  } catch (err) {
    note.textContent = err.message || String(err);
  }
}

const injectForm = document.getElementById("inject-form");
if (injectForm) {
  injectForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const sample = document.getElementById("sample").value;
    const content = document.getElementById("content").value;
    setStatus("Injecting…");
    try {
      const result = await getJson("/api/inject", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sample, content }),
      });
      const since = Date.now() / 1000 - 2;
      setStatus(`Dropped ${result.file}. Waiting for bucket output…`);
      try {
        const waited = await getJson(`/api/wait-results?since=${since}&timeout=45`);
        const hit = (waited.files || [])[0];
        setStatus(hit ? `Landed in ${hit.bucket}: ${hit.name}` : "Injected (no new bucket file yet)");
      } catch (_) {
        setStatus(
          `Dropped ${result.file}. No bucket output yet — start EIP with compose profile full if you need processing.`,
          true
        );
      }
      await refresh();
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

function showTab(tab) {
  document.querySelectorAll(".main-tab").forEach((b) => {
    const on = b.dataset.mainTab === tab;
    b.classList.toggle("active", on);
    b.setAttribute("aria-selected", on ? "true" : "false");
  });
  const demo = document.getElementById("tab-demo");
  const routes = document.getElementById("tab-routes");
  const experience = document.getElementById("tab-experience");
  const timing = document.getElementById("tab-timing");
  const info = document.getElementById("tab-info");
  if (demo) demo.hidden = tab !== "demo";
  if (routes) routes.hidden = tab !== "routes";
  if (experience) experience.hidden = tab !== "experience";
  if (timing) timing.hidden = tab !== "timing";
  if (info) info.hidden = tab !== "info";
  document.body.classList.toggle("routes-mode", tab === "routes");
  const nav = document.getElementById("demo-nav");
  if (nav) nav.hidden = tab !== "demo";
}

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => showTab(btn.dataset.mainTab));
});

// While build-status.active, prefer Routes so live construction is front and center.
(async () => {
  try {
    const status = await getJson("/api/build-status");
    if (status && status.active) showTab("routes");
  } catch (_) {
    /* keep Demo default */
  }
})();

loadHealth();
loadSamples().then(refresh).catch((err) => setStatus(err.message, true));
