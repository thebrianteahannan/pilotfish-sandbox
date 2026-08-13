(function () {
  const esc = (s) => String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const PHASES = {
    starting: "Starting",
    queued: "Waiting",
    tts: "Synthesizing narration",
    recording: "Recording the browser",
    mux: "Combining audio and video",
    done: "Done",
    error: "Export failed",
  };

  function href(selected, id) {
    return `/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(id)}/video/file`;
  }

  function fmtSec(sec) {
    sec = Math.max(0, Math.floor(Number(sec) || 0));
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return m ? `${m}m ${String(s).padStart(2, "0")}s` : `${s}s`;
  }

  function timeLine(job) {
    const started = Date.parse((job && job.started_at) || "") || 0;
    const elapsed = started ? Math.max(0, Math.floor((Date.now() - started) / 1000)) : 0;
    const parts = started ? [`Elapsed ${fmtSec(elapsed)}`] : [];
    const left = Number(job && job.remaining_sec);
    if (Number.isFinite(left) && left > 0) parts.push(`about ${fmtSec(left)} left`);
    return parts.join(" · ");
  }

  function icon(open, selected) {
    const v = open.video || {};
    if (!v.ready) return "";
    return `<a class="vid-open" href="${href(selected, open.id)}" target="_blank" rel="noopener" title="Watch demo video" aria-label="Watch demo video"></a>`;
  }

  function bar(open, zipNext, processing) {
    const v = open.video || {};
    const rec = v.status === "running";
    const label = rec ? "Recording…" : v.ready ? "Re-generate Demo Video" : "Generate Demo Video";
    return `<button type="button" class="btn" id="req-video" ${zipNext && !processing && !rec ? "" : "disabled"}>${label}</button>`;
  }

  function place(open, selected) {
    const v = open.video || {};
    const job = v.job || v;
    const rec = v.status === "running";
    const failed = v.status === "error";
    if (rec || failed) {
      const phase = PHASES[job.phase] || (failed ? PHASES.error : "Creating request demo video");
      const step = Number(job.step) || 0;
      const total = Number(job.step_total) || 0;
      const phaseText = total > 0 && step > 0 ? `${phase} (${step} of ${total})` : phase;
      const rows = Array.isArray(job.log) ? job.log.slice(-6) : [];
      const log = rows
        .map((row) => {
          const text = typeof row === "string" ? row : (row && row.text) || "";
          return text ? `<li>${esc(text)}</li>` : "";
        })
        .join("");
      const barHtml =
        total > 0 ? `<div class="barwrap"><div class="bar" style="width:${Math.min(100, Math.round((step / total) * 100))}%"></div></div>` : "";
      return `<div class="video-panel ${failed ? "is-error" : ""}">
        <p class="video-phase">${esc(failed ? "Export failed" : phaseText)}</p>
        ${barHtml}
        <p class="video-msg">${esc(job.message || v.message || (failed ? job.error || v.error : "Working…") || "")}</p>
        <p class="muted">${rec ? esc(timeLine(job)) : ""}</p>
        ${log ? `<ul class="video-log">${log}</ul>` : ""}
        ${failed && (job.error || v.error) ? `<p class="video-err">${esc(job.error || v.error)}</p>` : ""}
      </div>`;
    }
    if (!v.ready) return "";
    const size = v.size_kb >= 1024 ? `${(v.size_kb / 1024).toFixed(1)} MB` : v.size_kb ? `${v.size_kb} KB` : "";
    return `<div class="req-video-place"><strong>Demo video</strong><a href="${href(selected, open.id)}" target="_blank" rel="noopener">Watch</a>${size ? `<span class="muted">${size}</span>` : ""}<code>${esc(v.path || "request-demo.mp4")}</code></div>`;
  }

  async function handle(ev, selected, selectedReq, reload) {
    const btn = ev.target.closest("#req-video");
    if (!btn || !selectedReq) return false;
    btn.disabled = true;
    const resp = await fetch(
      `/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(selectedReq)}/video`,
      { method: "POST" }
    );
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) alert(data.error || "Could not start video");
    await reload();
    return true;
  }

  window.pfVideo = { icon, bar, place, handle };
})();
