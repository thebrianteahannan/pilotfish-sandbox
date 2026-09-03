(function () {
  const player = document.getElementById("pf-construction-player");
  const wrap = document.getElementById("pf-video-player-wrap");
  const timeEl = document.getElementById("pf-video-review-time");
  const textEl = document.getElementById("pf-video-review-text");
  const addBtn = document.getElementById("pf-video-review-add");
  const listEl = document.getElementById("pf-video-review-list");
  const emptyEl = document.getElementById("pf-video-review-empty");
  if (!player || !addBtn || !textEl || !listEl) return;

  function fmtTime(sec) {
    sec = Math.max(0, Number(sec) || 0);
    const m = Math.floor(sec / 60);
    const s = Math.floor(sec % 60);
    return `${m}:${String(s).padStart(2, "0")}`;
  }

  function currentSec() {
    return Number(player.currentTime) || 0;
  }

  function paintTime() {
    if (timeEl) timeEl.textContent = fmtTime(currentSec());
  }

  function render(comments) {
    const rows = Array.isArray(comments) ? comments.slice() : [];
    rows.sort((a, b) => (Number(a.t_sec) || 0) - (Number(b.t_sec) || 0));
    if (emptyEl) emptyEl.hidden = rows.length > 0;
    listEl.innerHTML = rows
      .map((row) => {
        const id = String(row.id || "");
        const done = row.status === "done";
        const text = String(row.text || "").replace(/</g, "&lt;");
        return (
          `<li class="pf-video-note${done ? " is-done" : ""}" data-id="${id}" data-t="${row.t_sec}">` +
          `<button type="button" class="pf-video-note-time" data-seek="${row.t_sec}">${fmtTime(row.t_sec)}</button>` +
          `<p class="pf-video-note-text">${text}</p>` +
          `<div class="pf-video-note-actions">` +
          `<button type="button" class="pf-video-note-done" data-id="${id}" data-status="${done ? "open" : "done"}">${done ? "Reopen" : "Done"}</button>` +
          `<button type="button" class="pf-video-note-del" data-id="${id}">Delete</button>` +
          `</div></li>`
        );
      })
      .join("");
  }

  async function refresh() {
    const resp = await fetch("/api/video-review-comments", { cache: "no-store" });
    const data = await resp.json();
    render((data && data.comments) || []);
  }

  async function addNote() {
    const text = (textEl.value || "").trim();
    if (!text) {
      textEl.focus();
      return;
    }
    player.pause();
    addBtn.disabled = true;
    try {
      const resp = await fetch("/api/video-review-comments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text, t_sec: currentSec() }),
      });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) {
        textEl.setCustomValidity(data.error || "Could not save note");
        textEl.reportValidity();
        return;
      }
      textEl.value = "";
      await refresh();
    } finally {
      addBtn.disabled = false;
      textEl.focus();
    }
  }

  player.addEventListener("timeupdate", paintTime);
  player.addEventListener("seeked", paintTime);
  player.addEventListener("pause", () => {
    paintTime();
    if (wrap && !wrap.hidden) textEl.focus();
  });

  addBtn.addEventListener("click", addNote);
  textEl.addEventListener("keydown", (ev) => {
    if (ev.key === "Enter" && (ev.metaKey || ev.ctrlKey)) {
      ev.preventDefault();
      addNote();
    }
  });

  listEl.addEventListener("click", async (ev) => {
    const seek = ev.target.closest("[data-seek]");
    if (seek) {
      player.currentTime = Number(seek.getAttribute("data-seek")) || 0;
      player.pause();
      paintTime();
      return;
    }
    const del = ev.target.closest(".pf-video-note-del");
    if (del) {
      await fetch(`/api/video-review-comments/${del.getAttribute("data-id")}`, { method: "DELETE" });
      await refresh();
      return;
    }
    const done = ev.target.closest(".pf-video-note-done");
    if (done) {
      await fetch(`/api/video-review-comments/${done.getAttribute("data-id")}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: done.getAttribute("data-status") }),
      });
      await refresh();
    }
  });

  paintTime();
  refresh().catch(() => {});
})();
