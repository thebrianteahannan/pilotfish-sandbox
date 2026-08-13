/**
 * Construction board shown on Routes while the diagram does not exist yet.
 * Fills the empty iframe with pipeline, phase checklist, and current work.
 */
(function () {
  const STORY = [
    {
      id: "scaffold",
      ids: ["scaffold", "webui_early"],
      label: "Web UI online",
      hint: "This page stays up so you can watch the rest of the build.",
    },
    {
      id: "design",
      ids: ["design", "design_scaffold"],
      label: "Choose the modules",
      hint: "Listener, processors, and the destination transport.",
    },
    {
      id: "routes",
      ids: ["routes"],
      label: "Wire the route",
      hint: "Publish the listener, router, and transport into the diagram.",
    },
    {
      id: "stack",
      ids: ["stack", "live_stack", "runtime", "compose", "eip"],
      label: "Start the live stack",
      hint: "SQL Server, eiPlatform, and the first poll. This is the long wait — not a freeze.",
    },
    {
      id: "webui",
      ids: ["webui", "docs", "webui_docs"],
      label: "Demo + docs",
      hint: "Inject screen, Timing tab, and PDFs.",
    },
    {
      id: "tests",
      ids: ["tests", "construction_video"],
      label: "Prove it works",
      hint: "Automated tests after the live stack is up.",
    },
  ];

  const FALLBACK_NOW = {
    scaffold: "The Web UI is up. Next we design the route and publish modules into the diagram.",
    design: "Selecting the listener and destination, then wiring processors between them.",
    routes: "Publishing the route — the diagram fills in as each module lands.",
    stack: "Starting the live stack: database, eiPlatform, then the first poll.",
    webui: "Finishing the Demo tab, Timing, and documentation.",
    docs: "Writing the docs and route diagrams.",
    tests: "Running automated tests against the live stack.",
    construction_video: "Recording the narrated construction video.",
    complete: "Build complete.",
  };

  let root = null;
  let clockTimer = null;
  let startedAt = null;
  let lastPaint = "";
  let everHadRoutes = false;
  let stackSeenUp = false;
  let lastStackParts = [];
  let lastHealthAt = 0;
  let lastHealth = null;
  let syncSeq = 0;

  function esc(s) {
    return String(s || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function demoTitle() {
    const brand = document.querySelector(".brand");
    const raw = brand ? brand.textContent : document.title;
    return String(raw || "this interface")
      .replace(/^PilotFish\s*[·•:\-]\s*/i, "")
      .replace(/\s+—\s+.*$/, "")
      .trim();
  }

  function pipelineNodes() {
    const title = demoTitle();
    const parts = title.split(/\s+to\s+/i);
    if (parts.length === 2 && parts[0] && parts[1]) {
      return [
        { k: "in", role: "Listener", name: parts[0].trim() },
        { k: "mid", role: "Route", name: "Processors" },
        { k: "out", role: "Transport", name: parts[1].trim() },
      ];
    }
    return [
      { k: "in", role: "Source", name: "Listener" },
      { k: "mid", role: "Transform", name: "Processors" },
      { k: "out", role: "Destination", name: "Transport" },
    ];
  }

  function phaseKey(status) {
    return String((status && status.phase) || "scaffold").toLowerCase();
  }

  function stackParts(health) {
    if (!health || typeof health !== "object") return [];
    const parts = [];
    if (Object.prototype.hasOwnProperty.call(health, "sql")) {
      parts.push({
        key: "sql",
        k: "in",
        role: "Database",
        name: "SQL Server",
        ok: !!health.sql,
        doing: "Starting SQL Server and waiting for logins. This often takes 30–60 seconds.",
        done: "SQL Server is accepting connections.",
      });
    }
    parts.push({
      key: "eip",
      k: "mid",
      role: "Runtime",
      name: "eiPlatform",
      ok: !!health.eip,
      doing: health && health.sql === false
        ? "eiPlatform waits until SQL Server is healthy, then Tomcat starts (about a minute)."
        : "Starting eiPlatform (Tomcat). This can take a minute.",
      done: "eiPlatform is up.",
    });
    if (Object.prototype.hasOwnProperty.call(health, "xml")) {
      parts.push({
        key: "xml",
        k: "out",
        role: "Proof",
        name: "First poll",
        ok: !!health.xml,
        doing: "Route is loaded. Waiting for the first database poll to write the export file.",
        done: "First export file is on disk.",
      });
    } else if (Object.prototype.hasOwnProperty.call(health, "rabbitmq")) {
      parts.push({
        key: "rabbitmq",
        k: "out",
        role: "Broker",
        name: "RabbitMQ",
        ok: !!health.rabbitmq,
        doing: "Waiting for RabbitMQ to become healthy.",
        done: "RabbitMQ is up.",
      });
    }
    return parts;
  }

  function stackPending(parts) {
    return (parts || []).find((p) => !p.ok) || null;
  }

  function stackUp(parts) {
    return !!(parts && parts.length && parts.every((p) => p.ok));
  }

  function effectivePhase(status, extras) {
    const phase = phaseKey(status);
    if (phase === "complete") return phase;
    const published = Array.isArray(status && status.routes_ready) && status.routes_ready.length > 0;
    const parts = (extras && extras.stackParts) || [];
    if (stackUp(parts)) stackSeenUp = true;
    if (published && parts.length && !stackUp(parts) && !stackSeenUp) return "stack";
    if (published && stackUp(parts) && phase === "routes") return "stack";
    return phase;
  }

  function storyIndex(phase) {
    const i = STORY.findIndex((s) => s.ids.includes(phase));
    return i < 0 ? 0 : i;
  }

  function itemState(item, status, extras) {
    const phase = effectivePhase(status, extras);
    if (phase === "complete") return "done";
    const cur = storyIndex(phase);
    const idx = STORY.indexOf(item);
    const timingPhases = (extras && extras.timingPhases) || [];
    if (idx < cur) return "done";
    if (idx === cur) {
      if (item.id === "stack" && stackUp((extras && extras.stackParts) || [])) return "done";
      return "now";
    }
    const match = timingPhases.find((p) => item.ids.includes(String(p.id || "")));
    if (match && match.ended_at) return "done";
    return "todo";
  }

  function itemHint(item, extras, state) {
    if (item.id !== "stack") return item.hint;
    const parts = (extras && extras.stackParts) || [];
    const pending = stackPending(parts);
    if (state === "now" && pending) return pending.doing;
    if (state === "done" && parts.length) {
      return parts.map((p) => p.name).join(", ") + " are up.";
    }
    return item.hint;
  }

  function humanNow(status, extras) {
    if (effectivePhase(status, extras) === "stack") {
      const pending = stackPending((extras && extras.stackParts) || []);
      if (pending) return pending.doing;
      return "Live stack is up.";
    }
    const msg = String((status && status.message) || "").trim();
    if (msg && !/waiting for first route/i.test(msg) && !/route\.v2\.xml/i.test(msg)) {
      return msg;
    }
    return FALLBACK_NOW[effectivePhase(status, extras)] || FALLBACK_NOW.scaffold;
  }

  function formatElapsed() {
    if (!startedAt) return "";
    const sec = Math.max(0, Math.floor((Date.now() - startedAt) / 1000));
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return m ? `${m}m ${String(s).padStart(2, "0")}s` : `${s}s`;
  }

  function setText(el, text) {
    if (!el) return;
    const next = text == null ? "" : String(text);
    if (el.textContent !== next) el.textContent = next;
  }

  function skeletonHtml() {
    const steps = STORY.map(
      (s) =>
        `<li class="pf-stage-step is-todo" data-step="${esc(s.id)}">` +
        `<span class="pf-stage-mark" aria-hidden="true"></span>` +
        `<div><strong>${esc(s.label)}</strong><p></p></div>` +
        `</li>`
    ).join("");
    return (
      `<div class="pf-stage-hero">` +
      `<p class="pf-stage-kicker">Live construction</p>` +
      `<h3 class="pf-stage-title"></h3>` +
      `<p class="pf-stage-now" aria-live="polite"></p>` +
      `<p class="pf-stage-elapsed"></p>` +
      `</div>` +
      `<div class="pf-stage-pipe">` +
      `<div class="pf-stage-node in"><span class="pf-stage-node-role"></span><strong></strong><span class="pf-stage-node-state"></span></div>` +
      `<div class="pf-stage-flow" aria-hidden="true"></div>` +
      `<div class="pf-stage-node mid"><span class="pf-stage-node-role"></span><strong></strong><span class="pf-stage-node-state"></span></div>` +
      `<div class="pf-stage-flow" aria-hidden="true"></div>` +
      `<div class="pf-stage-node out"><span class="pf-stage-node-role"></span><strong></strong><span class="pf-stage-node-state"></span></div>` +
      `</div>` +
      `<div class="pf-stage-grid is-single">` +
      `<ol class="pf-stage-steps">${steps}</ol>` +
      `<div class="pf-stage-feed" hidden><h4></h4><ul></ul></div>` +
      `</div>`
    );
  }

  function mountSkeleton(el) {
    if (el.dataset.ready === "1" && el.querySelector(".pf-stage-hero")) return;
    el.innerHTML = skeletonHtml();
    el.dataset.ready = "1";
  }

  function ensure() {
    if (root && document.body.contains(root)) {
      mountSkeleton(root);
      return root;
    }
    const frame = document.getElementById("route-viewer-frame");
    const panel =
      (frame && frame.parentNode) ||
      document.querySelector(".routes-panel") ||
      document.getElementById("tab-routes");
    if (!panel) return null;
    root = document.createElement("div");
    root.id = "pf-build-stage";
    root.className = "pf-build-stage";
    root.hidden = true;
    root.setAttribute("role", "status");
    mountSkeleton(root);
    if (frame) frame.insertAdjacentElement("beforebegin", root);
    else panel.appendChild(root);
    return root;
  }

  function setClock(on) {
    if (clockTimer) {
      clearInterval(clockTimer);
      clockTimer = null;
    }
    if (!on) return;
    clockTimer = setInterval(() => {
      const el = root && root.querySelector(".pf-stage-elapsed");
      if (el) el.textContent = formatElapsed() ? `Elapsed ${formatElapsed()}` : "";
    }, 1000);
  }

  function hide() {
    const el = ensure();
    const frame = document.getElementById("route-viewer-frame");
    if (el) {
      el.hidden = true;
      el.classList.remove("is-dock");
    }
    if (frame) frame.hidden = false;
    setClock(false);
  }

  function paint(status, extras) {
    const el = ensure();
    if (!el) return;
    extras = extras || {};
    const phase = effectivePhase(status, extras);
    const events = extras.events || [];
    const parts = extras.stackParts || [];
    const onStack = phase === "stack";
    const published = Array.isArray(status.routes_ready) && status.routes_ready.length > 0;
    const items = STORY.map((s) => ({ ...s, state: itemState(s, status, extras) }));
    const nowIdx = items.findIndex((s) => s.state === "now");
    const nodes = pipelineNodes().map((n, i) => {
      const allReady = published || stackSeenUp;
      const building = !allReady && nowIdx >= 0 && i === Math.min(nowIdx, 2);
      const ready = allReady || (nowIdx >= 0 && i < Math.min(nowIdx, 2));
      return {
        ...n,
        state: allReady || ready ? "Ready" : building ? "Building" : "Queued",
        lit: allReady || ready || building,
        pulse: building,
      };
    });
    const now = humanNow(status, extras);
    const elapsed = formatElapsed();
    const elapsedLine = elapsed ? `Elapsed ${elapsed}` : "";
    const log = [];
    const statusLog = Array.isArray(status.log) ? status.log : [];
    statusLog.slice(-6).forEach((row) => {
      const line = typeof row === "string" ? row : row.text || row.message;
      if (line) log.push(line);
    });
    events.slice(-4).forEach((ev) => {
      const line = ev.title || ev.summary;
      if (line && log.indexOf(line) < 0) log.push(line);
    });
    if (log.length > 6) log.splice(0, log.length - 6);
    const logLines = onStack
      ? parts.map((p) => `${p.name} — ${p.ok ? p.done : p.doing}`)
      : log;
    const nodeSig = nodes.map((n) => `${n.name}:${n.state}`).join("|");
    const sig = [phase, now, nowIdx, published ? "1" : "0", nodeSig, logLines.join("|")].join("~");
    if (sig === lastPaint) {
      setText(el.querySelector(".pf-stage-elapsed"), elapsedLine);
      return;
    }
    lastPaint = sig;
    mountSkeleton(el);
    setText(el.querySelector(".pf-stage-title"), `Assembling ${demoTitle()}`);
    setText(el.querySelector(".pf-stage-now"), now);
    setText(el.querySelector(".pf-stage-elapsed"), elapsedLine);
    const nodeEls = el.querySelectorAll(".pf-stage-pipe .pf-stage-node");
    nodes.forEach((n, i) => {
      const node = nodeEls[i];
      if (!node) return;
      node.className = `pf-stage-node ${n.k}${n.lit ? " is-lit" : ""}${n.pulse ? " is-now" : ""}`;
      setText(node.querySelector(".pf-stage-node-role"), n.role);
      setText(node.querySelector("strong"), n.name);
      setText(node.querySelector(".pf-stage-node-state"), n.state);
    });
    items.forEach((s) => {
      const li = el.querySelector(`.pf-stage-step[data-step="${s.id}"]`);
      if (!li) return;
      li.className = `pf-stage-step is-${s.state}`;
      setText(li.querySelector("p"), itemHint(s, extras, s.state));
    });
    const grid = el.querySelector(".pf-stage-grid");
    const feed = el.querySelector(".pf-stage-feed");
    const feedTitle = onStack ? "Live stack" : "Just happened";
    if (feed) {
      if (logLines.length) {
        feed.hidden = false;
        setText(feed.querySelector("h4"), feedTitle);
        const ul = feed.querySelector("ul");
        if (ul) {
          const next = logLines.map((line) => `<li>${esc(line)}</li>`).join("");
          if (ul.innerHTML !== next) ul.innerHTML = next;
        }
        if (grid) grid.classList.remove("is-single");
      } else {
        feed.hidden = true;
        if (grid) grid.classList.add("is-single");
      }
    }
  }

  async function extras(status) {
    const out = { timingPhases: [], events: [], health: lastHealth, stackParts: lastStackParts.slice() };
    const phase = phaseKey(status);
    const published = Array.isArray(status && status.routes_ready) && status.routes_ready.length > 0;
    const wantHealth = published || ["routes", "stack", "webui", "docs", "tests"].includes(phase);
    try {
      const res = await fetch("/api/build-timing", { cache: "no-store" });
      if (res.ok) {
        const data = await res.json();
        const timing = data.timing || data;
        if (timing && timing.started_at) startedAt = Date.parse(timing.started_at) || startedAt;
        if (Array.isArray(timing.phases)) out.timingPhases = timing.phases;
      }
    } catch (_) {
      /* optional */
    }
    const healthFresh = Date.now() - lastHealthAt < 8000 && lastHealth;
    if (wantHealth && !healthFresh) {
      try {
        const res = await fetch("/api/health", { cache: "no-store" });
        if (res.ok) {
          lastHealth = await res.json();
          lastHealthAt = Date.now();
          const parts = stackParts(lastHealth);
          if (parts.length) lastStackParts = parts;
        }
      } catch (_) {
        /* keep last good health */
      }
    }
    out.health = lastHealth;
    out.stackParts = lastStackParts.slice();
    try {
      const res = await fetch("/api/build-experience", { cache: "no-store" });
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data.events)) out.events = data.events;
      }
    } catch (_) {
      /* optional */
    }
    return out;
  }

  async function sync(status, routes, opts) {
    const seq = ++syncSeq;
    const el = ensure();
    if (!el) return;
    const recording = !!(opts && opts.replay) || !!window.__pfTheaterRecording;
    const empty = !(routes && routes.length);
    const active = !!(status && status.active);
    const show = !recording && active;
    const frame = document.getElementById("route-viewer-frame");
    if (!show) {
      hide();
      return;
    }
    if (!empty) everHadRoutes = true;
    const dock = everHadRoutes;
    el.hidden = false;
    el.classList.toggle("is-dock", dock);
    if (frame) {
      if (dock || frame.getAttribute("src") || frame.dataset.empty !== "1") {
        frame.hidden = false;
      } else {
        frame.hidden = true;
      }
    }
    if (!startedAt && status && status.updated_at) {
      startedAt = Date.parse(status.updated_at) || startedAt;
    }
    setClock(true);
    const extra = await extras(status || {});
    if (seq !== syncSeq) return;
    paint(status || {}, extra);
    const activity = document.getElementById("pf-routes-activity");
    if (activity) {
      activity.hidden = true;
      activity.classList.remove("is-active");
    }
    const statusEl = document.getElementById("routes-status");
    if (statusEl) {
      statusEl.textContent = humanNow(status, extra);
      statusEl.classList.add("is-building");
    }
  }

  window.pfBuildStage = { sync, hide };
})();
