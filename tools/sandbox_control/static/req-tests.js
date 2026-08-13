(function () {
  function side(raw) {
    if (raw && typeof raw === "object") return { label: raw.label || raw.path || "", text: raw.text || "" };
    return { label: raw || "", text: "" };
  }

  function pane(title, label, text, esc) {
    if (!label && !text) return "";
    return `<div><p class="tmeta"><strong>${esc(title)}</strong>${label ? ` <code>${esc(label)}</code>` : ""}</p>${text ? `<pre class="tev">${esc(text)}</pre>` : ""}</div>`;
  }

  function isCode(label) {
    return /\.(xslt|xsl)(\.bak-req)?$/i.test(String(label || ""));
  }

  function looksFinal(text) {
    return /^(MSH|BHS|ISA|ST\*|UNH)[|^]/m.test(String(text || ""));
  }

  function html(tests, esc) {
    const head = `<p class="${tests.ok ? "ok" : "bad"}"><strong>${tests.ok ? "All tests passed" : "Tests failed"}</strong></p>` +
      (tests.note ? `<p class="muted">${esc(tests.note)}</p>` : "");
    return head + (tests.items || []).map((i, n) => {
      const inn = side(i.input);
      const out = side(i.output);
      const inText = inn.text || i.input_text || i.before || "";
      const outText = out.text || i.output_text || i.after || "";
      const hide = isCode(inn.label) && isCode(out.label) && !looksFinal(outText);
      const pair = !hide && (inn.label || out.label || inText || outText)
        ? `<div class="tpair">${pane("Input", inn.label, inText, esc)}${pane("Output", out.label, outText, esc)}</div>`
        : "";
      const ev = (i.evidence || []).filter((row) => row && !String(row).startsWith("IN1."));
      const extra = [];
      if (ev.length) extra.push(`<pre class="tev">${esc(ev.join("\n"))}</pre>`);
      if (!pair && !extra.length && i.detail) extra.push(`<pre class="tev">${esc(i.detail)}</pre>`);
      return `<div class="trow"><div class="row"><span>${n + 1}. ${esc(i.name)}</span><strong class="${i.ok ? "ok" : "bad"}">${i.ok ? "PASS" : "FAIL"}</strong></div>${pair}${extra.join("")}</div>`;
    }).join("");
  }
  window.pfTests = { html };
})();
