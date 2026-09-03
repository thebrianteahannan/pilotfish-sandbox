(function () {
  const $ = (id) => document.getElementById(id);
  const esc = (s) => String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  let timer = null;

  function paint(data) {
    const st = data || {};
    const pull = st.pull || {};
    const total = $("llm-total");
    const status = $("llm-status");
    const models = $("llm-models");
    if (total) {
      total.textContent = pull.busy
        ? "Pulling…"
        : st.ok
          ? st.model_present
            ? `${st.model} ready`
            : "Ollama up, model missing"
          : "Ollama not running";
    }
    if (status) {
      const bits = [
        `<div class="row"><span>Service</span><span class="badge ${st.ok ? "on" : "err"}">${st.ok ? "up" : "down"}</span></div>`,
        `<div class="row"><span>URL</span><code>${esc(st.url)}</code></div>`,
        `<div class="row"><span>Default model</span><code>${esc(st.model)}</code></div>`,
        st.error && !st.model_present ? `<p class="hint">${esc(st.error)}</p>` : "",
        pull.busy ? `<p class="hint">Pull in progress…</p>` : "",
        pull.error ? `<p class="hint">${esc(pull.error)}</p>` : "",
        st.reply ? `<p class="hint">Ping: ${esc(st.reply)}</p>` : "",
      ];
      status.innerHTML = bits.filter(Boolean).join("");
    }
    if (models) {
      const list = st.models || [];
      models.innerHTML =
        list
          .map((m) => {
            const name = typeof m === "string" ? m : m.name;
            const gb = typeof m === "object" && m.size_gb ? `${m.size_gb} GB` : "";
            const on = name === st.model || (name && name.startsWith(st.model + ":"));
            return `<div class="row"><span class="path">${esc(name)}</span><span>${esc(gb)}</span><span class="badge ${on ? "on" : "off"}">${on ? "default" : ""}</span></div>`;
          })
          .join("") || '<p class="empty">No models pulled yet.</p>';
    }
    const start = $("llm-start");
    if (start) {
      start.disabled = !!st.ok;
      start.textContent = st.ok ? "Running" : "Start Ollama";
    }
    if (pull.busy) {
      if (!timer) timer = setInterval(load, 2500);
    } else if (timer) {
      clearInterval(timer);
      timer = null;
    }
  }

  async function load() {
    try {
      const resp = await fetch("/api/llm", { cache: "no-store" });
      paint(await resp.json());
    } catch (err) {
      paint({ ok: false, error: "Could not reach the hub.", models: [], pull: {} });
    }
  }

  async function post(url, extra) {
    const resp = await fetch(url, { method: "POST" });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok && data.error) alert(data.error);
    paint(Object.assign({}, data, extra || {}));
    await load();
  }

  const refresh = $("llm-refresh");
  if (refresh) refresh.addEventListener("click", load);
  const start = $("llm-start");
  if (start) start.addEventListener("click", () => post("/api/llm/start"));
  const pull = $("llm-pull");
  if (pull) pull.addEventListener("click", () => post("/api/llm/pull"));
  const ping = $("llm-ping");
  if (ping) ping.addEventListener("click", async () => {
    const resp = await fetch("/api/llm/ping", { method: "POST" });
    const data = await resp.json().catch(() => ({}));
    const cur = await fetch("/api/llm", { cache: "no-store" }).then((r) => r.json()).catch(() => ({}));
    paint(Object.assign({}, cur, { reply: data.reply || data.error || "" }));
  });

  window.pfOllama = { load };
  if (window.pfHub && window.pfHub.read().tab === "ollama") load();
})();
