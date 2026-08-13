/**
 * Build Experience tab — narrated construction log with rationale + full replay.
 */
(function () {
  const root = () => document.getElementById("experience-root");
  let playing = false;
  let timer = null;

  function esc(s) {
    return String(s || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function kindLabel(kind) {
    const map = {
      phase: "Phase",
      decision: "Decision",
      route: "Route",
      sql: "SQL / data",
      test: "Test",
      docs: "Docs",
      ops: "Ops",
      note: "Note",
    };
    return map[kind] || kind || "Event";
  }

  function renderEvent(ev, index, total, { highlight } = {}) {
    const alts = (ev.alternatives || [])
      .map((a) => `<li>${esc(a)}</li>`)
      .join("");
    const links = (ev.links || [])
      .map(
        (l) =>
          `<a href="${esc(l.href)}" target="_blank" rel="noopener">${esc(l.label || l.href)}</a>`
      )
      .join(" · ");
    return (
      `<article class="pf-xp-event kind-${esc(ev.kind || "note")}${highlight ? " is-active" : ""}" data-event-id="${esc(ev.id)}">` +
      `<header class="pf-xp-event-head">` +
      `<span class="pf-xp-kind">${esc(kindLabel(ev.kind))}</span>` +
      `<span class="pf-xp-step">${index + 1}/${total}</span>` +
      `</header>` +
      `<h3 class="pf-xp-title">${esc(ev.title)}</h3>` +
      (ev.summary ? `<p class="pf-xp-summary">${esc(ev.summary)}</p>` : "") +
      (ev.rationale
        ? `<div class="pf-xp-rationale"><strong>Why this way</strong><p>${esc(ev.rationale)}</p></div>`
        : "") +
      (alts
        ? `<div class="pf-xp-alts"><strong>Instead of</strong><ul>${alts}</ul></div>`
        : "") +
      (ev.detail
        ? `<pre class="pf-xp-detail">${esc(ev.detail)}</pre>`
        : "") +
      (links ? `<div class="pf-xp-links">${links}</div>` : "") +
      (ev.at ? `<time class="pf-xp-time">${esc(ev.at)}</time>` : "") +
      `</article>`
    );
  }

  function showStatus(msg) {
    const el = document.getElementById("pf-xp-status");
    if (el) el.textContent = msg || "";
  }

  function switchToRoutes() {
    const btn = document.querySelector('.main-tab[data-main-tab="routes"]');
    if (btn) btn.click();
  }

  function loadReplayFrame(stepId, routeId, focusLabel, focusNodeId) {
    const frame = document.getElementById("route-viewer-frame");
    if (!frame || !stepId) return;
    const src =
      `/static/route-viewer/index.html?replayStep=${encodeURIComponent(stepId)}` +
      (routeId ? `&route=${encodeURIComponent(routeId)}` : "") +
      (focusLabel ? `&focusLabel=${encodeURIComponent(focusLabel)}` : "") +
      (focusNodeId ? `&focusNode=${encodeURIComponent(focusNodeId)}` : "") +
      `&mode=docs&layout=pipeline&config=changed&v=${encodeURIComponent(stepId)}`;
    frame.src = src;
  }

  async function fetchExperience() {
    const res = await fetch("/api/build-experience", { cache: "no-store" });
    return res.json();
  }

  async function refresh() {
    const mount = root();
    if (!mount) return;
    let data;
    try {
      data = await fetchExperience();
    } catch (_) {
      mount.innerHTML = `<p class="muted">Could not load build experience.</p>`;
      return;
    }
    const events = data.events || [];
    const list = document.getElementById("pf-xp-list");
    const empty = document.getElementById("pf-xp-empty");
    const btn = document.getElementById("pf-xp-replay");
    if (btn) btn.disabled = !events.length || playing;
    if (!events.length) {
      if (list) list.innerHTML = "";
      if (empty) empty.hidden = false;
      showStatus(data.message || "No experience events yet.");
      return;
    }
    if (empty) empty.hidden = true;
    if (list) {
      list.innerHTML = events.map((ev, i) => renderEvent(ev, i, events.length)).join("");
    }
    showStatus(`${events.length} narrated step(s) · updated ${data.updated_at || "—"}`);
  }

  function stopReplay() {
    playing = false;
    if (timer) {
      clearTimeout(timer);
      timer = null;
    }
    const btn = document.getElementById("pf-xp-replay");
    const stop = document.getElementById("pf-xp-stop");
    if (btn) {
      btn.disabled = false;
      btn.textContent = "Replay full experience";
    }
    if (stop) stop.hidden = true;
    showStatus("Experience replay stopped.");
    refresh();
  }

  async function startReplay() {
    if (playing) return;
    let data;
    try {
      data = await fetchExperience();
    } catch (_) {
      alert("Could not load experience.");
      return;
    }
    const events = data.events || [];
    if (!events.length) {
      alert("No experience events to replay.");
      return;
    }
    playing = true;
    const btn = document.getElementById("pf-xp-replay");
    const stop = document.getElementById("pf-xp-stop");
    if (btn) {
      btn.disabled = true;
      btn.textContent = "Replaying…";
    }
    if (stop) stop.hidden = false;

    const pause = Number(data.default_pause_ms) || 4000;
    const list = document.getElementById("pf-xp-list");
    const banner = document.getElementById("pf-build-banner");
    const activityMsg = document.querySelector(".pf-routes-activity-msg");
    const activityLabel = document.querySelector(".pf-routes-activity-label");
    const activityMeta = document.querySelector(".pf-routes-activity-meta");
    const activity = document.getElementById("pf-routes-activity");
    const statusEl = document.getElementById("routes-status");

    for (let i = 0; i < events.length; i++) {
      if (!playing) break;
      const ev = events[i];
      if (list) {
        list.innerHTML = events
          .map((e, idx) => renderEvent(e, idx, events.length, { highlight: idx === i }))
          .join("");
        const active = list.querySelector(".pf-xp-event.is-active");
        if (active) active.scrollIntoView({ behavior: "smooth", block: "nearest" });
      }
      showStatus(`Experience ${i + 1}/${events.length}: ${ev.title}`);

      if (banner) {
        banner.hidden = false;
        banner.classList.add("is-active");
        const phase = banner.querySelector(".pf-build-phase");
        const msg = banner.querySelector(".pf-build-msg");
        const routes = banner.querySelector(".pf-build-routes");
        if (phase) phase.textContent = kindLabel(ev.kind);
        if (msg) msg.textContent = ev.title;
        if (routes) routes.textContent = `${i + 1}/${events.length}`;
      }
      if (activity) {
        activity.hidden = false;
        activity.classList.add("is-active");
      }
      if (activityLabel) activityLabel.textContent = kindLabel(ev.kind);
      if (activityMsg) activityMsg.textContent = ev.summary || ev.title;
      if (activityMeta) {
        activityMeta.textContent = ev.rationale
          ? `Why: ${ev.rationale.slice(0, 120)}${ev.rationale.length > 120 ? "…" : ""}`
          : "";
      }
      if (statusEl) {
        statusEl.textContent = ev.title;
        statusEl.classList.add("is-building");
      }

      if (ev.replay_step) {
        switchToRoutes();
        loadReplayFrame(ev.replay_step, ev.route_id, ev.focus_label, ev.focus_node_id);
      }

      await new Promise((resolve) => {
        timer = setTimeout(resolve, pause);
      });
    }

    if (playing) {
      playing = false;
      if (btn) {
        btn.disabled = false;
        btn.textContent = "Replay full experience";
      }
      if (stop) stop.hidden = true;
      showStatus("Experience replay complete.");
      // leave user on Experience tab
      const xp = document.querySelector('.main-tab[data-main-tab="experience"]');
      if (xp) xp.click();
      refresh();
    }
  }

  function wire() {
    const btn = document.getElementById("pf-xp-replay");
    const stop = document.getElementById("pf-xp-stop");
    if (btn) btn.addEventListener("click", () => startReplay());
    if (stop) stop.addEventListener("click", () => stopReplay());
    refresh();
    setInterval(() => {
      if (!playing) refresh();
    }, 5000);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", wire);
  } else {
    wire();
  }
})();
