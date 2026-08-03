/**
 * Renders route.v2.xml as an eiConsole-style node graph.
 * Styles follow RouteV2/route-node-editor.css (ported to web).
 */
(function () {
  const params = new URLSearchParams(window.location.search);
  const routeKey = (params.get("route") || "").trim();
  const BASE = routeKey
    ? `/api/v2/routes/${encodeURIComponent(routeKey)}`
    : ".";
  window.ROUTE_VIEWER_BASE = BASE;
  const XML_URL = `${BASE}/route.v2.xml`;
  const docsMode = params.get("mode") === "docs" || params.has("print");
  const layoutMode = (params.get("layout") || "pipeline").toLowerCase(); // pipeline | wrap | raw
  const colsParam = parseInt(params.get("cols") || "4", 10);
  const COLS = Number.isFinite(colsParam) && colsParam > 0 ? Math.min(8, colsParam) : 4;
  const PAD = docsMode ? 28 : 72;
  let configMode = (params.get("config") || "compact").toLowerCase(); // compact | changed | all
  if (!["compact", "changed", "all"].includes(configMode)) configMode = "compact";

  const KIND_LABEL = {
    listener: "Listener",
    processor: "Processor",
    transform: "Transform",
    routing: "Routing",
    transport: "Transport",
    "post-processor": "Post-Processor",
  };

  const state = {
    route: null,
    nodes: new Map(),
    modules: new Map(),
    connections: [],
    selectedId: null,
    scale: 0.55,
    panX: 0,
    panY: 0,
    useGeometricPorts: layoutMode !== "raw",
  };

  const el = {
    title: document.getElementById("route-title"),
    meta: document.getElementById("route-meta"),
    status: document.getElementById("status"),
    tree: document.getElementById("tree"),
    config: document.getElementById("config"),
    editor: document.getElementById("graph-editor"),
    world: document.getElementById("graph-world"),
    nodesLayer: document.getElementById("node-layer"),
    svg: document.getElementById("connection-layer"),
    minimap: document.getElementById("minimap-canvas"),
    locator: document.getElementById("minimap-locator"),
  };

  if (docsMode) document.body.classList.add("docs-mode");
  if (docsMode && params.get("bare") === "1") document.body.classList.add("docs-bare");

  function fallbackKind(label, inboundCount) {
    const t = (label || "").toLowerCase();
    if (/conditional\s*router|node\s*router|\brouter\b/.test(t)) return "routing";
    if (/listener|dir listener|directory listener/.test(t) || inboundCount === 0) return "listener";
    if (/doctype route|invalid creds|missing required/.test(t)) return "transport";
    return "processor";
  }

  function applyModuleMeta(node, mod) {
    if (!mod) return;
    node.kind = mod.kind || node.kind;
    node.kindTitle = mod.displayType || node.kindTitle;
    node.module = mod;
    if (mod.name) node.label = mod.name;
  }

  function parseRoute(xmlText) {
    const doc = new DOMParser().parseFromString(xmlText, "application/xml");
    if (doc.querySelector("parsererror")) {
      throw new Error("Failed to parse route.v2.xml");
    }
    const root = doc.documentElement;

    const inbound = new Map();
    root.querySelectorAll("Connections > Connection").forEach((c) => {
      const tid = c.getAttribute("targetNodeId");
      inbound.set(tid, (inbound.get(tid) || 0) + 1);
    });

    const nodes = [];
    root.querySelectorAll("Nodes > Node").forEach((n) => {
      const label = n.getAttribute("label") || "Untitled";
      const id = n.getAttribute("id");
      const kind = fallbackKind(label, inbound.get(id) || 0);
      nodes.push({
        id,
        moduleId: n.getAttribute("moduleId"),
        label,
        kind,
        kindTitle: KIND_LABEL[kind] || "Module",
        module: null,
        x: parseFloat(n.getAttribute("x")) || 0,
        y: parseFloat(n.getAttribute("y")) || 0,
        width: parseFloat(n.getAttribute("width")) || 192,
        height: parseFloat(n.getAttribute("height")) || 72,
      });
    });

    const connections = [];
    root.querySelectorAll("Connections > Connection").forEach((c) => {
      connections.push({
        id: c.getAttribute("id"),
        sourceNodeId: c.getAttribute("sourceNodeId"),
        targetNodeId: c.getAttribute("targetNodeId"),
        sourceConnector: c.getAttribute("sourceConnector") || "right-output",
        targetConnector: c.getAttribute("targetConnector") || "left-input",
        condition: c.getAttribute("condition") === "true",
      });
    });

    return {
      id: root.getAttribute("id"),
      name: root.getAttribute("name") || "Route",
      version: root.getAttribute("version") || "",
      nodes,
      connections,
    };
  }

  function sizeForLabel(label) {
    const text = String(label || "");
    const scale = docsMode ? 1.2 : 1;
    const width = Math.min(320, Math.max(230, 28 + text.length * 6.4)) * scale;
    const height = (text.length > 36 ? 92 : text.length > 22 ? 80 : 72) * scale;
    return { width, height };
  }

  function applyNodeSizes(route) {
    route.nodes.forEach((n) => {
      const mod = state.modules.get(n.moduleId) || n.module;
      if (window.RouteModuleConfig && window.RouteModuleConfig.estimateInlineSize) {
        const s = window.RouteModuleConfig.estimateInlineSize(mod, configMode, n.label);
        n.width = s.width * (docsMode && configMode === "compact" ? 1.2 : 1);
        n.height = s.height * (docsMode && configMode === "compact" ? 1.2 : 1);
      } else {
        const s = sizeForLabel(n.label);
        n.width = s.width;
        n.height = s.height;
      }
    });
  }

  function topologicalOrder(nodes, connections) {
    const ids = nodes.map((n) => n.id);
    const idSet = new Set(ids);
    const indeg = new Map(ids.map((id) => [id, 0]));
    const outs = new Map(ids.map((id) => [id, []]));
    connections.forEach((c) => {
      if (!idSet.has(c.sourceNodeId) || !idSet.has(c.targetNodeId)) return;
      indeg.set(c.targetNodeId, (indeg.get(c.targetNodeId) || 0) + 1);
      outs.get(c.sourceNodeId).push(c.targetNodeId);
    });
    const queue = ids.filter((id) => indeg.get(id) === 0);
    const order = [];
    while (queue.length) {
      const id = queue.shift();
      order.push(id);
      (outs.get(id) || []).forEach((t) => {
        indeg.set(t, indeg.get(t) - 1);
        if (indeg.get(t) === 0) queue.push(t);
      });
    }
    nodes.forEach((n) => {
      if (!order.includes(n.id)) order.push(n.id);
    });
    return order;
  }

  function layoutRole(node) {
    if (node.kind === "routing") return "router";
    if (node.kind === "listener") return "listener";
    if (node.kind === "transport") return "transport";
    return "stack";
  }

  function stackColumn(nodes, x, startY, gapY) {
    let y = startY;
    let maxW = 0;
    let contentH = 0;
    nodes.forEach((n, i) => {
      n.x = x;
      n.y = y;
      maxW = Math.max(maxW, n.width);
      y += n.height;
      contentH += n.height;
      if (i < nodes.length - 1) {
        y += gapY;
        contentH += gapY;
      }
    });
    return { maxW, height: contentH, bottom: y };
  }

  /**
   * eiConsole-style columns:
   * Listeners (left) → processors stacked under listener → Routers (middle)
   * → processors stacked before transport → Transports (right).
   */
  function autoLayoutPipeline(route, opts) {
    const keepSizes = opts && opts.keepSizes;
    const byId = new Map(route.nodes.map((n) => [n.id, n]));
    if (!keepSizes) {
      route.nodes.forEach((n) => {
        const s = sizeForLabel(n.label);
        n.width = s.width;
        n.height = s.height;
      });
    } else {
      applyNodeSizes(route);
    }

    const order = topologicalOrder(route.nodes, route.connections);
    const orderIndex = new Map(order.map((id, i) => [id, i]));

    const listeners = [];
    const routers = [];
    const transports = [];
    const stackables = [];
    order.forEach((id) => {
      const n = byId.get(id);
      const role = layoutRole(n);
      if (role === "listener") listeners.push(n);
      else if (role === "router") routers.push(n);
      else if (role === "transport") transports.push(n);
      else stackables.push(n);
    });

    const firstRouterIdx = routers.length
      ? Math.min(...routers.map((n) => orderIndex.get(n.id)))
      : Infinity;
    const leftStack = [];
    const rightStack = [];
    stackables.forEach((n) => {
      const idx = orderIndex.get(n.id);
      if (routers.length) {
        if (idx < firstRouterIdx) leftStack.push(n);
        else rightStack.push(n);
      } else {
        // No router: keep processors under the listener, transport on the right.
        leftStack.push(n);
      }
    });

    const gapX = docsMode ? 90 : 110;
    const gapY = docsMode ? 28 : 32;

    const leftNodes = listeners.concat(leftStack);
    const left = stackColumn(leftNodes, 0, 0, gapY);
    const leftW = Math.max(left.maxW, listeners.length || leftStack.length ? 210 : 0);

    let cursorX = leftW > 0 ? leftW + gapX : 0;

    let routerW = 0;
    let routerBottom = 0;
    let routerTop = 0;
    if (routers.length) {
      const mid = stackColumn(routers, cursorX, 0, gapY);
      routerW = Math.max(mid.maxW, 200);
      if (left.height > mid.height) {
        const offset = (left.height - mid.height) / 2;
        routers.forEach((n) => {
          n.y += offset;
        });
      }
      routerTop = Math.min(...routers.map((n) => n.y));
      routerBottom = Math.max(...routers.map((n) => n.y + n.height));
      cursorX += routerW + gapX;
    }

    let rightW = 0;
    let rightHeight = 0;
    if (rightStack.length) {
      const right = stackColumn(rightStack, cursorX, 0, gapY);
      rightW = Math.max(right.maxW, 200);
      rightHeight = right.height;
      cursorX += rightW + gapX;
    }

    if (transports.length) {
      const tH =
        transports.reduce((s, n) => s + n.height, 0) + gapY * Math.max(0, transports.length - 1);
      let transportStartY = 0;
      if (rightStack.length) {
        // Align beside the last pre-transport processor for a short horizontal exit.
        const last = rightStack[rightStack.length - 1];
        transportStartY = last.y + (last.height - tH) / 2;
      } else if (routers.length) {
        transportStartY = Math.max(0, (routerTop + routerBottom - tH) / 2);
      } else if (leftNodes.length) {
        transportStartY = Math.max(0, (left.height - tH) / 2);
      }
      stackColumn(transports, cursorX, transportStartY, gapY);
    }

    // Any leftovers (shouldn't happen) go under the tallest column.
    const placed = new Set(
      [...listeners, ...leftStack, ...routers, ...rightStack, ...transports].map((n) => n.id)
    );
    const orphans = route.nodes.filter((n) => !placed.has(n.id));
    if (orphans.length) {
      const placedNodes = route.nodes.filter((n) => placed.has(n.id));
      const b = placedNodes.length ? bounds(placedNodes) : { maxY: 0 };
      stackColumn(orphans, 0, (b.maxY || 0) + gapY + 40, gapY);
    }
  }

  /** Readable multi-row L→R wrap for long single-row V1 exports. */
  function autoLayoutWrap(route, cols, opts) {
    const keepSizes = opts && opts.keepSizes;
    const byId = new Map(route.nodes.map((n) => [n.id, n]));
    if (!keepSizes) {
      route.nodes.forEach((n) => {
        const s = sizeForLabel(n.label);
        n.width = s.width;
        n.height = s.height;
      });
    } else {
      applyNodeSizes(route);
    }
    const order = topologicalOrder(route.nodes, route.connections);
    const gapX = 64;
    const gapY = 100;
    const colW = Math.max(...route.nodes.map((n) => n.width)) + gapX;
    const rowH = Math.max(...route.nodes.map((n) => n.height)) + gapY;
    const rows = Math.ceil(order.length / cols) || 1;

    for (let row = 0; row < rows; row++) {
      const start = row * cols;
      const slice = order.slice(start, start + cols);
      slice.forEach((id, j) => {
        const n = byId.get(id);
        n.x = j * colW;
        n.y = row * rowH;
      });
    }
  }

  function bounds(nodes) {
    let minX = Infinity,
      minY = Infinity,
      maxX = -Infinity,
      maxY = -Infinity;
    nodes.forEach((n) => {
      minX = Math.min(minX, n.x);
      minY = Math.min(minY, n.y);
      maxX = Math.max(maxX, n.x + n.width);
      maxY = Math.max(maxY, n.y + n.height);
    });
    if (!nodes.length) return { minX: 0, minY: 0, maxX: 800, maxY: 600, w: 800, h: 600 };
    return {
      minX,
      minY,
      maxX,
      maxY,
      w: maxX - minX,
      h: maxY - minY,
    };
  }

  function routerOutputs(nodeId) {
    return state.connections
      .filter((c) => c.sourceNodeId === nodeId && c.sourceConnector.startsWith("router-output"))
      .map((c) => c.sourceConnector);
  }

  function edgePorts(source, target) {
    const sx = source.x + source.width / 2;
    const sy = source.y + source.height / 2;
    const tx = target.x + target.width / 2;
    const ty = target.y + target.height / 2;
    const dx = tx - sx;
    const dy = ty - sy;
    if (Math.abs(dx) >= Math.abs(dy)) {
      if (dx >= 0) {
        return {
          p1: { x: source.x + source.width, y: sy },
          p2: { x: target.x, y: ty },
        };
      }
      return {
        p1: { x: source.x, y: sy },
        p2: { x: target.x + target.width, y: ty },
      };
    }
    if (dy >= 0) {
      return {
        p1: { x: sx, y: source.y + source.height },
        p2: { x: tx, y: target.y },
      };
    }
    return {
      p1: { x: sx, y: source.y },
      p2: { x: tx, y: target.y + target.height },
    };
  }

  function portPoint(node, connector, isSource) {
    const outs = routerOutputs(node.id);
    if (connector.startsWith("router-output") && outs.length) {
      const idx = Math.max(0, outs.indexOf(connector));
      const count = outs.length;
      const y = node.y + (node.height * (idx + 1)) / (count + 1);
      return { x: node.x + node.width, y };
    }
    if (connector.startsWith("router-input") || connector === "left-input") {
      return { x: node.x, y: node.y + node.height / 2 };
    }
    return { x: node.x + node.width, y: node.y + node.height / 2 };
  }

  function bezierPath(x1, y1, x2, y2) {
    const dx = x2 - x1;
    const dy = y2 - y1;
    if (Math.abs(dy) > Math.abs(dx)) {
      const c = Math.max(48, Math.abs(dy) * 0.4);
      const s = dy >= 0 ? 1 : -1;
      return `M ${x1} ${y1} C ${x1} ${y1 + s * c}, ${x2} ${y2 - s * c}, ${x2} ${y2}`;
    }
    const c = Math.max(56, Math.abs(dx) * 0.42);
    const s = dx >= 0 ? 1 : -1;
    return `M ${x1} ${y1} C ${x1 + s * c} ${y1}, ${x2 - s * c} ${y2}, ${x2} ${y2}`;
  }

  function arrowHead(x2, y2, x1, y1) {
    const angle = Math.atan2(y2 - y1, x2 - x1);
    const s = 8;
    const a1 = angle + Math.PI * 0.82;
    const a2 = angle - Math.PI * 0.82;
    const xA = x2 + Math.cos(a1) * s;
    const yA = y2 + Math.sin(a1) * s;
    const xB = x2 + Math.cos(a2) * s;
    const yB = y2 + Math.sin(a2) * s;
    return `M ${x2} ${y2} L ${xA} ${yA} L ${xB} ${yB} Z`;
  }

  function selectNode(id) {
    state.selectedId = id;
    el.nodesLayer.querySelectorAll(".route-node").forEach((n) => {
      n.classList.toggle("selected", n.dataset.id === id);
    });
    el.tree.querySelectorAll(".tree-item").forEach((n) => {
      n.classList.toggle("selected", n.dataset.id === id);
    });
    renderConnections();
    renderConfig();
  }

  function renderTree() {
    el.tree.innerHTML = "";
    const byKind = {};
    state.route.nodes.forEach((n) => {
      (byKind[n.kind] || (byKind[n.kind] = [])).push(n);
    });
    const order = ["listener", "processor", "transform", "routing", "transport", "post-processor"];
    order.forEach((kind) => {
      const list = byKind[kind];
      if (!list) return;
      list
        .slice()
        .sort((a, b) => a.y - b.y || a.x - b.x)
        .forEach((n) => {
          const btn = document.createElement("button");
          btn.type = "button";
          btn.className = "tree-item";
          btn.dataset.id = n.id;
          btn.innerHTML = `<span class="tree-dot" style="background:${stripeColor(n.kind)}"></span><span class="label" title="${escapeAttr(n.label)}">${escapeHtml(n.label)}</span>`;
          btn.addEventListener("click", () => {
            selectNode(n.id);
            if (!docsMode) centerOn(n);
          });
          el.tree.appendChild(btn);
        });
    });
  }

  function stripeColor(kind) {
    return (
      {
        listener: "#2d8c9e",
        processor: "#4f75c8",
        transform: "#7a63c5",
        routing: "#b65a87",
        transport: "#2f8f64",
        "post-processor": "#7b8d37",
      }[kind] || "#7a8ca8"
    );
  }

  function renderConfig() {
    const n = state.nodes.get(state.selectedId);
    if (!n) {
      el.config.innerHTML = `<p class="config-empty">Select a node to view its module configuration from <code>modules/</code>.</p>`;
      return;
    }
    const mod = n.module || state.modules.get(n.moduleId);
    el.config.innerHTML = window.RouteModuleConfig.renderSummary(mod, state.route.name, n);
  }

  function renderNodes() {
    const b = bounds(state.route.nodes);
    const offsetX = -b.minX + PAD;
    const offsetY = -b.minY + PAD;
    state.offsetX = offsetX;
    state.offsetY = offsetY;

    const worldW = b.w + PAD * 2;
    const worldH = b.h + PAD * 2;
    el.world.style.width = `${worldW}px`;
    el.world.style.height = `${worldH}px`;
    el.nodesLayer.style.width = el.world.style.width;
    el.nodesLayer.style.height = el.world.style.height;
    el.svg.setAttribute("width", worldW);
    el.svg.setAttribute("height", worldH);
    el.svg.style.width = el.world.style.width;
    el.svg.style.height = el.world.style.height;

    el.nodesLayer.innerHTML = "";
    state.route.nodes.forEach((n) => {
      const node = document.createElement("div");
      const cfgClass =
        configMode === "compact" ? "" : ` config-${configMode}`;
      node.className = `route-node route-node-${n.kind}${cfgClass}`;
      node.dataset.id = n.id;
      node.style.left = `${n.x + offsetX}px`;
      node.style.top = `${n.y + offsetY}px`;
      node.style.width = `${n.width}px`;
      node.style.height = `${n.height}px`;
      const mod = n.module || state.modules.get(n.moduleId);
      const inline =
        window.RouteModuleConfig && window.RouteModuleConfig.renderInlineConfig
          ? window.RouteModuleConfig.renderInlineConfig(mod, configMode)
          : "";
      node.innerHTML = `
        <div class="route-node-content">
          <div class="route-node-kind">${escapeHtml(n.kindTitle)}</div>
          <div class="route-node-name" title="${escapeAttr(n.label)}">${escapeHtml(n.label)}</div>
          ${inline}
        </div>
        <div class="route-node-stripe"></div>
        <span class="route-connector-dot route-connector-input"></span>
        <span class="route-connector-dot route-connector-output"></span>
      `;
      if (!state.useGeometricPorts) {
        const outs = routerOutputs(n.id);
        if (outs.length > 1) {
          node.querySelector(".route-connector-output").remove();
          outs.forEach((conn, idx) => {
            const dot = document.createElement("span");
            dot.className = "route-connector-dot route-connector-router";
            dot.style.top = `${((idx + 1) / (outs.length + 1)) * 100}%`;
            node.appendChild(dot);
          });
        }
      }
      node.addEventListener("click", (e) => {
        e.stopPropagation();
        selectNode(n.id);
      });
      el.nodesLayer.appendChild(node);
    });

    if (docsMode) {
      el.editor.style.height = `${worldH}px`;
      el.editor.style.minHeight = `${worldH}px`;
      const container = document.querySelector(".route-graph-container");
      if (container) {
        container.style.height = `${worldH}px`;
        container.style.minHeight = `${worldH}px`;
      }
      document.documentElement.style.height = "auto";
      document.body.style.height = "auto";
      notifyParentSize(worldW, worldH);
    }
  }

  function notifyParentSize(worldW, worldH) {
    const top = document.querySelector(".topbar");
    const h = worldH + (top ? top.offsetHeight : 40) + 8;
    window.parent.postMessage(
      { type: "route-viewer-size", route: routeKey, width: worldW, height: h },
      "*"
    );
  }

  function renderConnections() {
    const ox = state.offsetX;
    const oy = state.offsetY;
    let html = "";
    state.connections.forEach((c) => {
      const s = state.nodes.get(c.sourceNodeId);
      const t = state.nodes.get(c.targetNodeId);
      if (!s || !t) return;
      let p1;
      let p2;
      if (state.useGeometricPorts) {
        const ports = edgePorts(s, t);
        p1 = ports.p1;
        p2 = ports.p2;
      } else {
        p1 = portPoint(s, c.sourceConnector, true);
        p2 = portPoint(t, c.targetConnector, false);
      }
      const x1 = p1.x + ox;
      const y1 = p1.y + oy;
      const x2 = p2.x + ox;
      const y2 = p2.y + oy;
      const sel = state.selectedId === s.id || state.selectedId === t.id ? " selected" : "";
      html += `<path class="default-connection${sel}" d="${bezierPath(x1, y1, x2, y2)}" />`;
      html += `<path class="default-connection-arrow${sel}" d="${arrowHead(x2, y2, x1, y1)}" />`;
    });
    el.svg.innerHTML = html;
  }

  function applyTransform() {
    if (docsMode) {
      el.world.style.transform = "none";
      return;
    }
    el.world.style.transform = `translate(${state.panX}px, ${state.panY}px) scale(${state.scale})`;
    drawMinimap();
  }

  function fitToView() {
    if (docsMode) {
      state.scale = 1;
      state.panX = 0;
      state.panY = 0;
      applyTransform();
      return;
    }
    const b = bounds(state.route.nodes);
    const vw = el.editor.clientWidth;
    const vh = el.editor.clientHeight;
    const scale = Math.min(vw / (b.w + PAD * 2), vh / (b.h + PAD * 2), 1) * 0.92;
    state.scale = Math.max(0.2, scale);
    state.panX = (vw - (b.w + PAD * 2) * state.scale) / 2;
    state.panY = (vh - (b.h + PAD * 2) * state.scale) / 2;
    applyTransform();
  }

  function centerOn(n) {
    const vw = el.editor.clientWidth;
    const vh = el.editor.clientHeight;
    const cx = (n.x + state.offsetX + n.width / 2) * state.scale;
    const cy = (n.y + state.offsetY + n.height / 2) * state.scale;
    state.panX = vw / 2 - cx;
    state.panY = vh / 2 - cy;
    applyTransform();
  }

  function drawMinimap() {
    if (docsMode) return;
    const canvas = el.minimap;
    const ctx = canvas.getContext("2d");
    const dpr = window.devicePixelRatio || 1;
    const cssW = canvas.clientWidth;
    const cssH = canvas.clientHeight;
    canvas.width = cssW * dpr;
    canvas.height = cssH * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, cssW, cssH);
    ctx.fillStyle = "#ffffff";
    ctx.fillRect(0, 0, cssW, cssH);

    const b = bounds(state.route.nodes);
    const worldW = b.w + PAD * 2;
    const worldH = b.h + PAD * 2;
    const s = Math.min(cssW / worldW, cssH / worldH);

    state.route.nodes.forEach((n) => {
      ctx.fillStyle = "#edf3fb";
      ctx.strokeStyle = "#93a4bd";
      ctx.lineWidth = 1;
      const x = (n.x - b.minX + PAD) * s;
      const y = (n.y - b.minY + PAD) * s;
      ctx.fillRect(x, y, n.width * s, n.height * s);
      ctx.strokeRect(x, y, n.width * s, n.height * s);
    });

    const loc = el.locator;
    const viewW = el.editor.clientWidth / state.scale;
    const viewH = el.editor.clientHeight / state.scale;
    const lx = (-state.panX / state.scale) * s;
    const ly = (-state.panY / state.scale) * s;
    loc.style.left = `${Math.max(0, lx)}px`;
    loc.style.top = `${Math.max(0, ly)}px`;
    loc.style.width = `${viewW * s}px`;
    loc.style.height = `${viewH * s}px`;
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
  function escapeAttr(s) {
    return escapeHtml(s).replace(/'/g, "&#39;");
  }

  function relayout() {
    if (!state.route) return;
    if (layoutMode === "pipeline") {
      autoLayoutPipeline(state.route, { keepSizes: true });
    } else if (layoutMode === "wrap") {
      autoLayoutWrap(state.route, COLS, { keepSizes: true });
    } else {
      applyNodeSizes(state.route);
    }
    state.nodes = new Map(state.route.nodes.map((n) => [n.id, n]));
    renderTree();
    renderNodes();
    renderConnections();
    renderConfig();
    fitToView();
  }

  function setConfigMode(mode) {
    configMode = mode;
    const url = new URL(window.location.href);
    url.searchParams.set("config", mode);
    window.history.replaceState({}, "", url);
    document.body.dataset.configMode = mode;
    const sel = document.getElementById("config-mode");
    if (sel && sel.value !== mode) sel.value = mode;
    relayout();
  }

  function wireControls() {
    const configSel = document.getElementById("config-mode");
    if (configSel) {
      configSel.value = configMode;
      configSel.addEventListener("change", () => setConfigMode(configSel.value));
    }
    document.body.dataset.configMode = configMode;
    if (docsMode) return;
    document.getElementById("zoom-in").addEventListener("click", () => {
      state.scale = Math.min(2, state.scale * 1.15);
      applyTransform();
    });
    document.getElementById("zoom-out").addEventListener("click", () => {
      state.scale = Math.max(0.15, state.scale / 1.15);
      applyTransform();
    });
    document.getElementById("zoom-fit").addEventListener("click", fitToView);
    document.getElementById("zoom-100").addEventListener("click", () => {
      state.scale = 1;
      applyTransform();
    });

    el.editor.addEventListener("click", () => selectNode(null));

    let dragging = false;
    let lastX = 0;
    let lastY = 0;
    el.editor.addEventListener("pointerdown", (e) => {
      if (e.target.closest(".route-node") || e.target.closest(".hyperlink")) return;
      dragging = true;
      lastX = e.clientX;
      lastY = e.clientY;
      el.editor.classList.add("dragging");
      el.editor.setPointerCapture(e.pointerId);
    });
    el.editor.addEventListener("pointermove", (e) => {
      if (!dragging) return;
      state.panX += e.clientX - lastX;
      state.panY += e.clientY - lastY;
      lastX = e.clientX;
      lastY = e.clientY;
      applyTransform();
    });
    el.editor.addEventListener("pointerup", () => {
      dragging = false;
      el.editor.classList.remove("dragging");
    });
    el.editor.addEventListener(
      "wheel",
      (e) => {
        e.preventDefault();
        const factor = e.deltaY < 0 ? 1.08 : 1 / 1.08;
        const prev = state.scale;
        state.scale = Math.min(2, Math.max(0.15, state.scale * factor));
        const rect = el.editor.getBoundingClientRect();
        const mx = e.clientX - rect.left;
        const my = e.clientY - rect.top;
        state.panX = mx - ((mx - state.panX) * state.scale) / prev;
        state.panY = my - ((my - state.panY) * state.scale) / prev;
        applyTransform();
      },
      { passive: false }
    );

    window.addEventListener("resize", () => {
      applyTransform();
    });
  }

  async function boot() {
    wireControls();
    if (!routeKey && BASE !== ".") {
      el.status.textContent = "No route selected";
      el.config.innerHTML = `<p class="config-empty">Choose a route from the picker above.</p>`;
      return;
    }
    el.status.textContent = "Loading route.v2.xml…";
    try {
      const res = await fetch(XML_URL);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const text = await res.text();
      const route = parseRoute(text);
      state.route = route;
      state.connections = route.connections;

      el.status.textContent = "Loading modules…";
      const moduleIds = route.nodes.map((n) => n.moduleId).filter(Boolean);
      state.modules = await window.RouteModuleConfig.loadModules(moduleIds);
      route.nodes.forEach((n) => applyModuleMeta(n, state.modules.get(n.moduleId)));

      if (layoutMode === "pipeline") {
        autoLayoutPipeline(route, { keepSizes: true });
      } else if (layoutMode === "wrap") {
        autoLayoutWrap(route, COLS, { keepSizes: true });
      } else {
        applyNodeSizes(route);
      }

      state.nodes = new Map(route.nodes.map((n) => [n.id, n]));

      const loaded = state.modules.size;
      const layoutLabel =
        layoutMode === "pipeline" ? " · pipeline layout" : layoutMode === "wrap" ? " · wrap layout" : "";
      const cfgLabel =
        configMode === "changed"
          ? " · non-default config"
          : configMode === "all"
            ? " · all config"
            : "";
      el.title.textContent = route.name;
      el.meta.textContent = `${route.nodes.length} modules (${loaded} configs) · ${route.connections.length} connections · v${route.version}${layoutLabel}${cfgLabel}`;
      renderTree();
      renderNodes();
      renderConnections();
      renderConfig();
      fitToView();
      el.status.textContent = "Ready";
      document.documentElement.setAttribute("data-ready", "1");
    } catch (err) {
      el.status.textContent = "Load failed";
      el.config.innerHTML = `<p class="config-empty">Could not load route/modules. Serve this folder over HTTP.<br><br>${escapeHtml(err.message)}</p>`;
      console.error(err);
    }
  }

  boot();
})();
