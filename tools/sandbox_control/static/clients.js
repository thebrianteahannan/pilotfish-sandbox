(function () {
  const $ = (id) => document.getElementById(id);
  const listEl = $("client-list");
  const filter = $("client-filter");
  const listView = $("client-list-view");
  const detailView = $("client-detail-view");
  const detailEl = $("client-detail");
  if (!listEl) return;

  let rows = [], pipeline = {}, job = {}, selected = "", selectedReq = "", detail = null;
  let timer = null, q = "", draft = emptyDraft(), ocrBusy = false, viewSig = "", planOpen = null, commentsOpen = false, newOpen = null;

  function emptyDraft() { return { from: "", subject: "", received_at: "", email: "", comments: "", screenshots: [], previews: [], status: "" }; }

  function esc(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  function remember(part) { if (window.pfHub) window.pfHub.write(part); }

  function paintBanner() {
    const banner = $("job-banner");
    if (!banner) return;
    const err = (job && job.error) || (pipeline && pipeline.error) || "";
    const msg = (pipeline && pipeline.busy && (pipeline.message || "Processing client request…")) || (job && job.busy && (job.message || "")) || err;
    banner.hidden = !msg;
    if (msg) { banner.textContent = err || msg; banner.classList.toggle("is-err", !!err); }
  }

  const statusLabel = (s) => ({ planned: "plan ready", processing: "working", tested: "review", ready: "ready to deploy", applied: "applied" }[s] || s || "saved");
  const busy = () => !!(job && job.busy) || !!(pipeline && pipeline.busy);

  function renderList() {
    const shown = rows.filter((c) => {
      if (!q) return true;
      return `${c.title} ${c.name} ${c.slug}`.toLowerCase().includes(q);
    });
    $("client-count").textContent = `${shown.length} client${shown.length === 1 ? "" : "s"}`;
    if (!shown.length) { listEl.innerHTML = '<p class="empty">No clients under Clients/ (excluding Demos).</p>'; return; }
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
    return window.pfTests ? window.pfTests.html(tests, esc) : "";
  }

  function renderDetail() {
    const live = $("req-new");
    if (live) newOpen = live.open;
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
    const formOpen = newOpen || !reqs.length || ocrBusy || !!(draft.email || draft.from || draft.subject || (draft.screenshots || []).length);
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
    const top = window.pfGroup ? window.pfGroup.top(reqs, detail && detail.deploy, processing) : null;
    const hist = window.pfGroup
      ? window.pfGroup.hist(reqs, open)
      : `<article class="panel"><h2>Request history</h2><p class="empty">No requests saved yet.</p></article>`;
    let reqPanel = "";
    if (open) {
      const showResults = ["processing", "tested", "ready", "error", "applied"].includes(open.status);
      const testsOk = !!(open.tests && open.tests.ok);
      const reviewOk = testsOk && !processing && (open.status === "tested" || open.status === "ready" || open.status === "error");
      const canMerge = reviewOk && !open.git_merged;
      const pdfUrl = open.plan_pdf_url || "";
      const showPlan = planOpen == null ? (open.status === "planned" && !!pdfUrl) : planOpen;
      const pdfIcon = pdfUrl ? `<a class="pdf-open" href="${esc(pdfUrl)}" target="_blank" rel="noopener" title="Open change plan PDF" aria-label="Open change plan PDF"></a>` : "";
      const pdfBody = pdfUrl
        ? `<iframe class="plan-frame" src="${esc(pdfUrl)}" title="Change plan PDF"></iframe>`
        : '<p class="muted">Build a change plan to inspect eip-root and write a PDF of the proposed edits.</p>';
      const hasDiff = open.diff && !String(open.diff).startsWith("(no file");
      const diffView = open.diff_html
        ? `<div class="diff-side">${open.diff_html}</div>`
        : (hasDiff ? `<pre class="diff-view">${esc(open.diff)}</pre>` : "");
      reqPanel = `<article class="panel">
        <h2 class="req-head">${window.pfGroup ? window.pfGroup.hours(open) : ""}${esc(open.subject || open.id)}<span class="file-icons">${pdfIcon}${window.pfVideo ? window.pfVideo.icon(open, selected) : ""}</span></h2>
        <p class="muted">${esc(open.from)} · ${esc(open.received_at)} · ${esc(statusLabel(open.status))}${open.phase ? " · " + esc(open.phase) : ""}</p>
        ${window.pfGroup ? window.pfGroup.where(open, canMerge) : ""}
        <p>${esc(open.message || "")}</p>
        <div class="actions" style="margin:0.6rem 0">
          ${open.tests ? `<a class="test-jump ${testsOk ? "ok" : "bad"}" href="#req-tests">${testsOk ? "Tests passed" : "Tests failed"}</a>` : ""}
          <button type="button" class="btn" id="req-process" ${processing ? "disabled" : ""}>${pdfUrl ? "Re-Build plan" : "Build plan"}</button>
          <button type="button" class="btn${!testsOk && pdfUrl ? " btn-primary" : ""}" id="req-work" ${processing || !pdfUrl ? "disabled" : ""}>${showResults || open.git_branch ? "Re-Implement plan" : "Implement"}</button>
          ${window.pfVideo ? window.pfVideo.bar(open, reviewOk, processing, selected) : ""}
        </div>${window.pfVideo ? window.pfVideo.place(open, selected) : ""}
        ${(open.request_summary || (open.dive && (open.dive.ask || open.dive.summary)) || open.subject) ? `<div class="change-blurb"><strong>What is being requested</strong><p>${esc(open.request_summary || (open.dive && (open.dive.ask || open.dive.summary)) || open.subject)}</p></div>` : ""}
        ${window.pfComments ? window.pfComments.fold(open, commentsOpen) : ""}
        ${(open.dive && (open.dive.delta || []).length) ? `<div class="comment-delta"><strong>From your comments</strong>${open.dive.delta.map((d) => `<p>${esc(d)}</p>`).join("")}</div>` : ""}
        <h3>Email</h3>
        ${(open.screenshot_urls || []).length ? `<div class="req-shots">${(open.screenshot_urls || []).map((u) => `<a href="${esc(u)}" target="_blank" rel="noopener"><img class="req-shot" src="${esc(u)}" alt="Request screenshot" /></a>`).join("")}</div>` : ""}
        <details class="fold"><summary>OCR text</summary><pre class="email-view">${esc(open.email || "")}</pre></details>
        <details class="fold plan-fold" id="req-plan"${showPlan ? " open" : ""}>
          <summary>Proposed changes</summary>
          ${pdfBody}
        </details>
        ${showResults && diffView ? `${(open.change_summary || (open.dive && open.dive.summary)) ? `<div class="change-blurb"><strong>What changed</strong><p>${esc(open.change_summary || open.dive.summary)}</p></div>` : ""}<h3>Code changes</h3>${diffView}` : ""}${open.tests ? `<div class="tests-block${testsOk ? " is-ok" : ""}" id="req-tests"><h3>Test results</h3>${testsHtml(open.tests)}</div>` : ""}
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
          ${top ? top.btn : ""}
        </div>
      </article>` +
      (top ? top.strip : "") +
      form +
      hist +
      reqPanel;
    applyDraft();
    if (window.pfDiff) window.pfDiff.fold(detailEl);
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
    detail = { requests: data.requests || [], pipeline: data.pipeline || {}, request: null, deploy: data.deploy || null };
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
    const v = r.video || {};
    const sig = [selected, selectedReq, r.updated_at, r.status, r.phase, r.message, r.plan_pdf_url, r.git_merged, !!(r.diff_html), (r.changes || []).length, pipeline && pipeline.busy, v.status, v.ready, v.phase, v.step, v.message, detail && detail.deploy && detail.deploy.path, ((detail && detail.requests) || []).map((x) => x.id + x.status).join()].join("|");
    if (sig === viewSig && $("req-form")) return;
    viewSig = sig;
    if (window.pfHub && window.pfHub.holdScroll) window.pfHub.holdScroll(renderDetail);
    else renderDetail();
  }

  function schedule() {
    if (timer) clearTimeout(timer);
    const on = $("tab-clients") && !$("tab-clients").hidden;
    if (!on) return;
    const rec = (pipeline && pipeline.busy) || ((detail && detail.request && detail.request.video && detail.request.video.status) === "running");
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
    planOpen = null; commentsOpen = false; newOpen = null;
    draft = emptyDraft();
    remember({ client: "", request: "" });
    await loadList();
    schedule();
  }

  async function openClient(slug, reqId) {
    selected = slug;
    selectedReq = reqId || "";
    viewSig = "";
    planOpen = null; commentsOpen = false; newOpen = null;
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
    if ($("req-notes-fold") && $("req-notes-fold").open) return;
    const files = clipFiles(ev.clipboardData);
    if (!files.length) return;
    ev.preventDefault();
    ingestFiles(files);
  });

  detailEl.addEventListener("toggle", (ev) => {
    if (ev.target.id === "req-plan") planOpen = ev.target.open; else if (ev.target.id === "req-notes-fold") commentsOpen = ev.target.open;
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
      planOpen = null; commentsOpen = false;
      remember({ request: selectedReq });
      await loadDetail();
      return;
    }
    if (window.pfGroup && await window.pfGroup.handle(ev, selected, () => loadDetail())) return;
    if (window.pfComments && await window.pfComments.handle(ev, selected, selectedReq, () => { commentsOpen = true; return loadDetail(); })) return;
    if (window.pfVideo && await window.pfVideo.handle(ev, selected, selectedReq, () => loadDetail())) return;
    const actBtn = ev.target.closest("#req-process, #req-work, #req-merge");
    if (actBtn && selectedReq) {
      const kind = actBtn.id === "req-process" ? "process" : actBtn.id === "req-merge" ? "merge" : "work";
      if (kind === "work") planOpen = false; else if (kind === "process") planOpen = true;
      actBtn.disabled = true;
      const comments = kind === "process" && $("req-comments") ? $("req-comments").value : "";
      const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(selectedReq)}/${kind}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ comments }) });
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

  if (window.pfComments) window.pfComments.bind(detailEl, () => ({ selected, selectedReq, reload() { commentsOpen = true; return loadDetail(); } }));
  window.pfClients = { show, openClient, restore };
  if (window.pfHub && window.pfHub.boot) window.pfHub.boot();
})();
