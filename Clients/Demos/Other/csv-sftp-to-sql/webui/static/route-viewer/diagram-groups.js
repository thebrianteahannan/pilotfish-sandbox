/**
 * Docs-only Processor Groups for route diagrams.
 * Collapses long processor chains into dashed group boxes (overview),
 * or focuses the canvas on one group's members (detail).
 *
 * Loaded by route-viewer.js when ?groups=1 is present.
 * Spec: GET .../diagram-groups.json next to route.v2.xml
 */
(function (global) {
  function escapeHtml(s) {
    return String(s ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function nodeByLabel(route, label) {
    const want = String(label || "").trim().toLowerCase();
    return route.nodes.find((n) => String(n.label || "").trim().toLowerCase() === want);
  }

  function resolveMembers(route, group) {
    const members = [];
    (group.labels || []).forEach((label) => {
      const n = nodeByLabel(route, label);
      if (n) members.push(n);
    });
    return members;
  }

  function resolveTransports(route, group) {
    const out = [];
    (group.transports || []).forEach((label) => {
      const n = nodeByLabel(route, label);
      if (n) out.push(n);
    });
    return out;
  }

  function sizeForGroup(title, description, count, docsMode) {
    const scale = docsMode ? 1.15 : 1;
    const width = Math.min(360, Math.max(260, 40 + String(title).length * 7)) * scale;
    const height = (description ? 108 : 86) * scale;
    return { width, height, count };
  }

  /**
   * Overview: replace each group's processor members with one virtual group node.
   * Transports stay as siblings (group → transport).
   */
  function collapseAll(route, spec, docsMode) {
    if (!spec || !Array.isArray(spec.groups)) return route;
    const byId = new Map(route.nodes.map((n) => [n.id, n]));
    const removeIds = new Set();
    const idRemap = new Map(); // old node id → group node id
    const groupNodes = [];

    spec.groups.forEach((g) => {
      const members = resolveMembers(route, g);
      if (members.length < 2) return;
      const gid = `group:${g.id}`;
      const size = sizeForGroup(g.title || g.id, g.description || "", members.length, docsMode);
      const groupNode = {
        id: gid,
        moduleId: null,
        label: g.title || g.id,
        description: g.description || "",
        memberCount: members.length,
        groupId: g.id,
        kind: "group",
        kindTitle: "Processor Group",
        module: null,
        x: 0,
        y: 0,
        width: size.width,
        height: size.height,
        collapsed: true,
      };
      groupNodes.push(groupNode);
      members.forEach((m) => {
        removeIds.add(m.id);
        idRemap.set(m.id, gid);
      });
    });

    if (!groupNodes.length) return route;

    // Rewire connections, drop internals
    const newConns = [];
    const seen = new Set();
    route.connections.forEach((c) => {
      const src = idRemap.get(c.sourceNodeId) || c.sourceNodeId;
      const tgt = idRemap.get(c.targetNodeId) || c.targetNodeId;
      if (src === tgt) return; // internal to same group
      if (removeIds.has(src) || removeIds.has(tgt)) return; // should not happen after remap
      // If either end was removed without remap, skip
      const srcOk = !removeIds.has(c.sourceNodeId) || idRemap.has(c.sourceNodeId);
      const tgtOk = !removeIds.has(c.targetNodeId) || idRemap.has(c.targetNodeId);
      if (!srcOk || !tgtOk) return;
      const key = `${src}->${tgt}`;
      if (seen.has(key)) return;
      seen.add(key);
      newConns.push({
        ...c,
        id: `c-${src}-${tgt}`,
        sourceNodeId: src,
        targetNodeId: tgt,
      });
    });

    const kept = route.nodes.filter((n) => !removeIds.has(n.id));
    // Ensure group nodes are present for remapped ids
    const present = new Set(kept.map((n) => n.id));
    groupNodes.forEach((g) => {
      if (!present.has(g.id)) kept.push(g);
    });

    // Drop dangling connections to missing nodes
    const ids = new Set(kept.map((n) => n.id));
    route.nodes = kept;
    route.connections = newConns.filter(
      (c) => ids.has(c.sourceNodeId) && ids.has(c.targetNodeId)
    );
    return route;
  }

  /**
   * Detail: keep only one group's processors (+ optional transports) and a banner node.
   */
  function focusGroup(route, spec, groupId, docsMode) {
    if (!spec || !Array.isArray(spec.groups)) return route;
    const g = spec.groups.find((x) => x.id === groupId);
    if (!g) return route;
    const members = resolveMembers(route, g);
    const transports = resolveTransports(route, g);
    if (!members.length) return route;

    const keep = new Set([...members, ...transports].map((n) => n.id));
    const bannerId = `group-banner:${g.id}`;
    const banner = {
      id: bannerId,
      moduleId: null,
      label: g.title || g.id,
      description: g.description || `${members.length} processors (detail)`,
      memberCount: members.length,
      groupId: g.id,
      kind: "group",
      kindTitle: "Processor Group · Detail",
      module: null,
      x: 0,
      y: 0,
      width: Math.min(420, Math.max(280, 48 + String(g.title || "").length * 8)) * (docsMode ? 1.1 : 1),
      height: 96 * (docsMode ? 1.1 : 1),
      collapsed: false,
    };

    const nodes = [banner, ...route.nodes.filter((n) => keep.has(n.id))];
    // Wire banner → first member
    const first = members[0];
    const connections = route.connections.filter(
      (c) => keep.has(c.sourceNodeId) && keep.has(c.targetNodeId)
    );
    connections.unshift({
      id: `c-${bannerId}-${first.id}`,
      sourceNodeId: bannerId,
      targetNodeId: first.id,
      sourceConnector: "right-output",
      targetConnector: "left-input",
      condition: false,
    });

    route.nodes = nodes;
    route.connections = connections;
    return route;
  }

  function listGroups(spec) {
    return (spec && spec.groups) || [];
  }

  function renderGroupInnerHtml(n) {
    const desc = n.description
      ? `<div class="route-node-group-desc">${escapeHtml(n.description)}</div>`
      : "";
    const count =
      typeof n.memberCount === "number"
        ? `<div class="route-node-group-count">${n.collapsed ? "▸ " : "▾ "}${n.memberCount} processors${n.collapsed ? " · see detail page" : ""}</div>`
        : "";
    return `
      <div class="route-node-content">
        <div class="route-node-kind">${escapeHtml(n.kindTitle || "Processor Group")}</div>
        <div class="route-node-name" title="${escapeHtml(n.label)}">${escapeHtml(n.label)}</div>
        ${desc}
        ${count}
      </div>
      <div class="route-node-stripe"></div>
      <span class="route-connector-dot route-connector-input"></span>
      <span class="route-connector-dot route-connector-output"></span>
    `;
  }

  global.RouteDiagramGroups = {
    collapseAll,
    focusGroup,
    listGroups,
    renderGroupInnerHtml,
    resolveMembers,
  };
})(window);
