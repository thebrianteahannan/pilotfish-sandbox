(function () {
  const esc = (s) => String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  function notes(open) {
    if (open.comment_log && open.comment_log.length) return open.comment_log;
    return open.comments ? [{ at: "", text: open.comments }] : [];
  }

  function item(n, i) {
    const when = n.at ? String(n.at).replace("T", " ").replace("Z", "") : "";
    const stamp = when ? `<span class="muted">${esc(when)}${n.edited_at ? " · edited" : ""}</span>` : "<span></span>";
    const shot = n.screenshot_url ? `<a href="${esc(n.screenshot_url)}" target="_blank" rel="noopener"><img class="req-shot" src="${esc(n.screenshot_url)}" alt="Comment screenshot" /></a>` : "";
    return `<div class="req-comment" data-cidx="${i}"><div class="req-comment-bar">${stamp}<span class="req-comment-acts"><button type="button" class="btn-link" data-cedit="${i}">Edit</button><button type="button" class="btn-link" data-cdel="${i}">Delete</button></span></div>${shot}<p data-cbody>${esc(n.text)}</p></div>`;
  }

  function fold(open, openFold) {
    return `<details class="fold" id="req-notes-fold"${openFold ? " open" : ""}><summary>Add comments</summary>${notes(open).map(item).join("")}<div class="drop-zone" id="req-comment-drop"><input type="file" id="req-comment-file" accept="image/*" multiple /><strong>Drop or paste a screenshot</strong><span>OCR becomes the comment, same as a new request.</span><div class="drop-actions"><div class="btn btn-primary drop-paste-btn" id="req-comment-paste" contenteditable="true" role="button" tabindex="0" inputmode="none" spellcheck="false">Paste screenshot</div><button type="button" class="btn" id="req-comment-choose">Choose photo</button></div><p id="req-comment-status" class="muted"></p></div><label class="req-notes"><textarea id="req-comments" rows="3" placeholder="What should the next plan change?"></textarea></label><div class="actions" style="margin:0.4rem 0 0"><button type="button" class="btn" id="req-comment-add">Add comment</button></div></details>`;
  }

  async function api(selected, reqId, suffix, method, body) {
    const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(reqId)}/comments${suffix}`, {
      method,
      headers: { "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (!resp.ok) alert(((await resp.json().catch(() => ({}))).error) || "Could not update comment");
    return resp.ok;
  }

  function startEdit(box) {
    const p = box && box.querySelector("[data-cbody]");
    if (!p || box.querySelector("textarea[data-cedit-text]")) return;
    const ta = document.createElement("textarea");
    ta.dataset.ceditText = "1";
    ta.rows = 3;
    ta.value = p.textContent;
    p.replaceWith(ta);
    const acts = box.querySelector(".req-comment-acts");
    if (acts) acts.innerHTML = `<button type="button" class="btn-link" data-csave="${box.dataset.cidx}">Save</button><button type="button" class="btn-link" data-ccancel="${box.dataset.cidx}">Cancel</button>`;
    ta.focus();
  }

  function clipFiles(cd) {
    const fromItems = [];
    for (const item of [...((cd && cd.items) || [])]) {
      if (String(item.type || "").startsWith("image/")) { const b = item.getAsFile(); if (b) fromItems.push(b); }
    }
    return fromItems.length ? fromItems : [...((cd && cd.files) || [])].filter((f) => String(f.type || "").startsWith("image/"));
  }

  function imageFiles(files) {
    const seen = new Set();
    return [...(files || [])].filter((f) => f && (String(f.type || "").startsWith("image/") || /\.(png|jpe?g|gif|webp|tiff?)$/i.test(f.name || "")) && !seen.has(`${f.size}:${f.type}`) && seen.add(`${f.size}:${f.type}`));
  }

  async function ingest(selected, reqId, files, reload) {
    files = imageFiles(files);
    if (!selected || !reqId || !files.length) return;
    const st = document.getElementById("req-comment-status");
    const zone = document.getElementById("req-comment-drop");
    if (zone) zone.classList.add("is-busy");
    if (st) st.textContent = `Reading ${files.length} screenshot${files.length === 1 ? "" : "s"}…`;
    let ok = false;
    for (const file of files) {
      const fd = new FormData();
      fd.append("file", file, file.name || "screenshot.png");
      const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(reqId)}/comments/screenshot`, { method: "POST", body: fd });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) { if (st) st.textContent = data.error || "Could not read that screenshot."; continue; }
      ok = true;
    }
    if (zone) zone.classList.remove("is-busy");
    if (ok) await reload();
  }

  async function handle(ev, selected, selectedReq, reload) {
    if (!selectedReq) return false;
    const add = ev.target.closest("#req-comment-add");
    const del = ev.target.closest("[data-cdel]");
    const edit = ev.target.closest("[data-cedit]");
    const save = ev.target.closest("[data-csave]");
    const cancel = ev.target.closest("[data-ccancel]");
    if (!add && !del && !edit && !save && !cancel) return false;
    ev.preventDefault();
    if (add) {
      const text = ((document.getElementById("req-comments") || {}).value || "").trim();
      if (text && await api(selected, selectedReq, "", "POST", { text })) await reload();
      return true;
    }
    const btn = del || edit || save || cancel;
    const idx = Number(btn.getAttribute("data-cdel") || btn.getAttribute("data-cedit") || btn.getAttribute("data-csave") || btn.getAttribute("data-ccancel"));
    const box = ev.target.closest(".req-comment");
    if (edit) { startEdit(box); return true; }
    if (cancel) { await reload(); return true; }
    if (del) {
      if (!confirm("Delete this comment?")) return true;
      if (await api(selected, selectedReq, "/" + idx, "DELETE")) await reload();
      return true;
    }
    const text = (((box && box.querySelector("textarea[data-cedit-text]")) || {}).value || "").trim();
    if (text && await api(selected, selectedReq, "/" + idx, "PATCH", { text })) await reload();
    return true;
  }

  function bind(detailEl, ctx) {
    if (!detailEl || detailEl.dataset.cBound) return;
    detailEl.dataset.cBound = "1";
    const go = (files) => { const { selected, selectedReq, reload } = ctx(); ingest(selected, selectedReq, files, reload); };
    detailEl.addEventListener("dragover", (ev) => {
      if (!ev.target.closest("#req-comment-drop")) return;
      ev.preventDefault();
      if (ev.dataTransfer) ev.dataTransfer.dropEffect = "copy";
      const z = document.getElementById("req-comment-drop");
      if (z) z.classList.add("is-over");
    });
    detailEl.addEventListener("dragleave", (ev) => {
      const z = document.getElementById("req-comment-drop");
      if (z && !z.contains(ev.relatedTarget)) z.classList.remove("is-over");
    });
    detailEl.addEventListener("drop", (ev) => {
      const z = document.getElementById("req-comment-drop");
      if (z) z.classList.remove("is-over");
      if (!ev.target.closest("#req-comment-drop")) return;
      ev.preventDefault();
      go([...((ev.dataTransfer && ev.dataTransfer.files) || [])]);
    });
    detailEl.addEventListener("click", (ev) => {
      if (ev.target.closest("#req-comment-paste")) return;
      if (ev.target.closest("#req-comment-choose") || (ev.target.closest("#req-comment-drop") && ev.target.id !== "req-comment-file")) {
        const inp = document.getElementById("req-comment-file");
        if (inp) inp.click();
      }
    });
    detailEl.addEventListener("change", (ev) => {
      if (ev.target.id !== "req-comment-file") return;
      go([...(ev.target.files || [])]);
      ev.target.value = "";
    });
    detailEl.addEventListener("input", (ev) => {
      const paste = ev.target.closest("#req-comment-paste");
      if (!paste) return;
      const imgs = [...paste.querySelectorAll("img")];
      paste.textContent = "Paste screenshot";
      if (imgs.length) Promise.all(imgs.map((img) => fetch(img.src).then((r) => r.blob()).catch(() => null))).then((blobs) => go(blobs.filter((b) => b && String(b.type || "").startsWith("image/")).map((b) => new File([b], "screenshot.png", { type: b.type || "image/png" }))));
    });
    detailEl.addEventListener("keydown", (ev) => {
      if (ev.target.closest("#req-comment-paste") && !ev.metaKey && !ev.ctrlKey) ev.preventDefault();
    });
    window.addEventListener("paste", (ev) => {
      const fold = document.getElementById("req-notes-fold");
      if (!fold || !fold.open) return;
      const files = clipFiles(ev.clipboardData);
      if (!files.length) return;
      ev.preventDefault();
      ev.stopImmediatePropagation();
      go(files);
    }, true);
  }

  window.pfComments = { fold, handle, bind };
})();
