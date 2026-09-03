(function () {
  const $ = (id) => document.getElementById(id);
  const esc = (s) =>
    String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  let data = { items: [], statuses: [], counts: {}, source: "" };
  let statusFilter = "";

  function fmtWhen(iso) {
    if (!iso) return `<span class="muted">—</span>`;
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return `<span class="muted">—</span>`;
    const txt = d.toLocaleString(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric",
      hour: "numeric",
      minute: "2-digit",
    });
    return `<time datetime="${esc(iso)}" title="${esc(iso)}">${esc(txt)}</time>`;
  }

  function rowHtml(row) {
    const page = row.page
      ? `<a href="${esc(row.page)}" target="_blank" rel="noopener">${esc(row.title)}</a>`
      : esc(row.title);
    const yt = row.youtube
      ? `<a href="${esc(row.youtube)}" target="_blank" rel="noopener">YouTube</a>`
      : `<span class="muted">—</span>`;
    const length = row.duration ? esc(row.duration) : `<span class="muted">—</span>`;
    let neu = row.new_duration ? esc(row.new_duration) : `<span class="muted">—</span>`;
    if (row.duration_sec && row.new_duration_sec) {
      const diff = row.new_duration_sec - row.duration_sec;
      const abs = Math.abs(diff);
      const mm = Math.floor(abs / 60);
      const ss = String(abs % 60).padStart(2, "0");
      const sign = diff > 0 ? "+" : diff < 0 ? "−" : "";
      const klass = diff > 15 ? "wd-over" : diff < -15 ? "wd-under" : "muted";
      neu += ` <span class="${klass}">${sign}${mm}:${ss}</span>`;
    }
    const opts = (data.statuses || [])
      .map((s) => `<option value="${esc(s.id)}" ${row.status === s.id ? "selected" : ""}>${esc(s.label)}</option>`)
      .join("");
    const origins = (data.origins || [])
      .map((s) => `<option value="${esc(s.id)}" ${row.origin === s.id ? "selected" : ""}>${esc(s.label)}</option>`)
      .join("");
    const work = row.exists ? "Open" : "Start";
    const when = fmtWhen(row.video_generated_at);
    const eic = row.eiconsole_version
      ? `<span class="wd-eic">${esc(row.eiconsole_version)}</span>`
      : `<span class="muted">—</span>`;
    return `<tr data-id="${esc(row.id)}">
      <td><select class="wd-status wd-st-${esc(row.status)}" data-field="status">${opts}</select></td>
      <td>${page}</td>
      <td><select class="wd-origin wd-or-${esc(row.origin || "unknown")}" data-field="origin">${origins}</select></td>
      <td>${yt}</td>
      <td class="wd-len">${length}</td>
      <td class="wd-len">${neu}</td>
      <td class="wd-when">${when}</td>
      <td>${eic}</td>
      <td class="wd-work"><button type="button" class="btn btn-primary" data-work>${work}</button></td>
    </tr>`;
  }

  function paint() {
    const items = data.items || [];
    const chips = $("wd-chips");
    if (chips) {
      chips.innerHTML = (data.statuses || [])
        .map((s) => {
          const n = (data.counts || {})[s.id] || 0;
          return `<button type="button" class="chip ${statusFilter === s.id ? "is-on" : ""}" data-status="${esc(s.id)}">${esc(s.label)} · ${n}</button>`;
        })
        .join("");
    }
    const total = items.length;
    const done = (data.counts || {}).done || 0;
    $("wd-count").textContent = total ? `${done} of ${total} done` : "";
    const groups = [];
    const seen = new Map();
    items.forEach((row) => {
      const g = row.group || "Other";
      if (!seen.has(g)) {
        seen.set(g, []);
        groups.push(g);
      }
      if (!statusFilter || row.status === statusFilter) seen.get(g).push(row);
    });
    const head = `<thead><tr><th>Status</th><th>Demo</th><th>Routes</th><th>Video</th><th>Length</th><th>New</th><th>Generated</th><th>eiConsole</th><th></th></tr></thead>`;
    const html = groups
      .map((g) => {
        const rows = seen.get(g) || [];
        if (!rows.length) return "";
        const gDone = items.filter((x) => x.group === g && x.status === "done").length;
        const gTotal = items.filter((x) => x.group === g).length;
        return `<article class="panel wd-group">
          <h2>${esc(g)} <span class="muted">${gDone} of ${gTotal} done</span></h2>
          <table class="wd-table">${head}<tbody>${rows.map(rowHtml).join("")}</tbody></table>
        </article>`;
      })
      .join("");
    $("wd-groups").innerHTML = html || `<p class="empty">Nothing in this filter.</p>`;
  }

  async function load() {
    const box = $("wd-groups");
    if (box) box.innerHTML = '<p class="muted">Loading…</p>';
    try {
      const resp = await fetch("/api/website-demos", { cache: "no-store" });
      data = await resp.json();
      if (!resp.ok || !data.ok) {
        if (box) box.innerHTML = `<p class="empty">${esc(data.error || "Could not load website demos.")}</p>`;
        return;
      }
      const src = $("wd-source");
      if (src && data.source) src.href = data.source;
      paint();
    } catch (err) {
      if (box) box.innerHTML = '<p class="empty">Could not load website demos.</p>';
    }
  }

  async function save(id, field, value) {
    const body = {};
    body[field] = value;
    const resp = await fetch("/api/website-demos/" + encodeURIComponent(id), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    const next = await resp.json().catch(() => ({}));
    if (!resp.ok || !next.ok) {
      alert(next.error || "Could not save.");
      return false;
    }
    data = next;
    paint();
    return true;
  }

  async function goWork(row) {
    if (row.exists && row.slug && window.pfDemos) {
      window.pfDemos.showSlug(row.slug);
      return;
    }
    if (row.status === "not_started") {
      const ok = await save(row.id, "status", "building_interface");
      if (!ok) return;
    }
    const href = row.page || row.youtube;
    if (href) window.open(href, "_blank", "noopener");
  }

  const chips = $("wd-chips");
  if (chips) {
    chips.addEventListener("click", (ev) => {
      const btn = ev.target.closest("button[data-status]");
      if (!btn) return;
      const s = btn.getAttribute("data-status") || "";
      statusFilter = statusFilter === s ? "" : s;
      paint();
    });
  }
  const groups = $("wd-groups");
  if (groups) {
    groups.addEventListener("change", (ev) => {
      const sel = ev.target.closest("select[data-field]");
      const tr = ev.target.closest("tr[data-id]");
      if (!sel || !tr) return;
      save(tr.getAttribute("data-id"), sel.getAttribute("data-field"), sel.value);
    });
    groups.addEventListener("click", (ev) => {
      const btn = ev.target.closest("button[data-work]");
      const tr = ev.target.closest("tr[data-id]");
      if (!btn || !tr) return;
      const row = (data.items || []).find((x) => x.id === tr.getAttribute("data-id"));
      if (row) goWork(row);
    });
  }

  window.pfWebsite = { load };
  if (window.pfHub && window.pfHub.read().tab === "website") load();
})();
