(function () {
  const $ = (id) => document.getElementById(id);
  const root = $("tab-calendar");
  if (!root) return;

  let state = { events: [], linked: false, start: "", end: "", error: "", sheet: null, ocr: "", busy: false, local: 0, dirty: false };
  const savedSheet = (window.pfHub && window.pfHub.read().timesheet) || null;
  if (savedSheet && savedSheet.url) state.sheet = savedSheet;

  function esc(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    }[c]));
  }

  function render() {
    const drop = `<article class="panel">
      <h2>Calendar from screenshot</h2>
      <p class="hint">Paste a screenshot of your week. Meetings plus client-request work feed the Ebility timesheet. Hours are spread across Monday–Friday.</p>
      <div class="drop-zone${state.busy ? " is-busy" : ""}" id="cal-drop">
        <input type="file" id="cal-file" accept="image/*" multiple />
        <strong>Drop or paste a screenshot</strong>
        <span>Week view works best. Re-paste the same days to replace them.</span>
        <div class="drop-actions">
          <div class="btn btn-primary drop-paste-btn" id="cal-paste" contenteditable="true" role="button" tabindex="0" inputmode="none" spellcheck="false">Paste screenshot</div>
          <button type="button" class="btn" id="cal-choose">Choose photo</button>
        </div>
        <p id="cal-drop-status" class="muted">${state.busy ? "Reading calendar…" : ""}</p>
      </div>
      ${state.ocr ? `<details class="fold"><summary>OCR text</summary><pre class="email-view">${esc(state.ocr)}</pre></details>` : ""}
    </article>`;
    const bar = `<div class="toolbar">
      <span class="muted">Screenshot calendar · ${esc(state.start)} – ${esc(state.end)}${state.local ? " · " + state.local + " from screenshot" : ""}</span>
      <button type="button" class="btn" id="cal-refresh">Refresh</button>
      <button type="button" class="btn" id="cal-clear">Clear screenshot meetings</button>
      <button type="button" class="btn btn-primary" id="cal-sheet">Generate timesheet</button>
    </div>
    <p class="hint">Meetings are grouped by customer. MedReceivables is Med Rec, CRL Plus is CRL Plus. Internal standups and timesheet reminders are not billable. Generate spreads billable hours Mon–Fri to 40.</p>`;
    const week = weekView(state.events || []);
    const sheet = state.sheet && state.sheet.url
      ? `<article class="panel">
          <h2 class="req-head">Timesheet ${esc(state.sheet.start)} – ${esc(state.sheet.end)} · ${esc(state.sheet.total)}h${state.dirty ? " · unsaved" : ""}<span class="file-icons"><a class="pdf-open" href="${esc(state.sheet.url)}" target="_blank" rel="noopener" title="Open timesheet PDF" aria-label="Open timesheet PDF"></a></span></h2>
          ${hourTable(state.sheet.rows || [])}
          <p id="sheet-copy-status" class="muted">${state.dirty ? "Left-click a day to add an hour, right-click to subtract. Save to rebuild the PDF." : ""}</p>
          ${state.dirty ? `<div class="toolbar"><button type="button" class="btn btn-primary" id="cal-sheet-save">Save timesheet</button></div>` : ""}
          <details class="fold"><summary>Timesheet PDF</summary>
          <iframe class="plan-frame" src="${esc(state.sheet.url)}" title="Timesheet PDF"></iframe>
          </details>
          ${state.sheet.copy_block ? `<details class="fold"><summary>Copy hours</summary><pre class="mail-snip" style="max-height:none">${esc(state.sheet.copy_block)}</pre></details>` : ""}
        </article>`
      : "";
    $("cal-ui").innerHTML =
      drop + bar +
      (state.error ? `<p class="job-banner is-err">${esc(state.error)}</p>` : "") +
      sheet +
      week;
  }

  function rowCopy(r) {
    return String(r.description || "").trim();
  }

  function hourTable(rows) {
    if (!rows.length) return "";
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
    const head = "<th>Customer</th>" + days.map((d) => `<th>${d}</th>`).join("") + "<th>Total</th>";
    const body = rows
      .map((r, i) => {
        const daily = r.daily || {};
        return `<tr data-row="${i}"><td data-copy="1" title="Click to copy this row">${esc(r.customer)}${r.bill ? "" : " <span class='muted'>non-bill</span>"}</td>${days
          .map((d) => `<td data-day="${d}" title="Left-click +1 · right-click −1">${Math.round(Number(daily[d] || 0))}</td>`)
          .join("")}<td>${Math.round(Number(r.grand || 0))}</td></tr>`;
      })
      .join("");
    return `<p class="hint">Left-click a day cell to add an hour, right-click to subtract (not below 0). Click the customer name to copy the row.</p><table class="sheet-hours"><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table>`;
  }

  function parseWhen(s) {
    const m = String(s || "").match(/(\d{4}-\d{2}-\d{2})[T ](\d{2}):(\d{2})/);
    if (!m) return null;
    return { day: m[1], hour: Number(m[2]), min: Number(m[3]), minutes: Number(m[2]) * 60 + Number(m[3]) };
  }

  function weekView(list) {
    if (!list.length) {
      return `<article class="panel"><p class="empty">No meetings yet. Paste a week screenshot.</p></article>`;
    }
    let mon = state.start || "";
    if (!mon) {
      const days = list.map((e) => e.day || (e.start || "").slice(0, 10)).filter(Boolean).sort();
      mon = days[0] || "";
    }
    const monDt = new Date(mon + "T00:00:00");
    const cols = [0, 1, 2, 3, 4].map((i) => {
      const d = new Date(monDt);
      d.setDate(monDt.getDate() + i);
      const iso = d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
      return { iso, label: ["Mon", "Tue", "Wed", "Thu", "Fri"][i], n: d.getDate() };
    });
    let t0 = 8 * 60;
    let t1 = 18 * 60;
    const placed = list.map((e) => {
      const a = parseWhen(e.start) || { day: e.day, hour: 9, min: 0, minutes: 9 * 60 };
      const b = parseWhen(e.end);
      const endMin = b ? b.minutes : a.minutes + Math.round(Number(e.hours || 0.5) * 60);
      t0 = Math.min(t0, Math.floor(a.minutes / 60) * 60);
      t1 = Math.max(t1, Math.ceil(endMin / 60) * 60);
      return { e, a, endMin };
    });
    t0 = Math.max(7 * 60, t0);
    t1 = Math.min(20 * 60, Math.max(t1, t0 + 60));
    const span = t1 - t0;
    const px = 52;
    const h = (span / 60) * px;
    const ticks = [];
    for (let m = t0; m < t1; m += 60) {
      const hr = m / 60;
      const label = hr === 12 ? "12 PM" : hr > 12 ? hr - 12 + " PM" : hr + " AM";
      ticks.push(`<div class="week-tick" style="top:${((m - t0) / 60) * px}px">${label}</div>`);
    }
    const dayCols = cols
      .map((col) => {
        const chips = placed
          .filter((p) => (p.e.day || p.a.day) === col.iso)
          .map((p) => {
            const top = ((p.a.minutes - t0) / 60) * px;
            const ht = Math.max(28, ((p.endMin - p.a.minutes) / 60) * px - 4);
            const kind = p.e.kind || "internal";
            const hh = String(p.a.hour).padStart(2, "0") + ":" + String(p.a.min).padStart(2, "0");
            return `<div class="week-chip is-${esc(kind)}" style="top:${top}px;height:${ht}px" title="${esc(p.e.subject)}">
              <strong>${esc(p.e.subject)}</strong>
              <span>${hh}${p.e.customer && p.e.kind !== "skip" ? " · " + esc(p.e.customer.replace("Non-Billable: Meetings, Email, AI", "Internal")) : ""}</span>
            </div>`;
          })
          .join("");
        return `<div class="week-day"><div class="week-day-track" style="height:${h}px">${chips}</div></div>`;
      })
      .join("");
    const head = cols.map((c) => `<div class="week-head-cell"><strong>${c.label}</strong> ${c.n}</div>`).join("");
    return `<article class="panel week-wrap">
      <h2>Week</h2>
      <div class="week-cal">
        <div class="week-cal-head"><div class="week-gutter"></div>${head}</div>
        <div class="week-cal-body">
          <div class="week-gutter" style="height:${h}px">${ticks.join("")}</div>
          ${dayCols}
        </div>
      </div>
    </article>`;
  }

  function rememberSheet(sheet) {
    if (window.pfHub && sheet) window.pfHub.write({ timesheet: sheet });
  }

  async function loadCal() {
    const kept = state.sheet;
    try {
      const resp = await fetch("/api/calendar", { cache: "no-store" });
      const data = await resp.json();
      Object.assign(state, data);
    } catch (err) {
      state.error = "Could not load calendar.";
    }
    const saved = (window.pfHub && window.pfHub.read().timesheet) || kept;
    if (saved && saved.url) state.sheet = saved;
    render();
  }

  async function ingestFiles(files) {
    if (!files.length) return;
    state.busy = true;
    state.error = "";
    render();
    try {
      for (const file of files) {
        const fd = new FormData();
        fd.append("file", file, file.name || "calendar.png");
        const resp = await fetch("/api/calendar/screenshot", { method: "POST", body: fd });
        const data = await resp.json().catch(() => ({}));
        state.ocr = data.ocr || "";
        if (!resp.ok) {
          state.error = data.error || "Could not read that screenshot.";
          continue;
        }
        Object.assign(state, { events: data.events || [], start: data.start, end: data.end, error: "" });
        state.local = (data.events || []).filter((e) => e.source === "screenshot").length;
      }
    } catch (err) {
      state.error = (err && err.message) || "Could not read that screenshot.";
    }
    state.busy = false;
    render();
  }

  async function show() {
    await loadCal();
  }

  function bumpHour(rowIdx, day, delta) {
    const rows = (state.sheet && state.sheet.rows) || [];
    const row = rows[rowIdx];
    if (!row || !day) return;
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
    row.daily = row.daily || {};
    row.daily[day] = Math.max(0, Math.round(Number(row.daily[day] || 0)) + delta);
    row.grand = days.reduce((s, d) => s + Math.round(Number(row.daily[d] || 0)), 0);
    row.wk1_total = row.grand;
    state.sheet.total = rows.reduce((s, r) => s + Math.round(Number(r.grand || 0)), 0);
    state.sheet.copy_block = rows.map(rowCopy).join("\n\n");
    state.dirty = true;
    render();
  }

  async function copyRow(row) {
    const text = rowCopy(row);
    try {
      await navigator.clipboard.writeText(text);
    } catch (err) {
      const ta = document.createElement("textarea");
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      ta.remove();
    }
    const note = $("sheet-copy-status");
    if (note) {
      note.hidden = false;
      note.textContent = text
        ? "Copied " + (row.customer || "row") + ": " + text
        : "Copied " + (row.customer || "row") + ".";
    }
  }

  async function saveSheet() {
    if (!state.sheet) return;
    const btn = $("cal-sheet-save");
    if (btn) {
      btn.disabled = true;
      btn.textContent = "Saving…";
    }
    try {
      const resp = await fetch("/api/calendar/timesheet/save", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sheet: state.sheet, rows: state.sheet.rows || [] }),
      });
      const data = await resp.json();
      if (!resp.ok) state.error = data.error || "Save failed";
      else {
        state.sheet = { ...(data.sheet || {}), url: data.url, file: data.file };
        state.dirty = false;
        state.error = "";
        rememberSheet(state.sheet);
      }
    } catch (err) {
      state.error = "Save failed.";
    }
    render();
  }

  $("cal-ui").addEventListener("click", async (ev) => {
    const dayCell = ev.target.closest(".sheet-hours td[data-day]");
    if (dayCell) {
      ev.preventDefault();
      const tr = dayCell.closest("tr");
      bumpHour(Number(tr && tr.dataset.row), dayCell.dataset.day, 1);
      return;
    }
    const copyCell = ev.target.closest(".sheet-hours td[data-copy]");
    if (copyCell) {
      const tr = copyCell.closest("tr");
      const row = ((state.sheet && state.sheet.rows) || [])[Number(tr && tr.dataset.row)];
      if (row) await copyRow(row);
      return;
    }
    if (ev.target.id === "cal-sheet-save") {
      await saveSheet();
      return;
    }
    if (ev.target.id === "cal-choose") {
      const inp = $("cal-file");
      if (inp) inp.click();
      return;
    }
    if (ev.target.id === "cal-refresh") {
      ev.target.disabled = true;
      await loadCal();
      return;
    }
    if (ev.target.id === "cal-clear") {
      await fetch("/api/calendar/clear", { method: "POST" });
      state.ocr = "";
      await loadCal();
      return;
    }
    if (ev.target.id === "cal-sheet") {
      ev.target.disabled = true;
      ev.target.textContent = "Building…";
      try {
        const body = state.start && state.end ? JSON.stringify({ start: state.start, end: state.end }) : "{}";
        const resp = await fetch("/api/calendar/timesheet", { method: "POST", headers: { "Content-Type": "application/json" }, body });
        const data = await resp.json();
        if (!resp.ok) state.error = data.error || "Timesheet failed";
        else {
          state.sheet = { ...(data.sheet || {}), url: data.url, file: data.file };
          state.error = "";
          rememberSheet(state.sheet);
          state.dirty = false;
        }
      } catch (err) {
        state.error = "Timesheet failed.";
      }
      render();
    }
  });
  $("cal-ui").addEventListener("contextmenu", (ev) => {
    const dayCell = ev.target.closest(".sheet-hours td[data-day]");
    if (!dayCell) return;
    ev.preventDefault();
    const tr = dayCell.closest("tr");
    bumpHour(Number(tr && tr.dataset.row), dayCell.dataset.day, -1);
  });
  $("cal-ui").addEventListener("change", (ev) => {
    if (ev.target.id === "cal-file" && ev.target.files) ingestFiles([...ev.target.files]);
  });
  $("cal-ui").addEventListener("dragover", (ev) => {
    if (!ev.target.closest("#cal-drop")) return;
    ev.preventDefault();
    ev.target.closest("#cal-drop").classList.add("is-over");
  });
  $("cal-ui").addEventListener("dragleave", (ev) => {
    const z = ev.target.closest("#cal-drop");
    if (z) z.classList.remove("is-over");
  });
  $("cal-ui").addEventListener("drop", (ev) => {
    const z = ev.target.closest("#cal-drop");
    if (!z) return;
    ev.preventDefault();
    z.classList.remove("is-over");
    ingestFiles([...ev.dataTransfer.files].filter((f) => String(f.type || "").startsWith("image/")));
  });
  $("cal-ui").addEventListener("input", (ev) => {
    const paste = ev.target.closest("#cal-paste");
    if (!paste) return;
    const imgs = [...paste.querySelectorAll("img")];
    paste.textContent = "Paste screenshot";
    if (imgs.length) Promise.all(imgs.map((img) => fetch(img.src).then((r) => r.blob()).catch(() => null))).then((blobs) =>
      ingestFiles(blobs.filter((b) => b && String(b.type || "").startsWith("image/")).map((b) => new File([b], "calendar.png", { type: b.type || "image/png" })))
    );
  });
  $("cal-ui").addEventListener("keydown", (ev) => {
    if (ev.target.closest("#cal-paste") && !ev.metaKey && !ev.ctrlKey) ev.preventDefault();
  });
  window.addEventListener("paste", (ev) => {
    const st = (window.pfHub && window.pfHub.read()) || {};
    if (st.tab !== "calendar") return;
    const files = [...(ev.clipboardData && ev.clipboardData.files) || []].filter((f) => String(f.type || "").startsWith("image/"));
    if (!files.length) return;
    ev.preventDefault();
    ingestFiles(files);
  });

  window.pfCal = { show };
  const st = (window.pfHub && window.pfHub.read()) || {};
  if (st.tab === "calendar") show();
})();
