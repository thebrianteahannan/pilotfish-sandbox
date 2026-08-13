/* Sandbox Web UI: highlight XML / XSLT in <pre.viewer>, #xslt-code, #xslt-view, etc.
 * Load after highlight.js; before or after app.js. Observes text updates automatically.
 *
 * Avoids an infinite MutationObserver ↔ hljs.highlightElement feedback loop by
 * fingerprinting textContent and disconnecting the observer while highlighting.
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

  const OBSERVE_OPTS = { childList: true, characterData: true, subtree: true };

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
      delete code.dataset.hlSrc;
      return;
    }
    // Skip re-entry only when span markup is still present. Setting textContent
    // keeps .hljs + hlSrc but destroys spans — must re-highlight in that case.
    if (
      code.dataset.hlSrc === text &&
      code.classList.contains("hljs") &&
      code.childElementCount > 0
    ) {
      return;
    }

    code.classList.add("language-xml");
    delete code.dataset.highlighted;

    const obs = el.__hlObs;
    if (obs) obs.disconnect();
    try {
      window.hljs.highlightElement(code);
      code.dataset.hlSrc = text;
    } catch (_) {
      /* leave plain text */
    } finally {
      if (obs) obs.observe(el, OBSERVE_OPTS);
    }
  }

  function scan(root) {
    (root || document).querySelectorAll(SELECTORS).forEach(highlightEl);
  }

  function watch(el) {
    if (!el || el.dataset.hlWatched === "1") return;
    el.dataset.hlWatched = "1";
    let scheduled = false;
    const obs = new MutationObserver(() => {
      if (scheduled) return;
      scheduled = true;
      window.requestAnimationFrame(() => {
        scheduled = false;
        highlightEl(el);
      });
    });
    el.__hlObs = obs;
    obs.observe(el, OBSERVE_OPTS);
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
      delete code.dataset.hlSrc;
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
