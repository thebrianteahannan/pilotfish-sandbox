(function () {
  const btn = document.getElementById("pf-create-video-btn");
  const status = document.getElementById("pf-create-video-status");
  const link = document.getElementById("pf-construction-video-link");
  const hint = document.getElementById("pf-construction-video-hint");
  const watch = document.getElementById("pf-video-watch");
  const badge = document.getElementById("pf-video-ready-badge");
  if (!btn) return;

  const PHASES = {
    starting: "Starting the exporter",
    tts: "Synthesizing narration",
    recording: "Recording the browser",
    mux: "Combining audio and video",
    transcript: "Writing the transcript",
    done: "Done",
    error: "Export failed",
    construction_video: "Creating construction video",
  };

  let pollTimer = null;
  let clockTimer = null;
  let lastJob = null;
  let banner = null;
  let wasRunning = false;
  let celebrateUntil = 0;

  function $(id) {
    return document.getElementById(id);
  }

  function setStatus(text) {
    if (status) status.textContent = text || "";
  }

  function fmtSec(sec) {
    sec = Math.max(0, Math.floor(Number(sec) || 0));
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return m ? `${m}m ${String(s).padStart(2, "0")}s` : `${s}s`;
  }

  function elapsedSec(job) {
    const started = Date.parse((job && job.started_at) || "") || 0;
    if (!started) return 0;
    return Math.max(0, Math.floor((Date.now() - started) / 1000));
  }

  function ensureBanner() {
    if (banner) return banner;
    banner = document.createElement("div");
    banner.id = "pf-video-job-banner";
    banner.className = "pf-video-job-banner";
    banner.hidden = true;
    banner.innerHTML =
      '<span class="pf-build-dot" aria-hidden="true"></span>' +
      "<strong>Creating construction video</strong>" +
      '<span id="pf-video-job-banner-msg"></span>' +
      '<span class="pf-video-job-banner-time" id="pf-video-job-banner-time"></span>';
    document.body.prepend(banner);
    return banner;
  }

  function timeLine(job) {
    const parts = [`Elapsed ${fmtSec(elapsedSec(job))}`];
    const left = Number(job && job.remaining_sec);
    if (Number.isFinite(left) && left > 0) parts.push(`about ${fmtSec(left)} left`);
    return parts.join(" · ");
  }

  function fmtSize(kb) {
    const n = Number(kb) || 0;
    if (n >= 1024) return `${(n / 1024).toFixed(1)} MB`;
    if (n > 0) return `${n} KB`;
    return "";
  }

  function paintProgress(job, running, ready, celebrate) {
    const panel = $("pf-create-video-panel");
    const phaseEl = $("pf-video-panel-phase");
    const msgEl = $("pf-video-panel-msg");
    const timeEl = $("pf-video-panel-time");
    const barWrap = $("pf-video-panel-barwrap");
    const bar = $("pf-video-panel-bar");
    const logEl = $("pf-video-panel-log");
    const justDone = !!(celebrate && ready && !running);
    const failed = !!(job && job.status === "error");
    const show = running || failed || justDone;
    if (panel) {
      panel.hidden = !show;
      panel.classList.toggle("is-ready", justDone);
      panel.classList.toggle("is-error", failed);
    }
    const barEl = ensureBanner();
    if (barEl) {
      barEl.hidden = !running && !justDone;
      barEl.classList.toggle("is-active", running);
      barEl.classList.toggle("is-ready", justDone);
      const title = barEl.querySelector("strong");
      if (title) title.textContent = justDone ? "Construction video is ready" : "Creating construction video";
    }
    if (!show && !running) return;
    if (justDone && !running) {
      if (phaseEl) phaseEl.textContent = "Video is ready";
      if (msgEl) msgEl.textContent = "Click Watch construction video to play it.";
      if (timeEl) timeEl.textContent = "";
      if (barWrap) barWrap.hidden = true;
      const bannerMsg = $("pf-video-job-banner-msg");
      const bannerTime = $("pf-video-job-banner-time");
      if (bannerMsg) bannerMsg.textContent = "Click Watch construction video on the Info tab.";
      if (bannerTime) bannerTime.textContent = "";
      return;
    }
    const phase = PHASES[job && job.phase] || PHASES.construction_video;
    const step = Number(job && job.step) || 0;
    const total = Number(job && job.step_total) || 0;
    const phaseText = total > 0 && step > 0 ? `${phase} (${step} of ${total})` : phase;
    if (phaseEl) phaseEl.textContent = phaseText;
    if (msgEl) msgEl.textContent = (job && job.message) || "Working…";
    if (timeEl) timeEl.textContent = timeLine(job);
    const bannerMsg = $("pf-video-job-banner-msg");
    const bannerTime = $("pf-video-job-banner-time");
    if (bannerMsg) bannerMsg.textContent = (job && job.message) || phase;
    if (bannerTime) bannerTime.textContent = timeLine(job);
    if (barWrap && bar) {
      if (total > 0) {
        barWrap.hidden = false;
        bar.max = total;
        bar.value = Math.min(step, total);
      } else {
        barWrap.hidden = true;
      }
    }
    if (logEl) {
      const rows = Array.isArray(job && job.log) ? job.log.slice(-6) : [];
      logEl.innerHTML = rows
        .map((row) => {
          const text = typeof row === "string" ? row : row.text || "";
          return text ? `<li>${text.replace(/</g, "&lt;")}</li>` : "";
        })
        .join("");
    }
  }

  function setClock(on) {
    if (clockTimer) {
      clearInterval(clockTimer);
      clockTimer = null;
    }
    if (!on) return;
    clockTimer = setInterval(() => {
      if (lastJob) {
        paintProgress(
          lastJob,
          lastJob.status === "running",
          lastJob.status === "done",
          Date.now() < celebrateUntil
        );
      }
    }, 1000);
  }

  function apply(data) {
    let job = (data && data.job) || null;
    if (!job && lastJob && lastJob.status === "running") {
      job = lastJob;
    }
    const ready = Boolean(data && (data.mp4 || data.ready));
    lastJob = job;
    const running = !!(job && job.status === "running");
    const size = fmtSize(data && data.size_kb);
    if (wasRunning && !running && ready) {
      celebrateUntil = Date.now() + 60000;
    }
    wasRunning = running;
    if (watch) watch.hidden = !ready;
    if (link) link.hidden = !ready;
    if (hint) hint.hidden = !ready;
    if (badge) badge.textContent = ready && !running ? (size ? `Ready · ${size}` : "Ready") : "";
    btn.disabled = running;
    btn.classList.toggle("btn-primary", !ready || running);
    btn.classList.toggle("pf-btn-quiet", ready && !running);
    paintProgress(job, running, ready, Date.now() < celebrateUntil);
    setClock(running);
    if (running) {
      btn.textContent = "Creating video…";
      setStatus("");
    } else {
      btn.textContent = ready ? "Re-create construction video" : "Create construction video";
      if (job && job.status === "error") {
        setStatus(job.error || job.message || "Export failed");
      } else if (ready) {
        setStatus("");
      } else {
        setStatus("Narration and transcript are ready. Video is created on demand.");
      }
    }
    return running;
  }

  let inFlight = false;

  function stillRunning() {
    return wasRunning || !!(lastJob && lastJob.status === "running");
  }

  function schedulePoll(keep) {
    if (pollTimer) {
      clearTimeout(pollTimer);
      pollTimer = null;
    }
    if (keep) pollTimer = setTimeout(refresh, 1000);
  }

  async function refresh() {
    if (inFlight) {
      schedulePoll(true);
      return;
    }
    inFlight = true;
    let keep = false;
    try {
      const ctrl = new AbortController();
      const abortAt = setTimeout(() => ctrl.abort(), 8000);
      try {
        const resp = await fetch("/api/construction-video", {
          cache: "no-store",
          signal: ctrl.signal,
        });
        const data = await resp.json();
        keep = apply(data);
      } finally {
        clearTimeout(abortAt);
      }
    } catch (err) {
      keep = stillRunning();
      if (keep) setStatus("Reconnecting to video progress…");
      else setStatus("Could not read video status.");
    } finally {
      inFlight = false;
      schedulePoll(keep);
    }
  }

  btn.addEventListener("click", async () => {
    btn.disabled = true;
    btn.textContent = "Creating video…";
    setStatus("Starting exporter…");
    lastJob = {
      status: "running",
      phase: "starting",
      message: "Starting exporter…",
      started_at: new Date().toISOString(),
      log: [{ text: "Clicked Create construction video" }],
    };
    wasRunning = true;
    paintProgress(lastJob, true, false, false);
    setClock(true);
    try {
      const resp = await fetch("/api/construction-video", { method: "POST" });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok && resp.status !== 202 && resp.status !== 409) {
        setStatus(data.message || data.error || data.command || "Exporter is not running on the host.");
        btn.disabled = false;
        btn.textContent = "Create construction video";
        paintProgress({ status: "error", phase: "error", message: data.message || data.error }, false, false, false);
        setClock(false);
        return;
      }
    } catch (err) {
      setStatus("Could not start the exporter.");
      btn.disabled = false;
      setClock(false);
      return;
    }
    refresh();
  });

  function dismissCelebrate() {
    celebrateUntil = 0;
    const panel = $("pf-create-video-panel");
    if (panel && panel.classList.contains("is-ready")) {
      panel.hidden = true;
      panel.classList.remove("is-ready");
    }
    if (banner) banner.hidden = true;
  }
  if (link) link.addEventListener("click", dismissCelebrate);

  document.addEventListener("visibilitychange", () => {
    if (!document.hidden && stillRunning()) refresh();
  });

  refresh();
})();
