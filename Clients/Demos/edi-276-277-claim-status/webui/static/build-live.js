/**
 * Live build theater: banner + Routes activity line + auto-refresh diagrams
 * as route.v2.xml files appear or change (module-by-module construction).
 */
(function () {
  const POLL_ACTIVE_MS = 2500;
  const POLL_IDLE_MS = 15000;
  let lastSig = "";
  let lastFrameKey = "";
  let timer = null;
  let banner = null;

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

  /** Prominent “currently doing” strip under the Routes header. */
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
    if (row && row.parentNode) {
      row.insertAdjacentElement("afterend", el);
    } else {
      panel.prepend(el);
    }
    return el;
  }

  function renderBanner(status) {
    const el = ensureBanner();
    const active = !!(status && status.active);
    el.hidden = !active;
    el.classList.toggle("is-active", active);
    if (!active) return;
    const phase = status.phase || "building";
    const msg = status.message || status.current_route || "Interface under construction…";
    const ready = Array.isArray(status.routes_ready) ? status.routes_ready : [];
    el.querySelector(".pf-build-phase").textContent = String(phase).replace(/_/g, " ");
    el.querySelector(".pf-build-msg").textContent = msg;
    el.querySelector(".pf-build-routes").textContent = ready.length
      ? `Routes ready: ${ready.join(", ")}`
      : "Waiting for first route.v2.xml…";
  }

  function renderActivity(status, routes) {
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
    el.hidden = false;
    el.classList.add("is-active");
    const msgEl = el.querySelector(".pf-routes-activity-msg");
    const metaEl = el.querySelector(".pf-routes-activity-meta");
    if (msgEl) msgEl.textContent = msg || "Building interface…";
    if (metaEl) {
      const bits = [];
      if (status.current_route) bits.push(status.current_route);
      if (modules != null && !Number.isNaN(modules)) bits.push(`${modules} module(s) in diagram`);
      else if (list.length) bits.push(`${list.length} route(s) visible`);
      metaEl.textContent = bits.join(" · ");
    }
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
    const byMtime = [...routes].sort((a, b) => Number(b.mtime || 0) - Number(a.mtime || 0));
    return byMtime[0].id;
  }

  function applyRoutes(routes, status, forceReload) {
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
      (status && status.current_route) ||
      (Array.isArray(status && status.routes_ready) && status.routes_ready.slice(-1)[0]) ||
      prev;
    const nextId = pickRouteId(list, preferred);
    if (select.value !== nextId) select.value = nextId;

    const meta = list.find((r) => r.id === nextId) || {};
    const mtime = meta.mtime || 0;
    const frameKey = `${nextId}@${mtime}`;
    const want =
      `/static/route-viewer/index.html?route=${encodeURIComponent(nextId)}` +
      `&mode=docs&layout=pipeline&config=changed&v=${encodeURIComponent(String(mtime))}`;

    if (forceReload || frame.dataset.empty === "1" || frameKey !== lastFrameKey) {
      frame.dataset.empty = "0";
      frame.style.height = "";
      frame.style.minHeight = "";
      frame.src = want;
      lastFrameKey = frameKey;
    }
  }

  async function tick() {
    let status = null;
    try {
      const res = await fetch("/api/build-status", { cache: "no-store" });
      status = await res.json();
    } catch (_) {
      status = { active: false };
    }
    renderBanner(status);

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
    // Always refresh activity text while building (message changes without mtime).
    if (changed || (status && status.active)) {
      lastSig = sig;
      applyRoutes(routes, status, changed);
      if (typeof window.pfOnRoutesChanged === "function" && changed) {
        try {
          window.pfOnRoutesChanged(routes, status);
        } catch (_) {
          /* ignore */
        }
      }
    } else {
      renderActivity(status, routes);
    }

    const ms = status && status.active ? POLL_ACTIVE_MS : POLL_IDLE_MS;
    timer = setTimeout(tick, ms);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      ensureBanner();
      ensureActivity();
      tick();
    });
  } else {
    ensureBanner();
    ensureActivity();
    tick();
  }
})();
