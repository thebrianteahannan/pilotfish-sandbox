/**
 * Live build theater: banner + auto-refresh Routes as route.v2.xml files appear.
 * Expects optional #route-select, #route-viewer-frame, #routes-status in the page.
 * Polls /api/build-status and /api/v2/routes while build is active (or always at a slow tick).
 */
(function () {
  const POLL_ACTIVE_MS = 4000;
  const POLL_IDLE_MS = 15000;
  let lastSig = "";
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

  function routeSignature(routes) {
    return (routes || [])
      .map((r) => `${r.id}:${r.mtime || r.name || ""}`)
      .sort()
      .join("|");
  }

  function pickRouteId(routes, preferred) {
    if (!routes || !routes.length) return "";
    if (preferred && routes.some((r) => r.id === preferred)) return preferred;
    // Prefer newest listed last if API returns mtime; else last id
    const sorted = [...routes].sort((a, b) => String(a.id).localeCompare(String(b.id)));
    return sorted[sorted.length - 1].id;
  }

  function applyRoutes(routes, status) {
    const select = document.getElementById("route-select");
    const frame = document.getElementById("route-viewer-frame");
    const statusEl = document.getElementById("routes-status");
    const list = routes || [];

    if (statusEl) {
      if (!list.length) {
        statusEl.textContent = status && status.active
          ? "Building… no route.v2.xml yet"
          : "No route.v2.xml yet";
      } else {
        statusEl.textContent = `${list.length} route(s)` + (status && status.active ? " · live" : "");
      }
    }

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
      }
      return;
    }

    const preferred =
      (status && status.current_route) ||
      (Array.isArray(status && status.routes_ready) && status.routes_ready.slice(-1)[0]) ||
      prev;
    const nextId = pickRouteId(list, preferred);
    if (select.value !== nextId) select.value = nextId;

    const want = `/static/route-viewer/index.html?route=${encodeURIComponent(nextId)}&mode=docs&layout=pipeline&config=changed`;
    if (frame.dataset.empty === "1" || !frame.src || !frame.src.includes(`route=${encodeURIComponent(nextId)}`)) {
      frame.dataset.empty = "0";
      frame.style.height = "";
      frame.style.minHeight = "";
      frame.src = want;
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
    if (sig !== lastSig || (status && status.active)) {
      const changed = sig !== lastSig;
      lastSig = sig;
      if (changed || (status && status.active)) {
        applyRoutes(routes, status);
        if (typeof window.pfOnRoutesChanged === "function" && changed) {
          try {
            window.pfOnRoutesChanged(routes, status);
          } catch (_) {
            /* ignore */
          }
        }
      }
    }

    const ms = status && status.active ? POLL_ACTIVE_MS : POLL_IDLE_MS;
    timer = setTimeout(tick, ms);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      ensureBanner();
      tick();
    });
  } else {
    ensureBanner();
    tick();
  }
})();
