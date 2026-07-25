const statusEl = () => document.getElementById("status");
const resultsEl = () => document.getElementById("results");

function setStatus(msg, cls = "") {
  const el = statusEl();
  el.textContent = msg;
  el.className = `status ${cls}`.trim();
}

function renderHl7(files) {
  const root = resultsEl();
  if (!files.length) {
    root.innerHTML = "<p class='section-lead'>No HL7 files matched yet.</p>";
    return;
  }
  root.innerHTML = files
    .map(
      (f) => `
      <article class="result-card">
        <header>
          <strong>${f.name}</strong>
          <span>${f.mtime} · ${f.size} bytes</span>
        </header>
        <pre class="hl7-box">${escapeHtml(f.content)}</pre>
      </article>`
    )
    .join("");
}

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

async function refreshEvents() {
  const res = await fetch("/api/events");
  const data = await res.json();
  const tbody = document.querySelector("#events-table tbody");
  tbody.innerHTML = (data.events || [])
    .map((e) => {
      const multi = e.EventType === "MULTI";
      return `<tr>
        <td>${e.EventId}</td>
        <td><span class="pill ${multi ? "multi" : ""}">${e.EventType}</span>${
          e.ChildEventTypes ? `<div class="mono" style="color:var(--muted);font-size:.75rem;margin-top:.2rem">${e.ChildEventTypes}</div>` : ""
        }</td>
        <td>${e.LastName}, ${e.FirstName}<div class="mono" style="color:var(--muted);font-size:.75rem">${e.OffenderId}</div></td>
        <td>${e.SourceSystem}</td>
        <td>${e.FacilityCode} / ${e.UnitCode || "-"} / ${e.BedCode || "-"}</td>
        <td>${e.Status}</td>
      </tr>`;
    })
    .join("");
}

async function refreshRecentHl7() {
  const res = await fetch("/api/hl7");
  const data = await res.json();
  renderHl7((data.files || []).slice(0, 8));
}

async function addEvent(ev) {
  ev.preventDefault();
  const form = ev.target;
  const btn = form.querySelector("button[type=submit]");
  btn.disabled = true;
  setStatus("Inserting event into SQL Server…");

  const body = {
    offenderId: form.offenderId.value,
    eventType: form.eventType.value,
    childEventTypes: form.childEventTypes.value,
    notes: form.notes.value || undefined,
  };

  try {
    const res = await fetch("/api/events", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const data = await res.json();
    if (!data.ok) throw new Error("Insert failed");

    setStatus(
      `Event ${data.eventId} inserted (${data.eventType}). Waiting for PilotFish poll + HL7 generation…`
    );
    await refreshEvents();

    const wait = await fetch(`/api/wait-hl7/${data.eventId}?timeout=50`);
    const waitData = await wait.json();
    if (waitData.ready && waitData.files.length) {
      setStatus(
        `Generated ${waitData.files.length} HL7 message(s) for event ${data.eventId}.`,
        "ok"
      );
      renderHl7(waitData.files);
    } else {
      setStatus(
        `Event ${data.eventId} is in the DB, but HL7 files were not ready yet. PilotFish polls every ~15s — try Refresh Results.`,
        "err"
      );
      await refreshRecentHl7();
    }
  } catch (err) {
    console.error(err);
    setStatus(`Failed: ${err.message || err}`, "err");
  } finally {
    btn.disabled = false;
  }
}

function wireRouteDetails() {
  document.querySelectorAll(".node[data-detail]").forEach((node) => {
    node.addEventListener("click", () => {
      const id = node.getAttribute("data-detail");
      const panel = document.getElementById(id);
      const section = node.closest("section");
      section.querySelectorAll(".node").forEach((n) => n.classList.remove("active"));
      section.querySelectorAll(".detail").forEach((d) => d.classList.remove("open"));
      node.classList.add("active");
      if (panel) panel.classList.add("open");
    });
  });
}

function syncPresetChildren() {
  const type = document.getElementById("eventType");
  const children = document.getElementById("childEventTypes");
  const apply = () => {
    if (type.value === "MULTI" && !children.value) {
      children.value = "ADMIT,BED_ASSIGN,DEMO_UPDATE";
    }
    if (type.value !== "MULTI") children.value = "";
  };
  type.addEventListener("change", apply);
}

document.addEventListener("DOMContentLoaded", () => {
  const eip = document.getElementById("eip-link");
  if (eip) eip.href = `http://${window.location.hostname}:8091/eip/`;
  wireRouteDetails();
  syncPresetChildren();
  document.getElementById("event-form").addEventListener("submit", addEvent);
  document.getElementById("refresh-hl7").addEventListener("click", refreshRecentHl7);
  refreshEvents();
  refreshRecentHl7();
});
