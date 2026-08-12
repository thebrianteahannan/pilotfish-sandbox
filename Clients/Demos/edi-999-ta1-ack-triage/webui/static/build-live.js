/**
 * Live build theater for Sandbox demos.
 *
 * While build-status.active: banner + activity + auto-refresh Routes.
 * Always: Experience tab stays available; Replay lives on Routes.
 * When complete: Demo tab is home — construction chrome hides unless replaying.
 */
(function () {
  const POLL_ACTIVE_MS = 2500;
  const POLL_IDLE_MS = 15000;
  let lastSig = "";
  let lastFrameKey = "";
  let timer = null;
  let banner = null;
  let replayPlaying = false;
  let replayTimer = null;
  let replayAvailable = false;
  let lastStatus = { active: false };

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
        : "Waiting for first route.v2.xml…";
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
    const el = ensureActivity();
    const statusEl = document.getElementById("routes-status");
    const active = !!(status && status.active);
    const msg = (status && (status.message || status.current_route)) || "";
    const list = routes || [];
    const modules =
      status && status.modules_visible != null ? Number(status.modules_visible) : null;

    if (statusEl) {
      if (active && msg) {
        statusEl.textContent = msg;
        statusEl.classList.add("is-building");
      } else if (!list.length) {
        statusEl.textContent = "No route.v2.xml yet";
        statusEl.classList.remove("is-building");
      } else {
        statusEl.textContent = `${list.length} route(s)`;
        statusEl.classList.remove("is-building");
      }
    }

    if (!el) return;
    if (!active) {
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
    frame.dataset.empty = "0";
    frame.style.height = "";
    frame.style.minHeight = "";
    frame.src = src;
    lastFrameKey = frameKey || src;
  }

  function applyRoutes(routes, status, forceReload) {
    if (replayPlaying) return;
    const select = document.getElementById("route-select");
    const frame = document.getElementById("route-viewer-frame");
    const list = routes || [];

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
    if (routes) routes.click();
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
    setReplayUi(true);
    const bannerEl = ensureBanner();
    bannerEl.hidden = false;
    bannerEl.classList.add("is-active");
    bannerEl.querySelector(".pf-build-phase").textContent = "Replay";
    bannerEl.querySelector(".pf-build-routes").textContent = `${steps.length} recorded steps`;

    const pause = Number(data.default_pause_ms) || 3500;
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
      await waitForFrameReady(8000);
      if (!replayPlaying) break;
      const stepPause = step.focus_label ? Math.max(pause, 4500) : pause;
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

  async function tick() {
    if (replayPlaying) {
      timer = setTimeout(tick, POLL_IDLE_MS);
      return;
    }

    let status = null;
    try {
      const res = await fetch("/api/build-status", { cache: "no-store" });
      status = await res.json();
    } catch (_) {
      status = { active: false };
    }

    const wasActive = !!(lastStatus && lastStatus.active);
    const nowActive = !!(status && status.active);
    lastStatus = status || { active: false };
    document.body.classList.toggle("pf-build-active", nowActive);
    renderBanner(status);

    // When a live build starts, surface Routes automatically once.
    if (!wasActive && nowActive) openRoutesTab();

    let routesPayload = null;
    try {
      const res = await fetch("/api/v2/routes", { cache: "no-store" });
      routesPayload = await res.json();
    } catch (_) {
      routesPayload = { routes: [] };
    }
    const routes = routesPayload.routes || [];
    const sig = routeSignature(routes);
    const changed = sig !== lastSig;
    if (changed || nowActive) {
      lastSig = sig;
      applyRoutes(routes, status, changed);
    } else {
      renderActivity(status, routes);
    }

    await refreshReplayAvailability();

    const ms = nowActive ? POLL_ACTIVE_MS : POLL_IDLE_MS;
    timer = setTimeout(tick, ms);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      ensureBanner();
      ensureActivity();
      ensureReplayControls();
      tick();
    });
  } else {
    ensureBanner();
    ensureActivity();
    ensureReplayControls();
    tick();
  }
})();
