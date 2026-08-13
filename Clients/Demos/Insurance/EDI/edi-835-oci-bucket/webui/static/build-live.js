/** Live build theater: banner + activity + Routes poll. Construction board is build-stage.js. */
(function () {
  const POLL_ACTIVE_MS = 2500;
  const POLL_IDLE_MS = 4000;
  let lastSig = "";
  let lastFrameKey = "";
  let timer = null;
  let banner = null;
  let replayPlaying = false;
  let replayTimer = null;
  let replayAvailable = false;
  let lastStatus = { active: false };
  let lastRoutes = [];
  let inactiveStreak = 0;

  // Prefer documents/construction-replay.mp4 (Info tab) over in-browser step replay.
  const SHOW_REPLAY_CONTROLS = false;

  function building() {
    return !!(lastStatus && lastStatus.active) || replayPlaying;
  }

  function ensureBanner() {
    if (banner) return banner;
    banner = document.createElement("div");
    banner.id = "pf-build-banner";
    banner.className = "pf-build-banner";
    banner.hidden = true;
    banner.innerHTML =
      '<span class="pf-build-dot" aria-hidden="true"></span>' +
      '<div class="pf-build-copy">' +
      '<strong class="pf-build-phase">Building</strong>' +
      '<span class="pf-build-msg"></span>' +
      "</div>" +
      '<span class="pf-build-routes"></span>';
    document.body.prepend(banner);
    return banner;
  }

  function ensureActivity() {
    let el = document.getElementById("pf-routes-activity");
    if (el) return el;
    const panel = document.querySelector(".routes-panel") || document.getElementById("tab-routes");
    if (!panel) return null;
    el = document.createElement("div");
    el.id = "pf-routes-activity";
    el.className = "pf-routes-activity";
    el.hidden = true;
    el.setAttribute("role", "status");
    el.setAttribute("aria-live", "polite");
    el.innerHTML =
      '<span class="pf-routes-activity-dot" aria-hidden="true"></span>' +
      '<div class="pf-routes-activity-copy">' +
      '<span class="pf-routes-activity-label">Currently</span>' +
      '<span class="pf-routes-activity-msg"></span>' +
      "</div>" +
      '<span class="pf-routes-activity-meta"></span>';
    const row = panel.querySelector(".row-head");
    if (row && row.parentNode) row.insertAdjacentElement("afterend", el);
    else panel.prepend(el);
    return el;
  }

  function ensureReplayControls() {
    if (!SHOW_REPLAY_CONTROLS) {
      const existing = document.getElementById("pf-replay-bar");
      if (existing) existing.hidden = true;
      return null;
    }
    let bar = document.getElementById("pf-replay-bar");
    if (bar) return bar;
    const panel = document.querySelector(".routes-panel") || document.getElementById("tab-routes");
    if (!panel) return null;
    bar = document.createElement("div");
    bar.id = "pf-replay-bar";
    bar.className = "pf-replay-bar";
    bar.innerHTML =
      '<button type="button" class="pf-replay-btn" id="pf-replay-btn" disabled>Replay construction</button>' +
      '<button type="button" class="pf-replay-stop" id="pf-replay-stop" hidden>Stop</button>' +
      '<span class="pf-replay-hint" id="pf-replay-hint">Missed the live build? Replay recorded steps.</span>';
    const activity = document.getElementById("pf-routes-activity");
    if (activity && activity.parentNode) activity.insertAdjacentElement("afterend", bar);
    else {
      const row = panel.querySelector(".row-head");
      if (row) row.insertAdjacentElement("afterend", bar);
      else panel.prepend(bar);
    }
    bar.querySelector("#pf-replay-btn").addEventListener("click", () => startReplay());
    bar.querySelector("#pf-replay-stop").addEventListener("click", () => stopReplay(true));
    return bar;
  }

  function setReplayUi(playing) {
    const btn = document.getElementById("pf-replay-btn");
    const stop = document.getElementById("pf-replay-stop");
    const hint = document.getElementById("pf-replay-hint");
    if (btn) {
      btn.disabled = playing || !replayAvailable;
      btn.textContent = playing ? "Replaying…" : "Replay construction";
    }
    if (stop) stop.hidden = !playing;
    if (hint) {
      hint.textContent = playing
        ? "Playing recorded construction steps…"
        : replayAvailable
          ? "Missed the live build? Replay recorded steps."
          : "No replay recorded yet — publish steps with tools/record_module_replay.py";
    }
  }

  function renderBanner(status) {
    const el = ensureBanner();
    const show = !!(status && status.active) || replayPlaying;
    el.hidden = !show;
    el.classList.toggle("is-active", show);
    if (replayPlaying) return;
    if (status && status.active) {
      const phase = status.phase || "building";
      const msg = status.message || status.current_route || "Interface under construction…";
      const ready = Array.isArray(status.routes_ready) ? status.routes_ready : [];
      el.querySelector(".pf-build-phase").textContent = String(phase).replace(/_/g, " ");
      el.querySelector(".pf-build-msg").textContent = msg;
      el.querySelector(".pf-build-routes").textContent = ready.length
        ? `Routes ready: ${ready.join(", ")}`
        : "";
    }
  }

  function showActivityMessage(msg, meta, { label } = {}) {
    const el = ensureActivity();
    const statusEl = document.getElementById("routes-status");
    if (statusEl && msg) {
      statusEl.textContent = msg;
      statusEl.classList.add("is-building");
    }
    if (!el) return;
    el.hidden = false;
    el.classList.add("is-active");
    const labelEl = el.querySelector(".pf-routes-activity-label");
    const msgEl = el.querySelector(".pf-routes-activity-msg");
    const metaEl = el.querySelector(".pf-routes-activity-meta");
    if (labelEl) labelEl.textContent = label || "Currently";
    if (msgEl) msgEl.textContent = msg || "";
    if (metaEl) metaEl.textContent = meta || "";
  }

  function renderActivity(status, routes) {
    if (replayPlaying) return;
    if (status && status.active && window.pfBuildStage) {
      const bar = document.getElementById("pf-routes-activity");
      if (bar) {
        bar.hidden = true;
        bar.classList.remove("is-active");
      }
      return;
    }
    const el = ensureActivity();
    const statusEl = document.getElementById("routes-status");
    const active = !!(status && status.active);
    const msg = (status && (status.message || status.current_route)) || "";
    const list = routes || [];
    const modules =
      status && status.modules_visible != null ? Number(status.modules_visible) : null;

    const preview = /(?:^|[?&])buildStage=preview(?:&|$)/.test(location.search);
    if (statusEl && !preview && !(active && window.pfBuildStage)) {
      if (active && !list.length) {
        statusEl.textContent = "Live construction";
        statusEl.classList.add("is-building");
      } else if (active && msg) {
        statusEl.textContent = msg;
        statusEl.classList.add("is-building");
      } else if (!list.length) {
        statusEl.textContent = "";
        statusEl.classList.remove("is-building");
      } else {
        statusEl.textContent = `${list.length} route(s)`;
        statusEl.classList.remove("is-building");
      }
    }

    if (!el) return;
    if (!active || !list.length) {
      el.hidden = true;
      el.classList.remove("is-active");
      return;
    }
    // Prefer diagram-centric copy: route.v2.xml is served by the Web UI, not EIP.
    const displayMsg =
      msg && /bringing up|eip|sql|sftp|compose/i.test(msg) && list.length
        ? `Routes visible (${list.length}) — runtime stack can start in parallel`
        : msg || "Building interface…";
    showActivityMessage(
      displayMsg,
      (() => {
        const bits = [];
        if (status.current_route) bits.push(status.current_route);
        if (modules != null && !Number.isNaN(modules)) bits.push(`${modules} module(s) in diagram`);
        else if (list.length) bits.push(`${list.length} route(s) visible`);
        return bits.join(" · ");
      })()
    );
  }

  function routeSignature(routes) {
    return (routes || [])
      .map((r) => `${r.id}:${r.mtime || r.name || ""}`)
      .sort()
      .join("|");
  }

  function pickRouteId(routes, preferred) {
    if (!routes || !routes.length) return "";
    if (preferred && routes.some((r) => r.id === preferred)) return preferred;
    if (building()) {
      const byMtime = [...routes].sort((a, b) => Number(b.mtime || 0) - Number(a.mtime || 0));
      return byMtime[0].id;
    }
    return routes[0].id;
  }

  function loadFrame(src, frameKey) {
    const frame = document.getElementById("route-viewer-frame");
    if (!frame) return;
    const key = frameKey || src;
    if (lastFrameKey === key && (frame.getAttribute("src") || "") === src) return;
    frame.dataset.empty = "0";
    frame.style.height = "";
    frame.style.minHeight = "";
    frame.src = src;
    lastFrameKey = key;
  }

  /** User picked a route in the dropdown — load it immediately (don't wait for poll). */
  function onRouteSelectChange() {
    if (replayPlaying) return;
    const select = document.getElementById("route-select");
    if (!select || !select.value) return;
    const nextId = select.value;
    const meta = lastRoutes.find((r) => r.id === nextId) || {};
    const mtime = meta.mtime || Date.now();
    const frameKey = `${nextId}@${mtime}`;
    const want =
      `/static/route-viewer/index.html?route=${encodeURIComponent(nextId)}` +
      `&mode=docs&layout=pipeline&config=changed&v=${encodeURIComponent(String(mtime))}`;
    loadFrame(want, frameKey);
  }

  function bindRouteSelect() {
    const select = document.getElementById("route-select");
    if (!select || select.dataset.pfBound === "1") return;
    select.dataset.pfBound = "1";
    select.addEventListener("change", onRouteSelectChange);
  }

  function applyRoutes(routes, status, forceReload) {
    if (replayPlaying) return;
    const select = document.getElementById("route-select");
    const frame = document.getElementById("route-viewer-frame");
    const list = routes || [];
    lastRoutes = list;

    renderActivity(status, list);

    if (!select || !frame) return;

    const prev = select.value;
    const html = list.map((r) => `<option value="${r.id}">${r.name || r.id}</option>`).join("");
    if (select.innerHTML !== html) {
      select.innerHTML = html || '<option value="">(none)</option>';
    }

    if (!list.length) {
      if (frame.dataset.empty !== "1") {
        frame.removeAttribute("src");
        frame.dataset.empty = "1";
        lastFrameKey = "";
      }
      return;
    }

    const preferred =
      building()
        ? (status && status.current_route) ||
          (Array.isArray(status && status.routes_ready) && status.routes_ready.slice(-1)[0]) ||
          prev
        : prev || list[0].id;
    const nextId = pickRouteId(list, preferred);
    if (select.value !== nextId) select.value = nextId;

    const meta = list.find((r) => r.id === nextId) || {};
    const mtime = meta.mtime || 0;
    const frameKey = `${nextId}@${mtime}`;
    const want =
      `/static/route-viewer/index.html?route=${encodeURIComponent(nextId)}` +
      `&mode=docs&layout=pipeline&config=changed&v=${encodeURIComponent(String(mtime))}`;

    if (forceReload || frame.dataset.empty === "1" || frameKey !== lastFrameKey) {
      loadFrame(want, frameKey);
    }
  }

  async function refreshReplayAvailability() {
    ensureReplayControls();
    try {
      const res = await fetch("/api/build-replay", { cache: "no-store" });
      const data = await res.json();
      replayAvailable = !!(data && data.available && (data.count || 0) > 0);
    } catch (_) {
      replayAvailable = false;
    }
    if (!replayPlaying) setReplayUi(false);
  }

  function sleep(ms) {
    return new Promise((resolve) => {
      replayTimer = setTimeout(resolve, ms);
    });
  }

  function openRoutesTab() {
    const routes = document.querySelector('.main-tab[data-main-tab="routes"]');
    if (!routes) return;
    if (routes.classList.contains("active") || routes.getAttribute("aria-selected") === "true") return;
    routes.click();
  }

  /** Wait until the route-viewer iframe finishes rendering (data-ready=1). */
  function waitForFrameReady(timeoutMs) {
    return new Promise((resolve) => {
      const frame = document.getElementById("route-viewer-frame");
      if (!frame) {
        resolve(false);
        return;
      }
      const started = Date.now();
      const poll = setInterval(() => {
        if (!replayPlaying) {
          clearInterval(poll);
          resolve(false);
          return;
        }
        try {
          const doc = frame.contentDocument;
          if (doc && doc.documentElement.getAttribute("data-ready") === "1") {
            clearInterval(poll);
            resolve(true);
            return;
          }
        } catch (_) {
          /* ignore */
        }
        if (Date.now() - started > timeoutMs) {
          clearInterval(poll);
          resolve(false);
        }
      }, 120);
    });
  }

  async function startReplay() {
    if (replayPlaying) return;
    openRoutesTab();
    let data;
    try {
      const res = await fetch("/api/build-replay", { cache: "no-store" });
      data = await res.json();
    } catch (err) {
      alert("Could not load build replay.");
      return;
    }
    const steps = (data && data.steps) || [];
    if (!steps.length) {
      alert("No construction replay recorded yet.");
      return;
    }

    replayPlaying = true;
    if (window.pfBuildStage) window.pfBuildStage.hide();
    setReplayUi(true);
    const bannerEl = ensureBanner();
    bannerEl.hidden = false;
    bannerEl.classList.add("is-active");
    bannerEl.querySelector(".pf-build-phase").textContent = "Replay";
    bannerEl.querySelector(".pf-build-routes").textContent = `${steps.length} recorded steps`;

    const pause = Number(data.default_pause_ms) || 4500;
    const select = document.getElementById("route-select");

    for (let i = 0; i < steps.length; i++) {
      if (!replayPlaying) break;
      const step = steps[i];
      const stepId = step.id || String(step.seq).padStart(4, "0");
      const msg = step.message || `Step ${stepId}`;
      bannerEl.querySelector(".pf-build-msg").textContent = msg;
      const explain = step.detail || msg;
      showActivityMessage(explain, `Replay ${i + 1}/${steps.length}` + (step.route_id ? ` · ${step.route_id}` : ""), {
        label: step.focus_label ? "Adding module" : "Replay",
      });
      if (select && step.route_id) {
        const opt = [...select.options].find((o) => o.value === step.route_id);
        if (opt) select.value = step.route_id;
      }
      // Diagrams come from /api/build-replay snapshots — EIP/SQL/SFTP do not need to be up.
      const src =
        `/static/route-viewer/index.html?replayStep=${encodeURIComponent(stepId)}` +
        (step.route_id ? `&route=${encodeURIComponent(step.route_id)}` : "") +
        (step.focus_label ? `&focusLabel=${encodeURIComponent(step.focus_label)}` : "") +
        (step.focus_node_id ? `&focusNode=${encodeURIComponent(step.focus_node_id)}` : "") +
        `&mode=docs&layout=pipeline&config=changed&v=${encodeURIComponent(stepId)}`;
      loadFrame(src, `replay:${stepId}`);
      await waitForFrameReady(6000);
      if (!replayPlaying) break;
      // Keep pace near readable speech; empty canvases don't linger.
      const detailLen = String(explain || "").length;
      const readBoost = Math.min(2500, Math.round(detailLen * 18));
      const stepPause = step.focus_label
        ? Math.max(pause, 4500) + readBoost
        : Math.max(Math.min(pause, 4000), 2800) + Math.round(readBoost * 0.35);
      await sleep(stepPause);
    }

    stopReplay(false);
  }

  function stopReplay(cancelled) {
    replayPlaying = false;
    if (replayTimer) {
      clearTimeout(replayTimer);
      replayTimer = null;
    }
    setReplayUi(false);
    lastSig = "";
    lastFrameKey = "";
    setTimeout(() => tick(), 400);
  }

  function syncStage(status, routes) {
    if (window.pfBuildStage) {
      window.pfBuildStage.sync(status, routes || [], { replay: replayPlaying });
    }
  }

  async function tick() {
    if (window.__pfTheaterRecording || replayPlaying) {
      if (window.__pfTheaterRecording && window.pfBuildStage) window.pfBuildStage.hide();
      timer = setTimeout(tick, POLL_IDLE_MS);
      return;
    }

    let status = lastStatus;
    try {
      const res = await fetch("/api/build-status", { cache: "no-store" });
      if (res.ok) {
        const data = await res.json();
        if (data && typeof data === "object" && data.ok !== false) {
          const idleDefault = /treating build as idle/i.test(String(data.message || ""));
          if (!(idleDefault && lastStatus && lastStatus.active)) status = data;
        }
      }
    } catch (_) {
      /* keep last good status — a failed poll must not hide the board */
    }

    const wasActive = !!(lastStatus && lastStatus.active);
    const reportedActive = !!(status && status.active);
    if (reportedActive) inactiveStreak = 0;
    else inactiveStreak += 1;
    const nowActive = reportedActive || (wasActive && inactiveStreak < 2);
    if (!reportedActive && nowActive) status = lastStatus;
    lastStatus = status || lastStatus || { active: false };
    document.body.classList.toggle("pf-build-active", nowActive);
    renderBanner(nowActive ? status : { active: false });

    // When a live build starts, surface Routes automatically once.
    if (!wasActive && nowActive) openRoutesTab();

    let routes = lastRoutes;
    try {
      const res = await fetch("/api/v2/routes", { cache: "no-store" });
      if (res.ok) {
        const routesPayload = await res.json();
        if (Array.isArray(routesPayload.routes) && (routesPayload.routes.length || !lastRoutes.length)) {
          routes = routesPayload.routes;
        }
      }
    } catch (_) {
      /* keep last good routes */
    }
    const sig = routeSignature(routes);
    const changed = sig !== lastSig;
    if (changed) {
      lastSig = sig;
      applyRoutes(routes, status, true);
    } else if (!nowActive) {
      renderActivity(status, routes);
    }
    syncStage(nowActive ? status : { ...status, active: false }, routes);

    await refreshReplayAvailability();

    const ms = nowActive ? POLL_ACTIVE_MS : POLL_IDLE_MS;
    timer = setTimeout(tick, ms);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      ensureBanner();
      ensureActivity();
      ensureReplayControls();
      bindRouteSelect();
      tick();
    });
  } else {
    ensureBanner();
    ensureActivity();
    ensureReplayControls();
    bindRouteSelect();
    tick();
  }
})();
