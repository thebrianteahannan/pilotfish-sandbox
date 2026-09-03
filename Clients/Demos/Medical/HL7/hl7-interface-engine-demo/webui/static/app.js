document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => {
    const tab = btn.dataset.mainTab;
    document.querySelectorAll(".main-tab").forEach((b) => {
      b.classList.toggle("active", b === btn);
    });
    ["demo", "routes", "timing", "info", "video"].forEach((name) => {
      const el = document.getElementById(`tab-${name}`);
      if (el) el.hidden = tab !== name;
    });
  });
});

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
  el.style.color = isError ? "#b91c1c" : "";
}

function show(id, text) {
  const el = document.getElementById(id);
  if (el) el.textContent = text || "(none yet)";
}

async function refresh() {
  const data = await getJson("/api/results");
  show("hl7-xml", data.hl7Xml);
  show("patient-xml", data.patientXml);
  show("sql-xml", data.sqlXml);
  const box = document.getElementById("patients");
  if (!box) return;
  box.innerHTML = "";
  (data.patients || []).forEach((row) => {
    const p = document.createElement("p");
    p.className = "muted";
    p.textContent = `${row.LastName}, ${row.FirstName}  DOB ${row.DateOfBirth}  ${row.MessageControlId || ""}`;
    box.appendChild(p);
  });
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const select = document.getElementById("sample");
  const box = document.getElementById("file-text");
  if (!select || !box) return;
  (data.files || []).forEach((f) => {
    const opt = document.createElement("option");
    opt.value = f.name;
    opt.textContent = f.name;
    select.appendChild(opt);
  });
  if (data.files && data.files[0]) {
    select.value = data.files[0].name;
    box.value = data.files[0].content || "";
  }
  select.addEventListener("change", () => {
    const match = (data.files || []).find((f) => f.name === select.value);
    box.value = match && match.content ? match.content : "";
  });
}

const form = document.getElementById("inject-form");
if (form) {
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    setStatus("Sending over LLP…");
    try {
      const prior = await getJson("/api/results");
      const after = (prior.patients && prior.patients[0] && prior.patients[0].RowId) || 0;
      const result = await getJson("/api/inject", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          sample: document.getElementById("sample").value,
          text: document.getElementById("file-text").value,
        }),
      });
      setStatus(result.ack ? `ACK: ${result.ack.slice(0, 80)}` : "Sent");
      await getJson(`/api/wait-patient?timeout=90&after=${after}`);
      await refresh();
    } catch (err) {
      setStatus(err.message || String(err), true);
    }
  });
}
const refreshBtn = document.getElementById("refresh-btn");
if (refreshBtn) refreshBtn.addEventListener("click", () => refresh().catch(() => {}));
loadSamples().catch(() => {});
refresh().catch(() => {});
