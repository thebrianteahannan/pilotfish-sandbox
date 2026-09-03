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

const KIND_EXT = { hl7: ".hl7", edi: ".edi", fhir: ".json" };
const KIND_WAIT = { hl7: "BUNNY", edi: "BEN KILDARE SERVICE", fhir: "CHALMERS" };

async function refresh() {
  const data = await getJson("/api/results");
  show("hl7-xml", data.hl7Xml);
  show("patient-xml", data.patientXml);
  show("sql-xml", data.sqlXml);
  show("json-out", data.jsonOut);
  const box = document.getElementById("patients");
  if (!box) return;
  box.innerHTML = "";
  (data.patients || []).forEach((row) => {
    const p = document.createElement("p");
    p.className = "muted";
    p.textContent = `${row.LASTNAME}, ${row.FIRSTNAME || ""}  DOB ${row.DOB || ""}  MRN ${row.MRN || ""}`;
    box.appendChild(p);
  });
  return data;
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const select = document.getElementById("sample");
  const box = document.getElementById("file-text");
  const kind = document.getElementById("kind");
  if (!select || !box) return;

  function applyKind() {
    const ext = KIND_EXT[kind.value] || "";
    const files = (data.files || []).filter((f) => f.name.toLowerCase().endsWith(ext));
    select.innerHTML = '<option value="">(custom / paste below)</option>';
    files.forEach((f) => {
      const opt = document.createElement("option");
      opt.value = f.name;
      opt.textContent = f.name;
      select.appendChild(opt);
    });
    if (files[0]) {
      select.value = files[0].name;
      box.value = files[0].content || "";
    } else {
      box.value = "";
    }
  }

  select.addEventListener("change", () => {
    const match = (data.files || []).find((f) => f.name === select.value);
    box.value = match && match.content ? match.content : "";
  });
  kind.addEventListener("change", applyKind);
  applyKind();
}

const form = document.getElementById("inject-form");
if (form) {
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const kind = document.getElementById("kind").value;
    setStatus(kind === "hl7" ? "Sending over LLP…" : kind === "edi" ? "Dropping on FTP…" : "POSTing FHIR…");
    try {
      const prior = await getJson("/api/results");
      const after = (prior.patients && prior.patients[0] && prior.patients[0].ID) || 0;
      const result = await getJson("/api/inject", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          kind,
          sample: document.getElementById("sample").value,
          text: document.getElementById("file-text").value,
        }),
      });
      setStatus(result.ack ? `ACK: ${String(result.ack).slice(0, 80)}` : result.dropped ? `Dropped ${result.dropped}` : "Sent");
      const last = KIND_WAIT[kind] || "";
      const q = last ? `&last=${encodeURIComponent(last)}` : "";
      await getJson(`/api/wait-patient?timeout=90&after=${after}${q}`);
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
