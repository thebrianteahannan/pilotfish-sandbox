(function () {
  const p = new URLSearchParams(location.search);
  if ((p.get("tab") || p.get("client")) && window.pfHub) {
    const tab = p.get("tab") || "clients";
    window.pfHub.write({ tab, client: p.get("client") || "", request: p.get("request") || "" });
    if (window.pfHub.paint) window.pfHub.paint(tab);
    history.replaceState({}, "", location.pathname);
  }
  const $ = (id) => document.getElementById(id);

  function esc(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    }[c]));
  }

  function containerRow(c) {
    const on = c.running ? "on" : "";
    const ports = c.ports || "no published ports";
    return `<div class="row docker-row"><span><strong>${esc(c.name)}</strong> <span class="muted">${esc(c.kind)} · ${esc(c.project)}</span><div class="path">${esc(c.image)}</div><div class="muted">${esc(ports)}</div></span><span class="badge ${on}">${esc(c.status)}</span></div>`;
  }

  async function load() {
    const total = $("docker-total");
    const boxes = $("docker-containers");
    const imgs = $("docker-images");
    if (total) total.textContent = "Loading…";
    try {
      const resp = await fetch("/api/docker", { cache: "no-store" });
      const data = await resp.json();
      if (!data.ok) {
        if (total) total.textContent = data.error || "Docker unavailable";
        if (boxes) boxes.innerHTML = '<p class="empty">Could not list containers.</p>';
        if (imgs) imgs.innerHTML = "";
        return;
      }
      const cons = data.containers || [];
      if (total) total.textContent = `${cons.length} running`;
      if (boxes) {
        const groups = [
          ["Clients", cons.filter((c) => c.kind === "client")],
          ["Demos", cons.filter((c) => c.kind === "demo")],
        ];
        const html = groups
          .filter(([, list]) => list.length)
          .map(([title, list]) => `<div class="demo-group"><h2>${title}</h2>${list.map(containerRow).join("")}</div>`)
          .join("");
        boxes.innerHTML = html || '<p class="empty">No Sandbox Docker containers are running.</p>';
      }
      if (imgs) {
        const list = data.images || [];
        imgs.innerHTML =
          list
            .map(
              (im) =>
                `<div class="row"><span class="path">${esc(im.name)}</span><strong>${esc(im.size || "")}</strong></div>`
            )
            .join("") || '<p class="empty">None in use.</p>';
      }
    } catch (err) {
      if (total) total.textContent = "Could not reach the hub.";
    }
  }

  const refresh = $("docker-refresh");
  if (refresh) refresh.addEventListener("click", load);
  window.pfDocker = { load };
})();
