(function () {
  const $ = (id) => document.getElementById(id);
  const root = $("tab-emails");
  if (!root) return;

  let state = { linked: false, messages: [], clients: [], sync: {}, error: "" };

  function esc(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    }[c]));
  }

  const KIND = {
    new_work: "New work",
    update: "Update",
    capability: "Capability",
    question: "Question",
  };

  function clientOptions(selected) {
    return `<option value="">Pick a client…</option>` +
      (state.clients || [])
        .map((c) => `<option value="${esc(c.slug)}" ${c.slug === selected ? "selected" : ""}>${esc(c.title || c.name)}</option>`)
        .join("");
  }

  function render() {
    const linked = !!state.linked;
    const syncing = !!(state.sync && state.sync.busy);
    const err = state.error || (state.sync && state.sync.error) || "";
    const connect = `<article class="panel" id="mail-connect">
      <h2>Link Outlook (IMAP)</h2>
      <p class="hint">Microsoft 365 blocked the Graph sign-in (needs an admin). This uses IMAP at <code>outlook.office365.com</code>. If login fails, an admin must enable IMAP on the mailbox in Exchange admin center. Credentials stay on this Mac.</p>
      <form id="mail-form" class="req-form">
        <label>Outlook email<input name="user" type="email" required placeholder="you@pilotfishtechnology.com" value="${esc(state.user || "")}" /></label>
        <label>Password<input name="password" type="password" required autocomplete="off" /></label>
        <div class="span2 actions">
          <button type="submit" class="btn btn-primary">Link &amp; scan</button>
        </div>
      </form>
    </article>`;
    const bar = linked
      ? `<div class="toolbar">
          <span class="muted">Linked as ${esc(state.user)} · IMAP ${esc(state.host || "outlook.office365.com")}${state.cached_at ? " · scanned " + esc(state.cached_at) : ""}</span>
          <button type="button" class="btn btn-primary" id="mail-sync" ${syncing ? "disabled" : ""}>${syncing ? "Scanning…" : "Scan inbox"}</button>
          <button type="button" class="btn btn-quiet" id="mail-unlink">Unlink</button>
        </div>
        <p class="hint">Shows client asks for new work, updates, “can you do this?”, and general questions. Dismiss noise. Create a client request or a new demo, then continue on those tabs.</p>`
      : connect;
    const list = (state.messages || [])
      .map((m) => {
        const act = m.action || {};
        let done = "";
        if (act.status === "request" && act.slug) {
          done = `<button type="button" class="btn btn-primary" data-open-req="${esc(act.slug)}" data-req="${esc(act.req_id || "")}">Open request</button>`;
        } else if (act.status === "demo" && act.slug) {
          done = `<button type="button" class="btn btn-primary" data-open-demo="${esc(act.slug)}">Open demo</button>`;
        }
        const actions = done || `<div class="actions">
          <select data-slug>${clientOptions(m.client_slug)}</select>
          <button type="button" class="btn btn-primary" data-act="request">New request</button>
          <button type="button" class="btn" data-act="demo">New demo</button>
          <button type="button" class="btn btn-quiet" data-act="dismiss">Dismiss</button>
        </div>`;
        return `<article class="card mail-card" data-mid="${esc(m.id)}">
          <div>
            <h3>${esc(m.subject || "(no subject)")}</h3>
            <div class="muted">${esc(m.from)} · ${esc((m.received_at || "").slice(0, 16).replace("T", " "))}</div>
            <div class="urls">
              <span class="badge on">${esc(KIND[m.kind] || m.kind)}</span>
              ${m.client_name ? `<span class="badge off">${esc(m.client_name)}</span>` : ""}
            </div>
            <pre class="mail-snip">${esc((m.body || "").slice(0, 700))}</pre>
          </div>
          <div>${actions}</div>
        </article>`;
      })
      .join("");
    $("mail-ui").innerHTML =
      bar +
      (err ? `<p class="job-banner is-err" style="margin:0.6rem 0">${esc(err)}</p>` : "") +
      (linked
        ? `<div class="demo-list">${list || '<p class="empty">No matching client emails yet. Scan the inbox.</p>'}</div>`
        : "");
  }

  async function loadClients() {
    try {
      const resp = await fetch("/api/clients", { cache: "no-store" });
      const data = await resp.json();
      state.clients = data.clients || [];
    } catch (err) {
      state.clients = [];
    }
  }

  let poll = null;

  async function loadMail() {
    try {
      const resp = await fetch("/api/mail", { cache: "no-store" });
      const data = await resp.json();
      Object.assign(state, data);
      state.error = data.error || "";
    } catch (err) {
      state.error = "Could not reach the hub mail API.";
    }
    render();
  }

  async function show() {
    await loadClients();
    await loadMail();
  }

  $("mail-ui").addEventListener("submit", async (ev) => {
    const form = ev.target.closest("#mail-form");
    if (!form) return;
    ev.preventDefault();
    const fd = new FormData(form);
    const resp = await fetch("/api/mail/link", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ user: fd.get("user"), password: fd.get("password") }),
    });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) {
      state.error = data.error || "Could not link Outlook IMAP.";
      render();
      return;
    }
    await fetch("/api/mail/sync", { method: "POST" });
    await loadMail();
  });

  $("mail-ui").addEventListener("click", async (ev) => {
    if (ev.target.id === "mail-sync") {
      ev.target.disabled = true;
      await fetch("/api/mail/sync", { method: "POST" });
      await loadMail();
      return;
    }
    if (ev.target.id === "mail-unlink") {
      if (!confirm("Unlink Outlook from this hub? Cached mail stays dismissed locally until you scan again.")) return;
      await fetch("/api/mail/unlink", { method: "POST" });
      await loadMail();
      return;
    }
    const openReq = ev.target.closest("[data-open-req]");
    if (openReq && window.pfClients) {
      if (window.pfHub) window.pfHub.paint("clients");
      window.pfClients.openClient(openReq.dataset.openReq, openReq.dataset.req || "");
      return;
    }
    const openDemo = ev.target.closest("[data-open-demo]");
    if (openDemo && window.pfDemos) {
      window.pfDemos.showSlug(openDemo.dataset.openDemo);
      return;
    }
    const btn = ev.target.closest("button[data-act]");
    if (!btn) return;
    const card = btn.closest("[data-mid]");
    const id = card && card.dataset.mid;
    const act = btn.dataset.act;
    if (!id || !act) return;
    btn.disabled = true;
    if (act === "dismiss") {
      await fetch(`/api/mail/${encodeURIComponent(id)}/dismiss`, { method: "POST" });
      await loadMail();
      return;
    }
    if (act === "request") {
      const slug = (card.querySelector("select[data-slug]") || {}).value || "";
      const resp = await fetch(`/api/mail/${encodeURIComponent(id)}/request`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug }),
      });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) {
        alert(data.error || "Could not create request");
        btn.disabled = false;
        return;
      }
      if (window.pfHub) window.pfHub.paint("clients");
      if (window.pfClients) window.pfClients.openClient(data.slug, data.request && data.request.id);
      return;
    }
    if (act === "demo") {
      const resp = await fetch(`/api/mail/${encodeURIComponent(id)}/demo`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) {
        alert(data.error || "Could not create demo");
        btn.disabled = false;
        return;
      }
      if (window.pfDemos) window.pfDemos.showSlug(data.slug);
    }
  });

  window.pfMail = { show };
  const st = (window.pfHub && window.pfHub.read()) || {};
  if (st.tab === "emails") show();
})();
