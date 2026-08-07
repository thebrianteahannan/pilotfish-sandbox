/* Sandbox Web UI: highlight XML / XSLT in <pre.viewer>, #xslt-code, #xslt-view, etc.
 * Load after highlight.js; before or after app.js. Observes text updates automatically.
 */
(function () {
  const SELECTORS = [
    "#xslt-code",
    "#xslt-view",
    "pre.xslt-source",
    "pre.viewer",
    "pre.snip-raw",
    "#snip-view",
    "#kickout-view",
    "#approved-view",
    "#incomplete-view",
    "#denied-view",
    "#pended-view",
    "#matched-view",
    "#exception-view",
    "#val-view",
    "pre.log",
  ].join(",");

  function ensureCode(el) {
    if (!el) return null;
    if (el.tagName === "CODE") return el;
    if (el.matches && el.matches("pre.xslt-source")) {
      return el.querySelector("code") || el;
    }
    let code = el.querySelector(":scope > code");
    if (!code) {
      code = document.createElement("code");
      code.className = "language-xml";
      while (el.firstChild) code.appendChild(el.firstChild);
      el.appendChild(code);
      el.classList.add("hljs-host");
    }
    return code;
  }

  function highlightEl(el) {
    if (!el || !window.hljs) return;
    const code = ensureCode(el);
    if (!code) return;
    const text = code.textContent || "";
    if (!text.trim() || text.trim() === "(none yet)" || text.trim() === "(empty)") {
      code.classList.remove("hljs");
      return;
    }
    code.classList.add("language-xml");
    delete code.dataset.highlighted;
    try {
      window.hljs.highlightElement(code);
    } catch (_) {
      /* leave plain text */
    }
  }

  function scan(root) {
    (root || document).querySelectorAll(SELECTORS).forEach(highlightEl);
  }

  function watch(el) {
    if (!el || el.dataset.hlWatched === "1") return;
    el.dataset.hlWatched = "1";
    const obs = new MutationObserver(() => {
      window.requestAnimationFrame(() => highlightEl(el));
    });
    obs.observe(el, { childList: true, characterData: true, subtree: true });
  }

  function boot() {
    if (!window.hljs) return;
    scan(document);
    document.querySelectorAll(SELECTORS).forEach(watch);
    const bodyObs = new MutationObserver((muts) => {
      muts.forEach((m) => {
        m.addedNodes.forEach((n) => {
          if (n.nodeType !== 1) return;
          if (n.matches && n.matches(SELECTORS)) {
            watch(n);
            highlightEl(n);
          }
          n.querySelectorAll?.(SELECTORS).forEach((el) => {
            watch(el);
            highlightEl(el);
          });
        });
      });
    });
    bodyObs.observe(document.body, { childList: true, subtree: true });
  }

  window.CodeHighlight = {
    xml(el, text) {
      if (!el) return;
      const code = ensureCode(el);
      if (!code) return;
      code.textContent = text == null ? "" : String(text);
      highlightEl(el.tagName === "CODE" ? el.parentElement || el : el);
    },
    refresh: () => scan(document),
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
