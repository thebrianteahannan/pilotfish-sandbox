(function () {
  const esc = (s) => String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  function html(open) {
    const qs = (open.dive && open.dive.questions) || [];
    if (!qs.length) return "";
    const openN = qs.filter((q) => q.status !== "closed").length;
    const items = qs
      .map((q) => {
        const closed = q.status === "closed";
        const ans = closed
          ? `<p class="muted">${esc(q.answer || "Closed")}</p>`
          : `<textarea class="q-answer" data-qid="${esc(q.id)}" rows="2" placeholder="Paste their reply…"></textarea>
             <div class="actions" style="margin:0.35rem 0 0">
               <button type="button" class="btn btn-primary" data-qsave="${esc(q.id)}">Save reply &amp; close</button>
               <button type="button" class="btn" data-qclose="${esc(q.id)}">Close without reply</button>
             </div>`;
        return `<div class="q-item ${closed ? "is-closed" : ""}">
          <span class="badge ${closed ? "off" : "on"}">${closed ? "Closed" : "Open"}</span>
          <p><strong>${esc(q.text)}</strong></p>
          ${q.why ? `<p class="muted">${esc(q.why)}</p>` : ""}
          ${ans}
        </div>`;
      })
      .join("");
    return `<details class="fold q-box" id="req-questions"${openN ? " open" : ""}><summary>Questions for the client <span class="muted">· ${openN} open</span></summary>${items}</details>`;
  }

  async function patch(selected, reqId, qid, body) {
    const resp = await fetch(
      `/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(reqId)}/questions/${encodeURIComponent(qid)}`,
      { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) }
    );
    if (!resp.ok) alert(((await resp.json().catch(() => ({}))).error) || "Could not update question");
    return resp.ok;
  }

  async function handle(ev, selected, selectedReq, reload) {
    if (!selectedReq) return false;
    const save = ev.target.closest("[data-qsave]");
    const close = ev.target.closest("[data-qclose]");
    if (!save && !close) return false;
    const qid = (save || close).dataset.qsave || (save || close).dataset.qclose;
    const ta = document.querySelector(`textarea.q-answer[data-qid="${qid}"]`);
    const answer = ta ? ta.value : "";
    await patch(selected, selectedReq, qid, save ? { answer, status: "closed" } : { answer: "", status: "closed" });
    await reload();
    return true;
  }

  window.pfQuestions = { html, handle };
})();
