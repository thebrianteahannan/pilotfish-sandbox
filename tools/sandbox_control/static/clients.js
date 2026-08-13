(function () {
  const $ = (id) => document.getElementById(id);
  const listEl = $("client-list");
  const filter = $("client-filter");
  const listView = $("client-list-view");
  const detailView = $("client-detail-view");
  const detailEl = $("client-detail");
  if (!listEl) return;

  let rows = [], pipeline = {}, job = {}, selected = "", selectedReq = "", detail = null;
  let timer = null, q = "", draft = emptyDraft(), ocrBusy = false, viewSig = "", planOpen = null;

  function emptyDraft() { return { from: "", subject: "", received_at: "", email: "", screenshots: [], previews: [], status: "" }; }

  function esc(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  function remember(part) { if (window.pfHub) window.pfHub.write(part); }

  function paintBanner() {
    const banner = $("job-banner");
    if (!banner) return;
    const err = (job && job.error) || (pipeline && pipeline.error) || "";
    const msg = (pipeline && pipeline.busy && (pipeline.message || "Processing client request…")) || (job && job.busy && (job.message || "")) || err;
    if (msg) {
      banner.hidden = false;
      banner.textContent = err || msg;
      banner.classList.toggle("is-err", !!err);
    } else banner.hidden = true;
  }

  const statusLabel = (s) => ({ planned: "plan ready", processing: "working", tested: "review", ready: "zip ready", applied: "applied" }[s] || s || "saved");
  const busy = () => !!(job && job.busy) || !!(pipeline && pipeline.busy);

  function renderList() {
    const shown = rows.filter((c) => {
      if (!q) return true;
      return `${c.title} ${c.name} ${c.slug}`.toLowerCase().includes(q);
    });
    $("client-count").textContent = `${shown.length} client${shown.length === 1 ? "" : "s"}`;
    if (!shown.length) {
      listEl.innerHTML = '<p class="empty">No clients under Clients/ (excluding Demos).</p>';
      return;
    }
    listEl.innerHTML = shown
      .map((c) => {
        const urls = c.local_url
          ? `<div class="urls"><a href="${esc(c.local_url)}" target="_blank" rel="noopener">Local</a>` +
            (c.lan_url ? `<a href="${esc(c.lan_url)}" target="_blank" rel="noopener">LAN</a>` : "") +
            (c.webui_port ? ` :${c.webui_port}` : "") +
            `</div>`
          : "";
        const latest = c.latest_request
          ? `<div class="muted">Latest: ${esc(c.latest_request.subject || c.latest_request.id)} · ${esc(statusLabel(c.latest_request.status))}</div>`
          : '<div class="muted">No requests yet</div>';
        return `<article class="card" data-cslug="${esc(c.slug)}">
          <div>
            <h3>${esc(c.title)}</h3>
            <code>${esc(c.path)}</code>
            ${urls}
            ${latest}
          </div>
          <div>
            <div style="text-align:right;margin-bottom:0.4rem">
              <span class="badge ${c.running ? "on" : "off"}">${c.running ? "Running" : "Stopped"}</span>
              <span class="badge off">${c.request_count || 0} request${c.request_count === 1 ? "" : "s"}</span>
            </div>
            <div class="actions">
              <button type="button" class="btn btn-primary" data-cact="open">Requests</button>
              <button type="button" class="btn" data-cact="start" ${busy() || c.running || !c.has_sandbox ? "disabled" : ""}>Start</button>
              <button type="button" class="btn btn-quiet" data-cact="stop" ${busy() || !c.running ? "disabled" : ""}>Stop</button>
            </div>
          </div>
        </article>`;
      })
      .join("");
  }

  function testsHtml(tests) {
    if (!tests || !tests.items) return "";
    return `<p class="${tests.ok ? "ok" : "bad"}"><strong>${tests.ok ? "All tests passed" : "Sandbox tests failed"}</strong></p>` + tests.items.map((i) => `<div class="row"><span>${esc(i.name)}</span><strong class="${i.ok ? "ok" : "bad"}">${i.ok ? "PASS" : "FAIL"}</strong><span class="muted">${esc(i.detail || "")}</span></div>`).join("");
  }

  function renderDetail() {
    const c = rows.find((x) => x.slug === selected);
    if (!c) {
      detailEl.innerHTML = '<p class="empty">Client not found.</p>';
      return;
    }
    $("client-detail-title").textContent = c.title;
    const reqs = (detail && detail.requests) || [];
    const open = detail && detail.request;
    const pipe = (detail && detail.pipeline) || pipeline;
    const processing = !!(pipe && pipe.busy && pipe.slug === selected);
    const formOpen = !reqs.length || ocrBusy || !!(draft.email || draft.from || draft.subject || (draft.screenshots || []).length);
    const form = `<details class="panel" id="req-new"${formOpen ? " open" : ""}>
      <summary>New email request</summary>
      <form id="req-form" class="req-form">
        <div class="drop-zone" id="req-drop">
          <input type="file" id="req-file" accept="image/*" multiple />
          <strong>Drop or paste a screenshot</strong>
          <span>Drop a file here, paste, or choose a photo. OCR fills From, Subject, and the email.</span>
          <div class="drop-actions"><div class="btn btn-primary drop-paste-btn" id="req-paste-btn" contenteditable="true" role="button" tabindex="0" inputmode="none" spellcheck="false">Paste screenshot</div><button type="button" class="btn" id="req-choose-btn">Choose photo</button></div>
          <p id="req-drop-status" class="muted"></p>
          <div class="draft-shots" id="req-draft-shots"></div>
        </div>
        <label>From<input name="from" type="text" placeholder="Karen Munoz &lt;karen@…&gt;" /></label>
        <label>Subject<input name="subject" type="text" required placeholder="Halifax splitting update" /></label>
        <label>Email date<input name="received_at" type="text" placeholder="2026-08-13" /></label>
        <label class="span2">Email text<textarea name="email" required rows="10" placeholder="Paste the client email, or drop a screenshot above…"></textarea></label>
        <input type="hidden" name="screenshots" value="" />
        <div class="span2 actions">
          <button type="submit" class="btn" data-run="">Save</button>
          <button type="submit" class="btn btn-primary" data-run="1">Save &amp; build plan</button>
        </div>
      </form>
    </details>`;
    const hist = `<article class="panel">
      <h2>Request history</h2>
      ${
        reqs.length
          ? `<div class="req-hist">${reqs
              .map(
                (r) =>
                  `<button type="button" class="req-item ${open && open.id === r.id ? "is-on" : ""}" data-rid="${esc(r.id)}">
                    <strong>${esc(r.subject || r.id)}</strong>
                    <span class="muted">${esc(r.from)} · ${esc(r.received_at || "")}</span>
                    <span class="badge ${r.status === "ready" || r.status === "planned" || r.status === "tested" ? "on" : r.status === "error" ? "err" : "off"}">${esc(statusLabel(r.status))}</span>
                  </button>`
              )
              .join("")}</div>`
          : '<p class="empty">No requests saved yet.</p>'
      }
    </article>`;
    let reqPanel = "";
    if (open) {
      const showResults = ["tested", "ready", "error"].includes(open.status);
      const testsOk = !!(open.tests && open.tests.ok);
      const zipNext = open.status === "tested" && testsOk && !processing;
      const zipIcon = open.status === "ready" && open.zip
        ? `<a class="zip-open" href="/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(open.id)}/zip" title="Download TEST deploy ZIP" aria-label="Download TEST deploy ZIP"></a>`
        : "";
      const showPlan = planOpen == null ? !(processing || showResults || open.status === "applied") : planOpen;
      const pdfUrl = open.plan_pdf_url || "";
      const pdfIcon = pdfUrl ? `<a class="pdf-open" href="${esc(pdfUrl)}" target="_blank" rel="noopener" title="Open change plan PDF" aria-label="Open change plan PDF"></a>` : "";
      const pdfBody = showPlan && pdfUrl
        ? `<iframe class="plan-frame" src="${esc(pdfUrl)}" title="Change plan PDF"></iframe>`
        : (!pdfUrl ? '<p class="muted">Build a change plan to inspect eip-root and write a PDF of the proposed edits.</p>' : "");
      const hasDiff = open.diff && !String(open.diff).startsWith("(no file");
      const diffView = open.diff_html
        ? `<div class="diff-side">${open.diff_html}</div>`
        : (hasDiff ? `<pre class="diff-view">${esc(open.diff)}</pre>` : "");
      reqPanel = `<article class="panel">
        <h2 class="req-head">${esc(open.subject || open.id)}<span class="file-icons">${pdfIcon}${zipIcon}</span></h2>
        <p class="muted">${esc(open.from)} · ${esc(open.received_at)} · ${esc(statusLabel(open.status))}${open.phase ? " · " + esc(open.phase) : ""}</p>
        <p>${esc(open.message || "")}</p>
        <div class="actions" style="margin:0.6rem 0">
          <button type="button" class="btn" id="req-process" ${processing ? "disabled" : ""}>Build change plan</button>
          <button type="button" class="btn${zipNext ? "" : " btn-primary"}" id="req-work" ${processing || !pdfUrl ? "disabled" : ""}>Start work</button>
          <button type="button" class="btn${zipNext ? " btn-go" : ""}" id="req-zip" ${zipNext ? "" : "disabled"}>Generate TEST Deploy ZIP</button>
        </div>
        ${open.tests ? `<div class="tests-block${testsOk ? " is-ok" : ""}"><h3>Sandbox tests</h3>${testsHtml(open.tests)}</div>` : ""}
        <h3>Email</h3>
        ${(open.screenshot_urls || []).length ? `<div class="req-shots">${(open.screenshot_urls || []).map((u) => `<img class="req-shot" src="${esc(u)}" alt="Request screenshot" />`).join("")}</div>` : ""}
        <details class="fold"><summary>OCR text</summary><pre class="email-view">${esc(open.email || "")}</pre></details>
        <details class="fold plan-fold" id="req-plan"${showPlan ? " open" : ""}>
          <summary>Proposed changes</summary>
          ${pdfBody}
        </details>
        ${showResults && diffView ? `<h3>Code changes</h3>${diffView}` : ""}
      </article>`;
    }
    detailEl.innerHTML =
      `<article class="card">
        <div>
          <h3>${esc(c.title)}</h3>
          <code>${esc(c.path)}</code>
          ${c.local_url ? `<div class="urls"><a href="${esc(c.local_url)}" target="_blank" rel="noopener">Local</a>${c.lan_url ? `<a href="${esc(c.lan_url)}" target="_blank" rel="noopener">LAN</a>` : ""}</div>` : ""}
        </div>
        <div class="actions">
          <span class="badge ${c.running ? "on" : "off"}">${c.running ? "Running" : "Stopped"}</span>
          <button type="button" class="btn" data-cact="start" ${busy() || c.running || !c.has_sandbox ? "disabled" : ""}>Start sandbox</button>
          <button type="button" class="btn btn-quiet" data-cact="stop" ${busy() || !c.running ? "disabled" : ""}>Stop</button>
        </div>
      </article>` +
      form +
      hist +
      reqPanel;
    applyDraft();
  }

  function captureDraft() {
    const form = $("req-form");
    if (!form) return;
    const fd = new FormData(form);
    draft.from = fd.get("from") || "";
    draft.subject = fd.get("subject") || "";
    draft.received_at = fd.get("received_at") || "";
    draft.email = fd.get("email") || "";
    const st = $("req-drop-status");
    if (st) draft.status = st.textContent || draft.status;
  }

  function applyDraft() {
    const form = $("req-form");
    if (!form) return;
    const set = (name, val) => {
      if (form.elements[name] && val) form.elements[name].value = val;
    };
    set("from", draft.from);
    set("subject", draft.subject);
    set("received_at", draft.received_at);
    set("email", draft.email);
    if (form.elements.screenshots) form.elements.screenshots.value = JSON.stringify(draft.screenshots || []);
    const st = $("req-drop-status");
    if (st) st.textContent = draft.status || "";
    const zone = $("req-drop");
    if (zone) zone.classList.toggle("is-busy", ocrBusy);
    const thumbs = $("req-draft-shots");
    if (thumbs) thumbs.innerHTML = (draft.previews || []).map((u) => `<img src="${esc(u)}" alt="Dropped screenshot" />`).join("");
    const box = $("req-new");
    if (box && (ocrBusy || draft.email || (draft.screenshots || []).length)) box.open = true;
  }

  async function loadList() {
    const resp = await fetch("/api/clients", { cache: "no-store" });
    const data = await resp.json();
    rows = data.clients || [];
    job = data.job || {};
    pipeline = data.pipeline || {};
    paintBanner();
    renderList();
  }

  async function loadDetail() {
    if (!selected) return;
    captureDraft();
    const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests`, { cache: "no-store" });
    const data = await resp.json();
    detail = { requests: data.requests || [], pipeline: data.pipeline || {}, request: null };
    pipeline = detail.pipeline;
    if (selectedReq) {
      const one = await fetch(
        `/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(selectedReq)}`,
        { cache: "no-store" }
      );
      const body = await one.json();
      if (body.request) detail.request = body.request;
      if (body.pipeline) pipeline = body.pipeline;
    }
    paintBanner();
    const r = (detail && detail.request) || {};
    const sig = [selected, selectedReq, r.updated_at, r.status, r.phase, r.message, r.plan_pdf_url, r.zip, !!(r.diff_html), (r.changes || []).length, pipeline && pipeline.busy, ((detail && detail.requests) || []).map((x) => x.id + x.status).join()].join("|");
    if (sig === viewSig && $("req-form")) return;
    viewSig = sig;
    if (window.pfHub && window.pfHub.holdScroll) window.pfHub.holdScroll(renderDetail);
    else renderDetail();
  }

  function schedule() {
    if (timer) clearTimeout(timer);
    const on = $("tab-clients") && !$("tab-clients").hidden;
    if (!on) return;
    const rec = pipeline && pipeline.busy;
    timer = setTimeout(async () => {
      try {
        await loadList();
        if (selected) await loadDetail();
      } catch (err) {}
      schedule();
    }, rec ? 1000 : 4000);
  }

  async function show() {
    listView.hidden = false;
    detailView.hidden = true;
    selected = "";
    selectedReq = "";
    viewSig = "";
    planOpen = null;
    draft = emptyDraft();
    remember({ client: "", request: "" });
    await loadList();
    schedule();
  }

  async function openClient(slug, reqId) {
    selected = slug;
    selectedReq = reqId || "";
    viewSig = "";
    planOpen = null;
    draft = emptyDraft();
    listView.hidden = true;
    detailView.hidden = false;
    remember({ tab: "clients", client: slug, request: selectedReq });
    await loadList();
    await loadDetail();
    schedule();
  }

  function restore() {
    const st = (window.pfHub && window.pfHub.read()) || {};
    const cq = st.clientQ || "";
    q = cq.trim().toLowerCase();
    if (filter) filter.value = cq;
    if (st.client) return openClient(st.client, st.request || "");
    return show();
  }

  filter.addEventListener("input", () => {
    q = (filter.value || "").trim().toLowerCase();
    remember({ clientQ: filter.value });
    renderList();
  });
  $("client-back").addEventListener("click", () => show());

  listEl.addEventListener("click", async (ev) => {
    const btn = ev.target.closest("button[data-cact]");
    if (!btn) return;
    const card = btn.closest("[data-cslug]");
    const slug = card && card.dataset.cslug;
    const act = btn.dataset.cact;
    if (!slug) return;
    if (act === "open") {
      openClient(slug);
      return;
    }
    btn.disabled = true;
    await fetch(`/api/clients/${encodeURIComponent(slug)}/${act}`, { method: "POST" });
    loadList();
  });

  async function ingestFiles(files) {
    const seen = new Set();
    files = [...(files || [])].filter((f) => f && (String(f.type || "").startsWith("image/") || /\.(png|jpe?g|gif|webp|tiff?)$/i.test(f.name || "")) && !seen.has(`${f.size}:${f.type}`) && seen.add(`${f.size}:${f.type}`));
    if (!selected || !files.length) return;
    ocrBusy = true;
    draft.status = `Reading ${files.length} screenshot${files.length === 1 ? "" : "s"}…`;
    applyDraft();
    for (const file of files) {
      draft.previews.push(URL.createObjectURL(file));
      const fd = new FormData();
      fd.append("file", file, file.name || "screenshot.png");
      const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/screenshot`, {
        method: "POST",
        body: fd,
      });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) {
        draft.status = data.error || "Could not read that screenshot.";
        continue;
      }
      if (data.path) draft.screenshots.push(data.path);
      ["from", "subject", "received_at"].forEach((k) => { if (data[k] && !draft[k]) draft[k] = data[k]; });
      const chunk = data.email || data.ocr || "";
      if (chunk) draft.email = draft.email ? `${draft.email.trim()}\n\n---\n\n${chunk}` : chunk;
      draft.status = `Read ${draft.screenshots.length} screenshot${draft.screenshots.length === 1 ? "" : "s"} — review the fields, then Save & process.`;
      applyDraft();
    }
    ocrBusy = false;
    applyDraft();
  }

  function clipFiles(cd) {
    const fromItems = [];
    for (const item of [...((cd && cd.items) || [])]) {
      if (String(item.type || "").startsWith("image/")) { const b = item.getAsFile(); if (b) fromItems.push(b); }
    }
    return fromItems.length ? fromItems : [...((cd && cd.files) || [])].filter((f) => String(f.type || "").startsWith("image/"));
  }

  detailEl.addEventListener("input", (ev) => {
    const paste = ev.target.closest("#req-paste-btn");
    if (paste) {
      const imgs = [...paste.querySelectorAll("img")];
      paste.textContent = "Paste screenshot";
      if (imgs.length) Promise.all(imgs.map((img) => fetch(img.src).then((r) => r.blob()).catch(() => null))).then((blobs) => ingestFiles(blobs.filter((b) => b && String(b.type || "").startsWith("image/")).map((b) => new File([b], "screenshot.png", { type: b.type || "image/png" }))));
      return;
    }
    if (ev.target.closest("#req-form")) captureDraft();
  });
  detailEl.addEventListener("keydown", (ev) => {
    if (ev.target.closest("#req-paste-btn") && !ev.metaKey && !ev.ctrlKey) ev.preventDefault();
  });
  detailEl.addEventListener("dragover", (ev) => {
    if (!ev.target.closest("#req-drop")) return;
    ev.preventDefault();
    if (ev.dataTransfer) ev.dataTransfer.dropEffect = "copy";
    $("req-drop").classList.add("is-over");
  });
  detailEl.addEventListener("dragleave", (ev) => {
    const z = $("req-drop");
    if (z && !z.contains(ev.relatedTarget)) z.classList.remove("is-over");
  });
  detailEl.addEventListener("drop", (ev) => {
    const z = $("req-drop");
    if (z) z.classList.remove("is-over");
    if (!ev.target.closest("#req-drop")) return;
    ev.preventDefault();
    const files = [...((ev.dataTransfer && ev.dataTransfer.files) || [])];
    if (files.length) ingestFiles(files);
  });
  detailEl.addEventListener("click", (ev) => {
    if (ev.target.closest("#req-paste-btn")) return;
    const zone = ev.target.closest("#req-drop");
    if (zone && ev.target.id !== "req-file" && $("req-file")) $("req-file").click();
  });
  detailEl.addEventListener("change", (ev) => {
    if (ev.target.id !== "req-file") return;
    ingestFiles([...(ev.target.files || [])]);
    ev.target.value = "";
  });
  window.addEventListener("paste", (ev) => {
    if (!($("tab-clients") && !$("tab-clients").hidden && selected && detailView && !detailView.hidden)) return;
    const files = clipFiles(ev.clipboardData);
    if (!files.length) return;
    ev.preventDefault();
    ingestFiles(files);
  });

  detailEl.addEventListener("toggle", (ev) => {
    if (ev.target.id !== "req-plan") return;
    planOpen = ev.target.open;
    if (planOpen && !ev.target.querySelector("iframe.plan-frame")) renderDetail();
  });

  detailEl.addEventListener("click", async (ev) => {
    const backAct = ev.target.closest("button[data-cact]");
    if (backAct && selected) {
      const act = backAct.dataset.cact;
      backAct.disabled = true;
      await fetch(`/api/clients/${encodeURIComponent(selected)}/${act}`, { method: "POST" });
      await loadList();
      await loadDetail();
      return;
    }
    const item = ev.target.closest("button[data-rid]");
    if (item) {
      selectedReq = item.dataset.rid;
      planOpen = null;
      remember({ request: selectedReq });
      await loadDetail();
      return;
    }
    const actBtn = ev.target.closest("#req-process, #req-work, #req-zip");
    if (actBtn && selectedReq) {
      const kind = actBtn.id === "req-process" ? "process" : actBtn.id === "req-zip" ? "zip" : "work";
      if (kind === "work") planOpen = false;
      actBtn.disabled = true;
      const resp = await fetch(
        `/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(selectedReq)}/${kind}`,
        { method: "POST" }
      );
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) alert(data.error || "Request failed");
      await loadDetail();
    }
  });

  detailEl.addEventListener("submit", async (ev) => {
    const form = ev.target.closest("#req-form");
    if (!form || !selected) return;
    ev.preventDefault();
    const run = ev.submitter && ev.submitter.getAttribute("data-run") === "1";
    const fd = new FormData(form);
    captureDraft();
    let shots = draft.screenshots || [];
    try {
      const parsed = JSON.parse(fd.get("screenshots") || "[]");
      if (Array.isArray(parsed) && parsed.length) shots = parsed;
    } catch (err) {}
    const payload = {
      from: fd.get("from") || "",
      subject: fd.get("subject") || "",
      received_at: fd.get("received_at") || "",
      email: fd.get("email") || "",
      screenshots: shots,
      process: run,
    };
    const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) { alert(data.error || "Could not save request"); return; }
    selectedReq = data.request && data.request.id;
    remember({ request: selectedReq || "" });
    draft = emptyDraft();
    form.reset();
    await loadList();
    await loadDetail();
  });

  window.pfClients = { show, openClient, restore };
  if (window.pfHub && window.pfHub.boot) window.pfHub.boot();
})();
