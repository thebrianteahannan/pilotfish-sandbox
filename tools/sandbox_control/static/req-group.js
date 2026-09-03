(function () {
  const esc = (s) => String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const statusLabel = (s) => ({ planned: "plan ready", processing: "working", tested: "review", ready: "ready to deploy", applied: "deployed" }[s] || s || "saved");

  function where(open, canMerge) {
    if (!open) return "";
    if (open.git_merged) {
      return `<div class="git-where is-main"><strong>Code is on main</strong>${open.git_branch ? `<code>${esc(open.git_branch)}</code><span class="muted">merged from this feature branch</span>` : ""}</div>`;
    }
    if (open.git_branch) {
      return `<div class="git-where is-feature"><div><strong>Code is on the feature branch</strong><code>${esc(open.git_branch)}</code></div><button type="button" class="btn${canMerge ? " btn-go" : ""}" id="req-merge" ${canMerge ? "" : "disabled"}>Merge</button></div>`;
    }
    return `<div class="git-where"><strong>No branch yet</strong><span class="muted">Implement creates a feature branch for this request.</span></div>`;
  }

  function hours(open) {
    const label = (open && (open.billable_label || (open.billable_hours != null ? `${open.billable_hours}h` : ""))) || "";
    return label
      ? `<span class="hours-tag" title="Best guess if you did this by hand in eiConsole">${esc(label)}</span>`
      : "";
  }

  function top(reqs, deploy, processing) {
    const readyN = (reqs || []).filter((r) => r.git_merged && !(r.deployed || r.status === "applied")).length;
    const btn = `<button type="button" class="btn${readyN ? " btn-go" : ""}" id="client-deploy" ${processing || !readyN ? "disabled" : ""}>Deploy</button>`;
    return { btn, strip: "" };
  }

  function packBar(pack) {
    if (!pack || !pack.name) return "";
    const size = pack.size_kb >= 1024 ? `${(pack.size_kb / 1024).toFixed(1)} MB` : pack.size_kb ? `${pack.size_kb} KB` : "";
    const n = (pack.ids || []).length;
    const full = pack.path || pack.name || "";
    const zipName = pack.name || full.split("/").pop() || "";
    const prefix = full.endsWith(zipName) && full.length > zipName.length ? full.slice(0, -zipName.length) : "";
    const pathBits = zipName
      ? `<code>${esc(prefix)}<button type="button" class="req-deploy-name" data-zip="${esc(zipName)}" title="Show in Finder">${esc(zipName)}</button></code>`
      : "";
    return `<div class="req-video-place"><strong>TEST deploy</strong><a href="${esc(pack.url)}" rel="noopener">Download</a>${size ? `<span class="muted">${size}</span>` : ""}${n ? `<span class="muted">${n} request${n === 1 ? "" : "s"}</span>` : ""}${pathBits}</div>`;
  }

  function reqBtn(r, open) {
    const on = open && open.id === r.id;
    return `<button type="button" class="req-item ${on ? "is-on" : ""}" data-rid="${esc(r.id)}">
      ${hours(r)}
      <strong>${esc(r.subject || r.id)}</strong>
      <span class="muted">${esc(r.from)} · ${esc(r.received_at || "")}${r.git_merged ? " · on main" : r.git_branch ? " · feature " + esc(r.git_branch) : ""}</span>
      <span class="badge ${r.status === "ready" || r.status === "planned" || r.status === "tested" ? "on" : r.status === "error" ? "err" : "off"}">${esc(statusLabel(r.status))}</span>
    </button>`;
  }

  function hist(reqs, open, tab, deploy) {
    const deployed = (reqs || []).filter((r) => r.deployed || r.status === "applied");
    const active = (reqs || []).filter((r) => !(r.deployed || r.status === "applied"));
    const mode = tab === "deployed" ? "deployed" : "active";
    const tabs = `<div class="req-hist-tabs" role="tablist">
      <button type="button" class="req-hist-tab${mode === "active" ? " is-on" : ""}" data-hist="active">Active <span>${active.length}</span></button>
      <button type="button" class="req-hist-tab${mode === "deployed" ? " is-on" : ""}" data-hist="deployed">Deployed <span>${deployed.length}</span></button>
    </div>`;
    let body = "";
    if (mode === "active") {
      body = active.length ? `<div class="req-hist">${active.map((r) => reqBtn(r, open)).join("")}</div>` : `<p class="empty">No active requests.</p>`;
    } else {
      const byId = Object.fromEntries((reqs || []).map((r) => [r.id, r]));
      const used = new Set();
      const packs = (deploy && deploy.packs) || (deploy && deploy.ready ? [deploy] : []);
      const groups = packs
        .map((p) => {
          const members = (p.ids || []).map((id) => byId[id]).filter(Boolean);
          members.forEach((m) => used.add(m.id));
          return { pack: p, members };
        })
        .filter((g) => g.members.length || g.pack.name);
      const leftover = deployed.filter((r) => !used.has(r.id));
      if (!groups.length && !leftover.length) {
        body = `<p class="empty">No deployed requests.</p>`;
      } else {
        body = groups
          .map((g) => `<div class="req-deploy-group">${packBar(g.pack)}<div class="req-hist">${g.members.map((r) => reqBtn(r, open)).join("")}</div></div>`)
          .join("");
        if (leftover.length) {
          body += `<div class="req-deploy-group"><p class="muted">Other deployed</p><div class="req-hist">${leftover.map((r) => reqBtn(r, open)).join("")}</div></div>`;
        }
      }
    }
    return `<article class="panel"><h2>Request history</h2>${tabs}${body}</article>`;
  }

  async function handle(ev, selected, reload) {
    const reveal = ev.target.closest(".req-deploy-name");
    if (reveal && selected) {
      const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/deploy/reveal`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: reveal.getAttribute("data-zip") || "" }),
      });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) alert(data.error || "Could not show the zip in Finder");
      return true;
    }
    const btn = ev.target.closest("#client-deploy");
    if (!btn || !selected) return false;
    btn.disabled = true;
    const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/deploy`, { method: "POST" });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) alert(data.error || "Could not start deploy");
    await reload();
    return true;
  }

  window.pfGroup = { hist, handle, top, where, hours };
})();
