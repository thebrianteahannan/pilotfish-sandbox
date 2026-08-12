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

function renderPatients(rows) {
  const el = document.getElementById("patients-table");
  if (!el) return;
  if (!rows.length) {
    el.innerHTML = "<p class='muted'>(no rows yet)</p>";
    return;
  }
  const cols = ["RowId", "PatientId", "FirstName", "LastName", "DateOfBirth", "City", "StateCode", "LoadedAt"];
  el.innerHTML =
    "<table class='data'><thead><tr>" +
    cols.map((c) => `<th>${c}</th>`).join("") +
    "</tr></thead><tbody>" +
    rows
      .map(
        (r) =>
          "<tr>" +
          cols.map((c) => `<td>${r[c] != null ? String(r[c]) : ""}</td>`).join("") +
          "</tr>"
      )
      .join("") +
    "</tbody></table>";
}

async function refresh() {
  try {
    const patients = await getJson("/api/patients");
    renderPatients(patients.rows || []);
  } catch (err) {
    renderPatients([]);
    setStatus(err.message || String(err), true);
  }
  try {
    const archive = await getJson("/api/archive");
    renderFiles("archive-list", "archive-view", archive.files || []);
  } catch (_) {
    /* optional */
  }
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const select = document.getElementById("sample");
  const content = document.getElementById("content");
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
  if (data.files && data.files[0]) {
    select.value = data.files[0].name;
    content.value = data.files[0].content;
  }
}

async function loadHealth() {
  const note = document.getElementById("health-note");
  try {
    const h = await getJson("/api/health");
    note.textContent = h.db_ok
      ? `DB connected · SFTP ${h.sftp_hint}`
      : `DB not ready yet (${h.db_error || "waiting"}) · SFTP ${h.sftp_hint}`;
  } catch (err) {
    note.textContent = err.message || String(err);
  }
}

document.getElementById("inject-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const sample = document.getElementById("sample").value;
  const content = document.getElementById("content").value;
  setStatus("Dropping on SFTP…");
  try {
    let before = 0;
    try {
      const cur = await getJson("/api/patients");
      before = Math.max(0, ...((cur.rows || []).map((r) => Number(r.RowId) || 0)), 0);
    } catch (_) {
      before = 0;
    }
    const result = await getJson("/api/inject", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sample, content }),
    });
    setStatus(`Dropped ${result.file}. Waiting for SQL…`);
    try {
      const waited = await getJson(`/api/wait-patients?before=${before}&timeout=90`);
      setStatus(`Loaded ${(waited.rows || []).length} new row(s)`);
    } catch (err) {
      setStatus(err.message || "Timeout — check EIP logs", true);
    }
    await refresh();
  } catch (err) {
    setStatus(err.message || String(err), true);
  }
});

document.getElementById("refresh-btn").addEventListener("click", () => {
  refresh().catch((err) => setStatus(err.message, true));
});

function showTab(tab) {
  document.querySelectorAll(".main-tab").forEach((b) => {
    const on = b.dataset.mainTab === tab;
    b.classList.toggle("active", on);
    b.setAttribute("aria-selected", on ? "true" : "false");
  });
  ["demo", "routes", "experience", "timing", "info"].forEach((id) => {
    const el = document.getElementById(`tab-${id}`);
    if (el) el.hidden = tab !== id;
  });
  const nav = document.getElementById("demo-nav");
  if (nav) nav.hidden = tab !== "demo";
  document.body.classList.toggle("routes-mode", tab === "routes");
}

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => showTab(btn.dataset.mainTab));
});

(async () => {
  try {
    const status = await getJson("/api/build-status");
    if (status && status.active) showTab("routes");
  } catch (_) {
    /* Demo default */
  }
})();

loadHealth();
loadSamples().then(refresh).catch((err) => setStatus(err.message, true));
