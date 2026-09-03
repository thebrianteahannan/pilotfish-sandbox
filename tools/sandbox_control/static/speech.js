(function () {
  const $ = (id) => document.getElementById(id);
  const esc = (s) =>
    String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  let recorder = null;
  let chunks = [];
  let stream = null;
  let lastHeard = "";

  function status(msg, isErr) {
    const el = $("speech-status");
    if (!el) return;
    el.textContent = msg || "";
    el.classList.toggle("err", !!isErr);
  }

  function setRecording(on) {
    const start = $("speech-start");
    const stop = $("speech-stop");
    if (start) start.disabled = on || !$("speech-word").value.trim();
    if (stop) stop.disabled = !on;
    if (stop) stop.classList.toggle("is-on", on);
  }

  function playUrl(url) {
    const audio = $("speech-audio");
    if (!audio || !url) return;
    audio.src = url;
    audio.hidden = false;
    audio.play().catch(() => {});
  }

  async function load() {
    const list = $("speech-terms");
    if (!list) return;
    try {
      const resp = await fetch("/api/speech", { cache: "no-store" });
      const data = await resp.json();
      const terms = data.terms || [];
      $("speech-total").textContent = terms.length ? `${terms.length} saved` : "";
      list.innerHTML =
        terms
          .map(
            (t) =>
              `<button type="button" class="row speech-term" data-word="${esc(t.word)}" data-speak="${esc(t.speak)}">` +
              `<span class="path">${esc(t.word)}</span><span>${esc(t.speak)}</span></button>`
          )
          .join("") || '<p class="empty">No words saved yet.</p>';
      list.querySelectorAll(".speech-term").forEach((btn) => {
        btn.addEventListener("click", () => {
          $("speech-word").value = btn.dataset.word || "";
          $("speech-speak").value = btn.dataset.speak || "";
          lastHeard = "";
          $("speech-heard").textContent = "Saved saying — play it, or record again to retrain.";
          $("speech-result").hidden = false;
          setRecording(false);
        });
      });
    } catch (err) {
      list.innerHTML = '<p class="empty">Could not load saved words.</p>';
    }
    setRecording(false);
  }

  async function hearBlob(blob) {
    const word = $("speech-word").value.trim();
    status("Listening… turning that into how the robot should say it.");
    const body = new FormData();
    body.append("word", word);
    body.append("audio", blob, "clip.webm");
    const resp = await fetch("/api/speech/hear", { method: "POST", body });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok || !data.ok) {
      status(data.error || "Could not hear that take.", true);
      return;
    }
    lastHeard = data.heard || "";
    $("speech-heard").textContent = data.current
      ? `I heard “${data.heard}”. Saved today as “${data.current}”.`
      : `I heard “${data.heard}”.`;
    $("speech-speak").value = data.speak || "";
    $("speech-result").hidden = false;
    status("Here is how I would say it. Confirm if that is right, or record again.");
    playUrl(data.preview);
  }

  async function startRec() {
    const word = $("speech-word").value.trim();
    if (!word) {
      status("Type the word as it should appear in the transcript.", true);
      return;
    }
    try {
      stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch (err) {
      status("Allow the microphone, then try Start speaking again.", true);
      return;
    }
    chunks = [];
    const mime = MediaRecorder.isTypeSupported("audio/webm;codecs=opus")
      ? "audio/webm;codecs=opus"
      : MediaRecorder.isTypeSupported("audio/mp4")
        ? "audio/mp4"
        : "";
    recorder = mime ? new MediaRecorder(stream, { mimeType: mime }) : new MediaRecorder(stream);
    recorder.ondataavailable = (ev) => {
      if (ev.data && ev.data.size) chunks.push(ev.data);
    };
    recorder.onstop = () => {
      stream.getTracks().forEach((t) => t.stop());
      stream = null;
      const blob = new Blob(chunks, { type: recorder.mimeType || "audio/webm" });
      recorder = null;
      setRecording(false);
      hearBlob(blob);
    };
    recorder.start();
    setRecording(true);
    status("Speaking now — say the word, then hit Stop.");
  }

  function stopRec() {
    if (recorder && recorder.state !== "inactive") recorder.stop();
    else setRecording(false);
  }

  async function playSpeak() {
    const speak = $("speech-speak").value.trim();
    if (!speak) return;
    status("Playing how the robot would say it…");
    const resp = await fetch("/api/speech/preview", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ speak }),
    });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok || !data.ok) {
      status(data.error || "Could not play that.", true);
      return;
    }
    playUrl(data.preview);
  }

  async function confirm() {
    const word = $("speech-word").value.trim();
    const speak = $("speech-speak").value.trim();
    const resp = await fetch("/api/speech/save", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ word, speak, heard: lastHeard }),
    });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok || !data.ok) {
      status(data.error || "Could not save.", true);
      return;
    }
    status(`Saved. Videos will say “${speak}” for ${word}. Record another word, or re-export a demo video.`);
    await load();
  }

  const word = $("speech-word");
  if (word) word.addEventListener("input", () => setRecording(false));
  const start = $("speech-start");
  if (start) start.addEventListener("click", startRec);
  const stop = $("speech-stop");
  if (stop) stop.addEventListener("click", stopRec);
  const play = $("speech-play");
  if (play) play.addEventListener("click", playSpeak);
  const ok = $("speech-confirm");
  if (ok) ok.addEventListener("click", confirm);
  const again = $("speech-again");
  if (again) again.addEventListener("click", startRec);

  window.pfSpeech = { load };
  if (window.pfHub && window.pfHub.read().tab === "speech") load();
})();
