(function () {
  const box = document.getElementById("file-view");
  const nameEl = document.getElementById("file-view-name");
  const codeEl = document.getElementById("file-view-code");
  const beforeBtn = document.getElementById("file-view-before");
  const afterBtn = document.getElementById("file-view-after");
  if (!box || !codeEl) return;

  let rel = "";
  let side = "after";

  function esc(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  function colorXml(raw) {
    const parts = [];
    const re = /<!--[\s\S]*?-->|<[^>]+>|[^<]+/g;
    let m;
    while ((m = re.exec(raw))) {
      const chunk = m[0];
      if (chunk.startsWith("<!--")) {
        parts.push(`<span class="hl-com">${esc(chunk)}</span>`);
      } else if (chunk.startsWith("<")) {
        const inner = esc(chunk).replace(/(&lt;\/?)([\w:.-]+)([\s\S]*?)(\/?&gt;)/, (_, a, n, rest, z) => {
          rest = rest.replace(/([\w:.-]+)(=)(&quot;[\s\S]*?&quot;)/g, '<span class="hl-attr">$1</span>$2<span class="hl-str">$3</span>');
          return `<span class="hl-punct">${a}</span><span class="hl-tag">${n}</span>${rest}<span class="hl-punct">${z}</span>`;
        });
        parts.push(inner);
      } else {
        parts.push(esc(chunk));
      }
    }
    return parts.join("");
  }

  async function load() {
    const st = (window.pfHub && window.pfHub.read()) || {};
    const slug = st.client || "";
    const reqId = st.request || "";
    if (!slug || !reqId || !rel) return;
    const url = `/api/clients/${encodeURIComponent(slug)}/requests/${encodeURIComponent(reqId)}/file?path=${encodeURIComponent(rel)}&side=${encodeURIComponent(side)}`;
    const resp = await fetch(url, { cache: "no-store" });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) {
      codeEl.textContent = data.error || "Could not open file";
      return;
    }
    nameEl.textContent = data.path || rel;
    nameEl.title = data.path || rel;
    beforeBtn.hidden = !data.has_before;
    beforeBtn.classList.toggle("is-on", data.side === "before");
    afterBtn.classList.toggle("is-on", data.side !== "before");
    const changed = new Set(data.changed || []);
    const lines = String(data.text || "").split("\n");
    if (lines.length && lines[lines.length - 1] === "") lines.pop();
    const paint = data.language === "xml" ? colorXml : esc;
    const kind = data.side === "before" ? "is-del" : "is-add";
    codeEl.innerHTML = `<table class="file-view-lines">${lines
      .map((ln, i) => {
        const n = i + 1;
        const cls = changed.has(n) ? kind : "";
        return `<tr class="${cls}"><td class="num">${n}</td><td class="src">${paint(ln) || " "}</td></tr>`;
      })
      .join("")}</table>`;
    const hit = codeEl.querySelector("tr.is-add, tr.is-del");
    if (hit) hit.scrollIntoView({ block: "center" });
  }

  function openView(path, which) {
    rel = path;
    side = which || "after";
    box.hidden = false;
    load();
  }

  function close() {
    box.hidden = true;
  }

  document.addEventListener("click", (ev) => {
    const btn = ev.target.closest(".diff-file-open");
    if (btn && btn.dataset.rel) {
      ev.preventDefault();
      openView(btn.dataset.rel, "after");
      return;
    }
    if (ev.target === box) close();
  });
  document.getElementById("file-view-close").addEventListener("click", close);
  beforeBtn.addEventListener("click", () => {
    side = "before";
    load();
  });
  afterBtn.addEventListener("click", () => {
    side = "after";
    load();
  });
  document.addEventListener("keydown", (ev) => {
    if (ev.key === "Escape" && !box.hidden) close();
  });
})();
