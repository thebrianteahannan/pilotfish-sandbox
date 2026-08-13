(function () {
  const esc = (s) => String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const statusLabel = (s) => ({ planned: "plan ready", processing: "working", tested: "review", ready: "ready to deploy", applied: "applied" }[s] || s || "saved");

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

  function top(reqs, deploy, processing) {
    const readyN = (reqs || []).filter((r) => r.git_merged).length;
    const btn = `<button type="button" class="btn${readyN ? " btn-go" : ""}" id="client-deploy" ${processing || !readyN ? "disabled" : ""}>Deploy</button>`;
    if (!deploy || !deploy.ready) return { btn, strip: "" };
    const size = deploy.size_kb >= 1024 ? `${(deploy.size_kb / 1024).toFixed(1)} MB` : deploy.size_kb ? `${deploy.size_kb} KB` : "";
    const n = (deploy.ids || []).length;
    const strip = `<div class="req-video-place"><strong>TEST deploy</strong><a href="${esc(deploy.url)}" rel="noopener">Download</a>${size ? `<span class="muted">${size}</span>` : ""}${n ? `<span class="muted">${n} request${n === 1 ? "" : "s"} on main</span>` : ""}<code>${esc(deploy.path || deploy.name)}</code></div>`;
    return { btn, strip };
  }

  function hist(reqs, open) {
    const items = reqs
      .map((r) => {
        const on = open && open.id === r.id;
        return `<button type="button" class="req-item ${on ? "is-on" : ""}" data-rid="${esc(r.id)}">
          <strong>${esc(r.subject || r.id)}</strong>
          <span class="muted">${esc(r.from)} · ${esc(r.received_at || "")}${r.git_merged ? " · on main" : r.git_branch ? " · feature " + esc(r.git_branch) : ""}</span>
          <span class="badge ${r.status === "ready" || r.status === "planned" || r.status === "tested" ? "on" : r.status === "error" ? "err" : "off"}">${esc(statusLabel(r.status))}</span>
        </button>`;
      })
      .join("");
    return `<article class="panel"><h2>Request history</h2>${reqs.length ? `<div class="req-hist">${items}</div>` : '<p class="empty">No requests saved yet.</p>'}</article>`;
  }

  async function handle(ev, selected, reload) {
    const btn = ev.target.closest("#client-deploy");
    if (!btn || !selected) return false;
    btn.disabled = true;
    const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/deploy`, { method: "POST" });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) alert(data.error || "Could not start deploy");
    await reload();
    return true;
  }

  window.pfGroup = { hist, handle, top, where };
})();
