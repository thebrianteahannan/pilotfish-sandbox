const statusEl = () => document.getElementById("status");
const resultsEl = () => document.getElementById("results");

function setStatus(msg, cls = "") {
  const el = statusEl();
  el.textContent = msg;
  el.className = `status ${cls}`.trim();
}

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

async function readJson(res) {
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    const snippet = (text || "").replace(/\s+/g, " ").slice(0, 160);
    throw new Error(
      res.ok
        ? `Unexpected non-JSON response: ${snippet || "(empty)"}`
        : `Server error ${res.status}. ${snippet || "SQL Server may be restarting — wait a few seconds and retry."}`
    );
  }
  if (!res.ok) {
    throw new Error((data && data.error) || `Request failed (${res.status})`);
  }
  return data;
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

function dbPillClass(engine) {
  const e = String(engine || "").toLowerCase();
  if (e.includes("oracle")) return "db-oracle";
  if (e.includes("sql")) return "db-sqlserver";
  return "";
}

async function refreshHealth() {
  try {
    const data = await readJson(await fetch("/api/health"));
    const root = document.getElementById("db-health");
    if (!root) return data;
    root.querySelectorAll(".db-chip").forEach((chip) => {
      const key = chip.getAttribute("data-db");
      const up = data[key] === "up";
      chip.classList.toggle("up", up);
      chip.classList.toggle("down", !up);
      chip.textContent =
        key === "oracle"
          ? `Oracle ${up ? "up" : "down"}`
          : `SQL Server ${up ? "up" : "down"}`;
    });
    return data;
  } catch (err) {
    const root = document.getElementById("db-health");
    if (root) {
      root.querySelectorAll(".db-chip").forEach((chip) => {
        chip.classList.add("down");
        chip.classList.remove("up");
      });
    }
    throw err;
  }
}

async function refreshEvents() {
  try {
    const data = await readJson(await fetch("/api/events"));
    const tbody = document.querySelector("#events-table tbody");
    tbody.innerHTML = (data.events || [])
      .map((e) => {
        const multi = e.EventType === "MULTI";
        const statusClass =
          String(e.Status).toUpperCase() === "PROCESSED" ? "processed" : "pending";
        const dbClass = dbPillClass(e.DbEngine);
        return `<tr>
        <td>${e.EventId}</td>
        <td><span class="pill ${dbClass}">${escapeHtml(e.DbEngine || "?")}</span></td>
        <td><span class="pill ${multi ? "multi" : ""}">${e.EventType}</span>${
          e.ChildEventTypes
            ? `<div class="mono" style="color:var(--muted);font-size:.75rem;margin-top:.2rem">${escapeHtml(
                e.ChildEventTypes
              )}</div>`
            : ""
        }</td>
        <td>${escapeHtml(e.LastName)}, ${escapeHtml(e.FirstName)}<div class="mono" style="color:var(--muted);font-size:.75rem">${escapeHtml(
          e.OffenderId
        )}</div></td>
        <td>${escapeHtml(e.SourceSystem)}</td>
        <td>${escapeHtml(e.FacilityCode)} / ${escapeHtml(e.UnitCode || "-")} / ${escapeHtml(e.BedCode || "-")}</td>
        <td><span class="pill ${statusClass}">${escapeHtml(e.Status)}</span></td>
      </tr>`;
      })
      .join("");
  } catch (err) {
    setStatus(`Could not load events: ${err.message || err}`, "err");
  }
}

async function refreshRecentHl7() {
  try {
    const data = await readJson(await fetch("/api/hl7"));
    renderHl7((data.files || []).slice(0, 8));
  } catch (err) {
    setStatus(`Could not load HL7: ${err.message || err}`, "err");
  }
}

async function addEvent(ev) {
  ev.preventDefault();
  const form = ev.target;
  const btn = form.querySelector("button[type=submit]");
  btn.disabled = true;

  const targetDatabase = document.getElementById("targetDatabase").value;
  const dbLabel = targetDatabase === "sqlserver" ? "SQL Server Housing" : "Oracle OMS";
  setStatus(`Inserting event into ${dbLabel}…`);

  const eventType = document.getElementById("eventType").value;
  const body = {
    offenderId: document.getElementById("offenderId").value,
    eventType,
    targetDatabase,
    childEventTypes: document.getElementById("childEventTypes").value,
    notes: document.getElementById("notes").value || undefined,
  };

  try {
    const health = await refreshHealth();
    const dbKey = targetDatabase === "sqlserver" ? "sqlserver" : "oracle";
    if (health[dbKey] !== "up") {
      throw new Error(`${dbLabel} is down — pick the other database or wait for it to recover.`);
    }

    const data = await readJson(
      await fetch("/api/events", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      })
    );
    if (!data.ok) throw new Error(data.error || "Insert failed");

    setStatus(
      `Event ${data.eventId} inserted into ${data.dbEngine} (${data.eventType}). Waiting for PilotFish poll + shared Route 2 HL7…`
    );
    await refreshEvents();

    const waitData = await readJson(await fetch(`/api/wait-hl7/${data.eventId}?timeout=50`));
    if (waitData.ready && waitData.files.length) {
      setStatus(
        `Generated ${waitData.files.length} HL7 message(s) for ${data.dbEngine} event ${data.eventId}.`,
        "ok"
      );
      renderHl7(waitData.files);
    } else {
      setStatus(
        `Event ${data.eventId} is in ${data.dbEngine}, but HL7 files were not ready yet. PilotFish polls every ~15s — try Refresh Results.`,
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
  const target = document.getElementById("targetDatabase");
  const children = document.getElementById("childEventTypes");
  const apply = () => {
    if (type.value !== "MULTI") {
      children.value = "";
      return;
    }
    // Sensible defaults by DB role; user can edit either way.
    children.value =
      target.value === "sqlserver"
        ? "TRANSFER,BED_ASSIGN"
        : "ADMIT,BED_ASSIGN,DEMO_UPDATE";
  };
  type.addEventListener("change", apply);
  target.addEventListener("change", apply);
  apply();
}

document.addEventListener("DOMContentLoaded", () => {
  const eip = document.getElementById("eip-link");
  if (eip) eip.href = `http://${window.location.hostname}:8091/eip/`;
  wireRouteDetails();
  syncPresetChildren();
  document.getElementById("event-form").addEventListener("submit", addEvent);
  document.getElementById("refresh-hl7").addEventListener("click", refreshRecentHl7);
  document.querySelectorAll(".main-tab").forEach((btn) => {
    btn.addEventListener("click", () => {
      const tab = btn.dataset.mainTab;
      document.querySelectorAll(".main-tab").forEach((b) => {
        const on = b.dataset.mainTab === tab;
        b.classList.toggle("active", on);
        b.setAttribute("aria-selected", on ? "true" : "false");
      });
      const demo = document.getElementById("tab-demo");
      const info = document.getElementById("tab-info");
      if (demo) demo.hidden = tab !== "demo";
      if (info) info.hidden = tab !== "info";
      const nav = document.getElementById("demo-nav");
      if (nav) nav.hidden = tab !== "demo";
    });
  });
  refreshHealth().catch(() => {});
  refreshEvents();
  refreshRecentHl7();
  setInterval(() => {
    refreshHealth().catch(() => {});
  }, 15000);
});
