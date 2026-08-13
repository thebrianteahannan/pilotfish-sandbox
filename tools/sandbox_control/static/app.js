(function () {
  const $ = (id) => document.getElementById(id);
  const demoList = $("demo-list");
  const filter = $("filter");
  const runningOnly = $("running-only");
  const jobBanner = $("job-banner");
  const FAMILY_ORDER = ["Insurance", "Medical", "Other"];
  const CAT_ORDER = ["Insurance/EDI", "Medical/HL7", "Medical/FHIR", "Other"];
  const PHASES = {
    queued: "Queued",
    starting: "Starting",
    tts: "Synthesizing narration",
    recording: "Recording the browser",
    mux: "Combining audio and video",
    transcript: "Writing the transcript",
    done: "Done",
    error: "Export failed",
    construction_video: "Creating construction video",
  };
  let demos = [];
  let videoWorker = {};
  let busy = false;
  let diskLoaded = false;
  let familyFilter = "";
  let catFilter = "";
  let pollTimer = null;
  const TABS = ["demos", "clients", "disk", "docker"];
  const STORE = "pf-hub-ui";

  function hubRead() {
    try {
      const data = JSON.parse(localStorage.getItem(STORE) || "{}");
      return data && typeof data === "object" ? data : {};
    } catch (err) {
      return {};
    }
  }
  function hubWrite(part) {
    try {
      localStorage.setItem(STORE, JSON.stringify(Object.assign(hubRead(), part || {})));
    } catch (err) {}
  }
  function paintTab(tab) {
    if (!TABS.includes(tab)) tab = "demos";
    document.querySelectorAll(".tab").forEach((b) => b.classList.toggle("is-on", b.dataset.tab === tab));
    document.querySelectorAll(".tab-panel").forEach((p) => {
      p.hidden = p.id !== "tab-" + tab;
    });
    return tab;
  }
  window.pfHub = {
    read: hubRead,
    write: hubWrite,
    paint: paintTab,
    holdScroll(fn) {
      const x = window.scrollX;
      const y = window.scrollY;
      const inner = [...document.querySelectorAll(".plan-view,.email-view,.diff-view,.req-hist")].map((el) => [
        el.className.split(" ")[0],
        el.scrollTop,
      ]);
      fn();
      const put = () => {
        window.scrollTo(x, y);
        inner.forEach(([cls, top]) => {
          const el = document.querySelector("." + cls);
          if (el) el.scrollTop = top;
        });
      };
      put();
      requestAnimationFrame(put);
    },
    boot() {
      const st = hubRead();
      if (st.tab === "disk") loadDisk();
      if (st.tab === "docker" && window.pfDocker) window.pfDocker.load();
      if (st.tab === "clients" && window.pfClients) window.pfClients.restore();
    },
  };

  const saved = hubRead();
  if (saved.demoQ) filter.value = saved.demoQ;
  if (saved.runningOnly) runningOnly.checked = true;
  familyFilter = saved.family || "";
  catFilter = saved.cat || "";
  paintTab(saved.tab || "demos");

  document.querySelectorAll(".tab").forEach((btn) => {
    btn.addEventListener("click", () => {
      const tab = paintTab(btn.dataset.tab);
      hubWrite({ tab });
      if (tab === "disk" && !diskLoaded) loadDisk();
      if (tab === "docker" && window.pfDocker) window.pfDocker.load();
      if (tab === "clients" && window.pfClients) window.pfClients.show();
    });
  });

  function esc(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    }[c]));
  }

  function catLabel(cat) {
    return String(cat || "Other").replaceAll("/", " / ");
  }

  function fmtSec(sec) {
    sec = Math.max(0, Math.floor(Number(sec) || 0));
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return m ? `${m}m ${String(s).padStart(2, "0")}s` : `${s}s`;
  }

  function elapsedSec(job) {
    const started = Date.parse((job && job.started_at) || "") || 0;
    if (!started) return 0;
    return Math.max(0, Math.floor((Date.now() - started) / 1000));
  }

  function timeLine(job) {
    const parts = [`Elapsed ${fmtSec(elapsedSec(job))}`];
    const left = Number(job && job.remaining_sec);
    if (Number.isFinite(left) && left > 0) parts.push(`about ${fmtSec(left)} left`);
    return parts.join(" · ");
  }

  function sortKey(list, order) {
    return [...list].sort((a, b) => {
      const ia = order.indexOf(a);
      const ib = order.indexOf(b);
      return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib) || a.localeCompare(b);
    });
  }

  function setJob(job) {
    busy = !!(job && job.busy);
    if ($("tab-clients") && !$("tab-clients").hidden) return;
    if (!jobBanner) return;
    const err = (job && job.error) || "";
    const msg = (job && job.message) || "";
    const rec = demos.find((d) => d.video && d.video.status === "running");
    const queuedN = demos.filter((d) => d.video && d.video.status === "queued").length;
    let text = "";
    let isErr = !!err;
    if (busy || err) text = err || msg;
    else if (rec) text = `Recording construction video for ${rec.slug}…` + (queuedN ? ` · ${queuedN} queued` : "");
    else if (!videoWorker.up) text = "Video worker is down — Create video will start it.";
    else if (msg && msg !== "Idle") text = msg;
    if (text) {
      jobBanner.hidden = false;
      jobBanner.textContent = text;
      jobBanner.classList.toggle("is-err", isErr);
    } else {
      jobBanner.hidden = true;
    }
  }

  function matches(d, q) {
    if (runningOnly.checked && !d.running) return false;
    if (familyFilter && d.family !== familyFilter) return false;
    if (catFilter && d.category !== catFilter) return false;
    if (!q) return true;
    const hay = `${d.slug} ${d.title} ${d.category} ${d.family} ${d.running ? "running" : "stopped"}`.toLowerCase();
    return hay.includes(q);
  }

  function videoBlock(d, videoBusy) {
    const v = d.video || {};
    const job = v.job || {};
    const running = v.status === "running";
    const queued = v.status === "queued";
    const failed = v.status === "error";
    const ready = !!(v.ready && !running && !queued);
    const btnLabel = queued
      ? "Queued"
      : videoBusy && !running
        ? ready || failed
          ? "Queue re-create"
          : "Queue video"
        : ready || failed
          ? "Re-create video"
          : "Create video";
    const watch = v.ready
      ? `<a href="/api/demos/${encodeURIComponent(d.slug)}/video/file" target="_blank" rel="noopener">Watch</a>`
      : "";
    const behind = job.behind || v.behind || "";
    const state = running
      ? "Recording…"
      : queued
        ? behind
          ? `Queued behind ${behind}`
          : "Queued"
        : failed
          ? esc(job.message || "Export failed")
          : v.ready
            ? `Ready${v.size_label ? " · " + v.size_label : ""}`
            : "No video yet";
    let panel = "";
    if (queued) {
      panel = `<div class="video-panel">
        <p class="video-phase">Queued</p>
        <p class="video-msg">${esc(job.message || (behind ? `Starts after ${behind} finishes.` : "Waiting for the current recording to finish."))}</p>
      </div>`;
    } else if (running || failed) {
      const phase = PHASES[job.phase] || PHASES.construction_video;
      const step = Number(job.step) || 0;
      const total = Number(job.step_total) || 0;
      const phaseText = total > 0 && step > 0 ? `${phase} (${step} of ${total})` : phase;
      const rows = Array.isArray(job.log) ? job.log.slice(-6) : [];
      const log = rows
        .map((row) => {
          const text = typeof row === "string" ? row : (row && row.text) || "";
          return text ? `<li>${esc(text)}</li>` : "";
        })
        .join("");
      const bar =
        total > 0
          ? `<div class="barwrap"><div class="bar" style="width:${Math.min(100, Math.round((step / total) * 100))}%"></div></div>`
          : "";
      panel = `<div class="video-panel ${failed ? "is-error" : ""}">
        <p class="video-phase">${esc(failed ? "Export failed" : phaseText)}</p>
        ${bar}
        <p class="video-msg">${esc(job.message || (failed ? job.error : "Working…") || "")}</p>
        <p class="muted">${running ? esc(timeLine(job)) : ""}</p>
        ${log ? `<ul class="video-log">${log}</ul>` : ""}
        ${failed && job.error ? `<p class="video-err">${esc(job.error)}</p>` : ""}
      </div>`;
    }
    return `<div class="video-row">
      <span class="video-state">${esc(state)}</span>
      ${watch}
      <button type="button" class="btn btn-video" data-act="video" ${busy || running || queued ? "disabled" : ""}>${btnLabel}</button>
    </div>${panel}`;
  }

  function cardHtml(d, videoBusy) {
    const urls = d.local_url
      ? `<div class="urls"><a href="${esc(d.local_url)}" target="_blank" rel="noopener">Local</a>` +
        (d.lan_url ? `<a href="${esc(d.lan_url)}" target="_blank" rel="noopener">LAN</a>` : "") +
        ` :${d.webui_port}</div>`
      : "";
    const rec = d.video && (d.video.status === "running" || d.video.status === "queued");
    return `<article class="card" data-slug="${esc(d.slug)}">
      <div>
        <h3>${esc(d.title)}</h3>
        <code>${esc(d.slug)}</code>
        ${urls}
      </div>
      <div>
        <div style="text-align:right;margin-bottom:0.4rem">
          <span class="badge ${d.running ? "on" : "off"}">${d.running ? "Running" : "Stopped"}</span>
        </div>
        <div class="actions">
          <button type="button" class="btn btn-primary" data-act="start" ${busy || d.running ? "disabled" : ""}>Start</button>
          <button type="button" class="btn" data-act="restart" ${busy || rec ? "disabled" : ""}>Restart</button>
          <button type="button" class="btn btn-quiet" data-act="stop" ${busy || rec || !d.running ? "disabled" : ""}>Stop</button>
        </div>
      </div>
      ${videoBlock(d, videoBusy)}
    </article>`;
  }

  function renderChips() {
    const fams = sortKey(
      [...new Set(demos.map((d) => d.family).filter(Boolean))],
      FAMILY_ORDER
    );
    $("family-chips").innerHTML =
      `<button type="button" class="chip ${familyFilter ? "" : "is-on"}" data-family="">All</button>` +
      fams
        .map(
          (f) =>
            `<button type="button" class="chip ${familyFilter === f ? "is-on" : ""}" data-family="${esc(f)}">${esc(f)}</button>`
        )
        .join("");
    const cats = sortKey(
      [
        ...new Set(
          demos
            .filter((d) => !familyFilter || d.family === familyFilter)
            .map((d) => d.category)
            .filter(Boolean)
        ),
      ],
      CAT_ORDER
    );
    const catEl = $("category-chips");
    if (cats.length <= 1 && familyFilter) {
      catEl.innerHTML = "";
      catEl.hidden = true;
      return;
    }
    catEl.hidden = false;
    catEl.innerHTML =
      `<button type="button" class="chip ${catFilter ? "" : "is-on"}" data-cat="">All ${esc(familyFilter || "categories")}</button>` +
      cats
        .map(
          (c) =>
            `<button type="button" class="chip ${catFilter === c ? "is-on" : ""}" data-cat="${esc(c)}">${esc(catLabel(c))}</button>`
        )
        .join("");
  }

  function renderDemos() {
    const q = (filter.value || "").trim().toLowerCase();
    const rows = demos.filter((d) => matches(d, q));
    $("demo-count").textContent = `${rows.length} shown · ${demos.filter((d) => d.running).length} running`;
    renderChips();
    if (!rows.length) {
      demoList.innerHTML = '<p class="empty">No demos match.</p>';
      return;
    }
    const groups = new Map();
    rows.forEach((d) => {
      const k = d.category || "Other";
      if (!groups.has(k)) groups.set(k, []);
      groups.get(k).push(d);
    });
    const keys = sortKey([...groups.keys()], CAT_ORDER);
    const videoBusy = demos.some((d) => d.video && (d.video.status === "running" || d.video.status === "queued"));
    demoList.innerHTML = keys
      .map(
        (k) =>
          `<section class="demo-group"><h2>${esc(catLabel(k))}</h2>${groups
            .get(k)
            .map((d) => cardHtml(d, videoBusy))
            .join("")}</section>`
      )
      .join("");
  }

  function schedulePoll() {
    if (pollTimer) clearTimeout(pollTimer);
    const rec = demos.some((d) => d.video && (d.video.status === "running" || d.video.status === "queued"));
    pollTimer = setTimeout(loadDemos, rec ? 1000 : 3000);
  }

  async function loadDemos() {
    try {
      const resp = await fetch("/api/demos", { cache: "no-store" });
      const data = await resp.json();
      demos = data.demos || [];
      videoWorker = data.video_worker || {};
      setJob(data.job);
      window.pfHub.holdScroll(renderDemos);
    } catch (err) {
      if (jobBanner) {
        jobBanner.hidden = false;
        jobBanner.textContent = "Could not load demos.";
        jobBanner.classList.add("is-err");
      }
    }
    schedulePoll();
  }

  $("family-chips").addEventListener("click", (ev) => {
    const btn = ev.target.closest("button[data-family]");
    if (!btn) return;
    familyFilter = btn.dataset.family || "";
    catFilter = "";
    hubWrite({ family: familyFilter, cat: "" });
    renderDemos();
  });
  $("category-chips").addEventListener("click", (ev) => {
    const btn = ev.target.closest("button[data-cat]");
    if (!btn) return;
    catFilter = btn.dataset.cat || "";
    if (catFilter) familyFilter = catFilter.split("/")[0];
    hubWrite({ family: familyFilter, cat: catFilter });
    renderDemos();
  });

  demoList.addEventListener("click", async (ev) => {
    const btn = ev.target.closest("button[data-act]");
    if (!btn || btn.disabled) return;
    const card = btn.closest("[data-slug]");
    const slug = card && card.dataset.slug;
    const act = btn.dataset.act;
    if (!slug || !act) return;
    if (act === "video") {
      const d = demos.find((x) => x.slug === slug);
      const other = demos.find(
        (x) => x.slug !== slug && x.video && (x.video.status === "running" || x.video.status === "queued")
      );
      const bits = [];
      if (other) {
        bits.push(`Another video is in progress (${other.slug}). This one will queue and start when that finishes.`);
      }
      if (d && d.video && d.video.ready) bits.push("This replaces the current construction-replay.mp4.");
      if (d && !d.running && !other) bits.push("The demo will start first (other Clients/ stacks stop).");
      bits.push("Continue?");
      if (!confirm(bits.join(" "))) return;
    }
    btn.disabled = true;
    try {
      const resp = await fetch(`/api/demos/${encodeURIComponent(slug)}/${act}`, { method: "POST" });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) {
        setJob({ busy: false, error: data.error || "Request failed", message: "" });
      }
    } catch (err) {
      setJob({ busy: false, error: "Could not reach the hub.", message: "" });
    }
    loadDemos();
  });

  filter.addEventListener("input", () => {
    hubWrite({ demoQ: filter.value });
    renderDemos();
  });
  runningOnly.addEventListener("change", () => {
    hubWrite({ runningOnly: runningOnly.checked });
    renderDemos();
  });

  function bar(bytes, max) {
    const pct = max > 0 ? Math.min(100, Math.round((bytes / max) * 100)) : 0;
    return `<div class="barwrap"><div class="bar" style="width:${pct}%"></div></div>`;
  }

  function fileRow(item, { del } = {}) {
    const delBtn =
      del && item.deletable
        ? `<button type="button" class="btn btn-danger" data-del="${esc(item.path)}">Delete</button>`
        : "";
    return `<div class="row"><span class="path">${esc(item.path || item.slug)}</span><strong>${esc(item.label)}</strong>${delBtn}</div>`;
  }

  async function loadDisk(force) {
    $("disk-total").textContent = "Scanning…";
    try {
      const resp = await fetch("/api/disk" + (force ? "?refresh=1" : ""), { cache: "no-store" });
      const data = await resp.json();
      diskLoaded = true;
      $("disk-total").textContent = `Repo ${data.total_label || ""}`;
      const folders = data.top_folders || [];
      const fmax = folders[0] ? folders[0].bytes : 0;
      $("disk-folders").innerHTML =
        folders
          .map(
            (r) =>
              `<div class="row"><span>${esc(r.path)}${r.note ? ` <span class="muted">(${esc(r.note)})</span>` : ""}</span>${bar(r.bytes, fmax)}<strong>${esc(r.label)}</strong></div>`
          )
          .join("") || '<p class="empty">No folders.</p>';
      const junk = data.junk || {};
      $("disk-junk").innerHTML = [
        ["Construction videos", junk.construction_videos],
        ["Demo logs", junk.logs],
        ["Demo output", junk.output],
      ]
        .map(
          ([label, row]) =>
            `<div class="row"><span>${esc(label)}${row && row.count != null ? ` (${row.count})` : ""}</span><strong>${esc((row && row.label) || "0 B")}</strong></div>`
        )
        .join("");
      const dmax = (data.demos && data.demos[0] && data.demos[0].bytes) || 0;
      $("disk-demos").innerHTML =
        (data.demos || [])
          .map((r) => `<div class="row"><span>${esc(r.slug)}</span>${bar(r.bytes, dmax)}<strong>${esc(r.label)}</strong></div>`)
          .join("") || '<p class="empty">No demos.</p>';
      $("disk-files").innerHTML =
        (data.largest_files || []).map((r) => fileRow(r, { del: true })).join("") || '<p class="empty">No files.</p>';
    } catch (err) {
      $("disk-total").textContent = "Scan failed";
    }
  }

  $("disk-refresh").addEventListener("click", () => loadDisk(true));
  $("disk-videos").addEventListener("click", async () => {
    if (!confirm("Delete every documents/construction-replay.mp4 under Clients/Demos? They can be re-created from this hub or the demo Info tab.")) return;
    const resp = await fetch("/api/disk/delete-videos", { method: "POST" });
    const data = await resp.json().catch(() => ({}));
    alert(data.ok ? `Removed ${data.removed} files (${data.freed_label}).` : data.error || "Delete failed");
    loadDisk(true);
  });
  $("disk-files").addEventListener("click", async (ev) => {
    const btn = ev.target.closest("button[data-del]");
    if (!btn) return;
    const path = btn.dataset.del;
    if (!confirm(`Delete ${path}?`)) return;
    const resp = await fetch("/api/disk/delete", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ path }),
    });
    const data = await resp.json().catch(() => ({}));
    if (!data.ok) alert(data.error || "Delete failed");
    loadDisk(true);
  });

  loadDemos();
})();
