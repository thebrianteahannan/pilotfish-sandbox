(function () {
  const $ = (id) => document.getElementById(id);
  const listEl = $("client-list");
  const filter = $("client-filter");
  const listView = $("client-list-view");
  const detailView = $("client-detail-view");
  const detailEl = $("client-detail");
  if (!listEl) return;

  let rows = [], pipeline = {}, job = {}, selected = "", selectedReq = "", detail = null;
  let timer = null, q = "", draft = emptyDraft(), ocrBusy = false, viewSig = "", planOpen = null, commentsOpen = false, newOpen = null, histTab = "active";
  const regrOpen = new Set();
  const regrScroll = {};
  let paintGen = 0;

  function regrRoots() {
    return [$("req-regr-slot")].filter(Boolean);
  }

  function snapRegrUi() {
    const seen = {};
    const scrolls = {};
    regrRoots().forEach((root) => {
      root.querySelectorAll("details[data-regr-key]").forEach((el) => {
        const k = el.getAttribute("data-regr-key");
        if (k) seen[k] = !!(seen[k] || el.open);
      });
      root.querySelectorAll("[data-regr-scroll]").forEach((el) => {
        const k = el.getAttribute("data-regr-scroll");
        if (!k) return;
        const cur = scrolls[k] || { x: 0, y: 0 };
        scrolls[k] = { x: Math.max(cur.x, el.scrollLeft), y: Math.max(cur.y, el.scrollTop) };
      });
    });
    Object.keys(seen).forEach((k) => {
      if (seen[k]) regrOpen.add(k);
      else regrOpen.delete(k);
    });
    Object.keys(scrolls).forEach((k) => { regrScroll[k] = scrolls[k]; });
  }

  function restoreRegrUi() {
    regrRoots().forEach((root) => {
      root.querySelectorAll("details[data-regr-key]").forEach((el) => {
        const k = el.getAttribute("data-regr-key");
        if (k && regrOpen.has(k)) el.open = true;
      });
      root.querySelectorAll("[data-regr-scroll]").forEach((el) => {
        const k = el.getAttribute("data-regr-scroll");
        const pos = k && regrScroll[k];
        if (pos) {
          el.scrollLeft = pos.x;
          el.scrollTop = pos.y;
        }
      });
    });
  }

  function emptyDraft() { return { from: "", subject: "", received_at: "", email: "", comments: "", screenshots: [], previews: [], status: "" }; }

  function esc(s) {
    return String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  }

  function mdInline(s) {
    return esc(s).replace(/`([^`]+)`/g, "<code>$1</code>");
  }

  function planHtml(md) {
    if (!md) return "";
    const lines = String(md).replace(/\r\n/g, "\n").split("\n");
    const out = [];
    let i = 0;
    while (i < lines.length) {
      const line = lines[i];
      if (line.startsWith("```")) {
        const buf = [];
        i += 1;
        while (i < lines.length && !lines[i].startsWith("```")) {
          buf.push(lines[i]);
          i += 1;
        }
        if (i < lines.length) i += 1;
        out.push(`<pre class="plan-code">${esc(buf.join("\n"))}</pre>`);
        continue;
      }
      if (line.startsWith("# ")) {
        out.push(`<h3 class="plan-title">${mdInline(line.slice(2))}</h3>`);
        i += 1;
        continue;
      }
      if (line.startsWith("## ")) {
        out.push(`<h3>${mdInline(line.slice(3))}</h3>`);
        i += 1;
        continue;
      }
      if (/^\s*-\s/.test(line)) {
        const items = [];
        while (i < lines.length && /^\s*-\s/.test(lines[i])) {
          let item = mdInline(lines[i].replace(/^\s*-\s/, ""));
          i += 1;
          const notes = [];
          while (i < lines.length && lines[i] && !/^\s*-\s/.test(lines[i]) && !lines[i].startsWith("#") && !lines[i].startsWith("```") && /^\s+/.test(lines[i])) {
            notes.push(mdInline(lines[i].trim()));
            i += 1;
          }
          items.push(`<li>${item}${notes.map((n) => `<div class="plan-note">${n}</div>`).join("")}</li>`);
        }
        out.push(`<ul>${items.join("")}</ul>`);
        continue;
      }
      if (!line.trim()) {
        i += 1;
        continue;
      }
      const para = [line];
      i += 1;
      while (i < lines.length && lines[i].trim() && !lines[i].startsWith("#") && !lines[i].startsWith("```") && !/^\s*-\s/.test(lines[i])) {
        para.push(lines[i]);
        i += 1;
      }
      out.push(`<p>${mdInline(para.join(" "))}</p>`);
    }
    return `<div class="plan-doc">${out.join("")}</div>`;
  }

  function remember(part) { if (window.pfHub) window.pfHub.write(part); }

  async function paintBanner() {
    const gen = ++paintGen;
    snapRegrUi();
    const banner = $("job-banner");
    const live = $("regr-live");
    if (!banner) return;
    const err = (job && job.error) || (pipeline && pipeline.error) || "";
    const rg = { ...((pipeline && pipeline.regression) || {}) };
    try {
      const extra = await fetch("/static/regr-live.json?t=" + Date.now(), { cache: "no-store" });
      if (extra.ok) Object.assign(rg, await extra.json());
    } catch (err) {}
    try {
      const timing = await fetch("/static/regr-timing.json?t=" + Date.now(), { cache: "no-store" });
      if (timing.ok) {
        const t = await timing.json();
        if (t.capture_sec) {
          rg.capture_sec = t.capture_sec;
          if (!rg.expected_sec) rg.expected_sec = t.capture_sec;
          window.pfRegrCaptureSec = t.capture_sec;
        }
      }
    } catch (err) {}
    try {
      const score = await fetch("/static/regr-score.json?t=" + Date.now(), { cache: "no-store" });
      if (score.ok) {
        const s = await score.json();
        if (s.passed || s.failed || s.ignored) {
          rg.passed = s.passed || [];
          rg.failed = s.failed || [];
          rg.ignored = s.ignored || [];
        }
      }
    } catch (err) {}
    const testsHere = pipeline && pipeline.busy && pipeline.kind === "tests" && pipeline.request_id === selectedReq;
    const msg = testsHere
      ? err
      : (pipeline && pipeline.busy && (pipeline.message || "Processing client request…")) || (job && job.busy && (job.message || "")) || err;
    const showLive = !!(pipeline && pipeline.kind === "regression" && (rg.busy || pipeline.busy));
    const liveHtml = showLive
      ? regrLive({
          ...rg,
          busy: rg.busy || pipeline.busy,
          message: rg.message || pipeline.message,
          capture: rg.capture != null ? rg.capture : (pipeline.regression && pipeline.regression.capture),
          error: rg.error || err,
          wait_sec: rg.wait_sec || (pipeline.regression && pipeline.regression.wait_sec),
          started_at: rg.started_at || (pipeline.regression && pipeline.regression.started_at),
          capture_sec: rg.capture_sec || window.pfRegrCaptureSec,
        })
      : "";
    if (gen !== paintGen) return;
    snapRegrUi();
    if (live) {
      live.hidden = true;
      live.innerHTML = "";
    }
    if ($("req-regr-slot")) $("req-regr-slot").innerHTML = liveHtml;
    restoreRegrUi();
    banner.hidden = !msg || showLive;
    if (msg && !showLive) {
      banner.textContent = err || msg;
      banner.classList.toggle("is-err", !!err);
    }
  }

  const statusLabel = (s) => ({ planned: "plan ready", processing: "working", tested: "review", ready: "ready to deploy", applied: "deployed" }[s] || s || "saved");
  const busy = () => !!(job && job.busy) || !!(pipeline && pipeline.busy);

  function renderList() {
    const shown = rows.filter((c) => {
      if (!q) return true;
      return `${c.title} ${c.name} ${c.slug} ${c.eip_version || ""}`.toLowerCase().includes(q);
    });
    $("client-count").textContent = `${shown.length} client${shown.length === 1 ? "" : "s"}`;
    if (!shown.length) { listEl.innerHTML = '<p class="empty">No clients under Clients/ (excluding Demos).</p>'; return; }
    listEl.innerHTML = shown
      .map((c) => {
        const urls = c.local_url
          ? `<div class="urls"><a href="${esc(c.local_url)}" target="_blank" rel="noopener">Local</a>` +
            (c.lan_url ? `<a href="${esc(c.lan_url)}" target="_blank" rel="noopener">LAN</a>` : "") +
            (c.webui_port ? ` :${c.webui_port}` : "") +
            `</div>`
          : "";
        const latest = c.latest_request
          ? `<div class="muted">Latest: ${esc(c.latest_request.subject || c.latest_request.id)} · ${esc(statusLabel(c.latest_request.status))}</div>`
          : '<div class="muted">No requests yet</div>';
        return `<article class="card" data-cslug="${esc(c.slug)}">
          <div>
            <h3>${esc(c.title)}</h3>
            <code>${esc(c.path)}</code>
            <div class="muted">eiPlatform ${c.eip_version ? esc(c.eip_version) : "not tagged"}</div>
            ${urls}
            ${latest}
          </div>
          <div>
            <div style="text-align:right;margin-bottom:0.4rem">
              <span class="badge ${c.running ? "on" : "off"}">${c.running ? "Running" : "Stopped"}</span>
              <span class="badge off">${c.request_count || 0} request${c.request_count === 1 ? "" : "s"}</span>
            </div>
            <div class="actions">
              <button type="button" class="eic-open" data-cact="eiconsole" title="Open eiConsole" aria-label="Open eiConsole"></button>
              <button type="button" class="btn btn-primary" data-cact="open">Requests</button>
              <button type="button" class="btn" data-cact="manage">Manage</button>
              <button type="button" class="btn" data-cact="start" ${busy() || c.running || !c.has_sandbox ? "disabled" : ""}>Start</button>
              <button type="button" class="btn btn-quiet" data-cact="stop" ${busy() || !c.running ? "disabled" : ""}>Stop</button>
            </div>
          </div>
        </article>`;
      })
      .join("");
  }

  function regrFeedLabel(row) {
    return row && typeof row === "object" ? (row.title || row.id || "") : String(row || "");
  }

  function regrWhyCell(r, ch, e, withExplain) {
    e = e || esc;
    if (r.error && !ch) return e(r.error);
    if (!ch) return e("diff");
    if (ch.kind === "missing" && !(withExplain && ch.explain)) return e("missing this run");
    if (ch.kind === "extra" && !(withExplain && ch.explain)) return e("new this run");
    const labelWhy = ch.kind === "ignored" ? (ch.reason || "ignored") : "changed";
    const bits = (ch.lines || []).map((ln) => String(ln).replace(/\n$/, "")).filter((ln) => {
      if (ln.startsWith("+++") || ln.startsWith("---") || ln.startsWith("@@")) return false;
      return ln.startsWith("+") || ln.startsWith("-");
    });
    const prose = withExplain && ch.explain ? `<p class="regr-explain">${e(ch.explain)}</p>` : "";
    if (!bits.length) return prose || e(ch.kind === "missing" ? "missing this run" : ch.kind === "extra" ? "new this run" : labelWhy);
    const head = withExplain && ch.explain ? "" : `<div>${e(labelWhy)}</div>`;
    return `${prose}${head}${regrDiffBody({ kind: "changed", lines: bits }, "")}`;
  }

  function regrFailTable(feeds, e, withExplain) {
    e = e || esc;
    const rows = [];
    (feeds || []).forEach((r) => {
      const feed = regrFeedLabel(r);
      const changes = r.changes || [];
      if (!changes.length) rows.push(`<tr><td>${e(feed)}</td><td></td><td>${regrWhyCell(r, null, e, withExplain)}</td></tr>`);
      else changes.forEach((ch) => {
        rows.push(`<tr><td>${e(feed)}</td><td><code>${e(ch.file || "")}</code></td><td>${regrWhyCell(r, ch, e, withExplain)}</td></tr>`);
      });
    });
    if (!rows.length) return '<p class="muted">None yet</p>';
    return `<table class="regr-fail-table"><thead><tr><th>Feed</th><th>File</th><th>Why</th></tr></thead><tbody>${rows.join("")}</tbody></table>`;
  }

  window.pfRegrScoreHtml = function (job, escapeHtml) {
    const e = escapeHtml || esc;
    const pass = job.passed || [];
    const fail = job.failed || [];
    const ign = job.ignored || [];
    if (!pass.length && !fail.length && !ign.length) return "";
    const chips = pass.length
      ? pass.map((r) => `<span class="regr-chip">${e(regrFeedLabel(r))}</span>`).join("")
      : '<span class="muted">None yet</span>';
    return `<div class="regr-score">
      <section class="regr-fail-block"><h4 class="bad">Failed (${e(String(fail.length))})</h4>${regrFailTable(fail, e)}</section>
      ${ign.length ? `<details class="fold regr-fold"><summary>Ignored differences (${e(String(ign.length))})</summary>${regrFailTable(ign, e)}</details>` : ""}
      <details class="fold regr-fold"><summary class="ok">Passed (${e(String(pass.length))})</summary><div class="regr-pass-chips">${chips}</div></details>
    </div>`;
  };

  function regrElapsed(job) {
    let n = Number(job.wait_sec) || 0;
    const started = Date.parse(job.started_at || "") || 0;
    if (started) n = Math.max(n, Math.max(0, Math.round((Date.now() - started) / 1000)));
    const msg = String(job.message || "");
    const hit = msg.match(/\((\d+)\s*s\)\s*$/i);
    if (hit) n = Math.max(n, Number(hit[1]));
    return n;
  }

  function regrPct(job, elapsed) {
    const cap = Number(job.capture_sec || job.expected_sec || window.pfRegrCaptureSec) || 1031;
    const raw = cap ? Math.round((elapsed / cap) * 100) : 0;
    const pct = Math.min(100, elapsed > 0 ? Math.max(1, raw) : 0);
    const fmt = (s) => {
      s = Math.max(0, Math.round(Number(s) || 0));
      const m = Math.floor(s / 60);
      const r = s % 60;
      return m ? `${m}m ${String(r).padStart(2, "0")}s` : `${r}s`;
    };
    const over = elapsed > cap;
    const text = over
      ? `${raw}% · elapsed ${fmt(elapsed)} of last capture ${fmt(cap)} · still running`
      : `${pct}% · elapsed ${fmt(elapsed)} of last capture ${fmt(cap)} · ${fmt(cap - elapsed)} left`;
    return { pct, text };
  }

  function regrLive(job) {
    if (!job || !job.busy) return "";
    const busy = !!job.busy;
    const step = Number(job.step) || 0;
    const total = Number(job.step_total) || 0;
    const elapsed = regrElapsed(job);
    const log = (job.log || []).slice(-12).map((l) => `<li>${esc(l)}</li>`).join("");
    const lists = window.pfRegrLiveLists ? window.pfRegrLiveLists(job, esc) : "";
    const pickedN = Number(job.picked_n) || 0;
    const totalIn = Number(job.step_total) || total;
    const eta = regrPct({ ...job, capture_sec: job.capture_sec || window.pfRegrCaptureSec || 0 }, elapsed);
    const score = window.pfRegrScoreHtml ? window.pfRegrScoreHtml(job, esc) : "";
    return `<div class="regr-progress${job.error ? " is-err" : ""}">
      <p class="video-phase">${esc(busy ? (job.capture ? "Capturing baseline" : "Running regression") : "Regression")}</p>
      <p class="video-msg">${esc(job.message || (busy ? "Working…" : ""))}</p>
      ${busy ? `<div class="regr-bar-row"><strong class="regr-pct">${esc(String(eta.pct))}%</strong><progress max="100" value="${esc(String(eta.pct))}"></progress></div>
      <p class="muted">${esc(eta.text)}</p>
      <p class="muted">${esc(String(step))}/${esc(String(total || "?"))} feeds · this drop ${esc(String(pickedN || 0))}/${esc(String(job.inbound_n != null ? (Number(job.inbound_n)+pickedN) : "?"))} inbound · ${esc(String(job.output_n || job.files || 0))} ADT/DFT</p>` : ""}
      ${score}
      ${lists}
      ${job.error ? `<p class="video-err">${esc(job.error)}</p>` : ""}
      ${log ? `<ul class="video-log">${log}</ul>` : ""}
    </div>`;
  }

  function regrKind(kind) {
    if (kind === "missing") return "missing this run";
    if (kind === "extra") return "new this run";
    return "changed";
  }

  function regrDiffBody(ch, feedId) {
    const lines = ch.lines || [];
    if (!lines.length) return '<p class="muted">No line detail.</p>';
    if (ch.kind === "missing" || ch.kind === "extra") return `<p>${esc(lines.join(" "))}</p>`;
    const body = lines
      .map((line) => {
        const raw = String(line);
        let cls = "";
        if (raw.startsWith("+") && !raw.startsWith("+++")) cls = "diff_add";
        else if (raw.startsWith("-") && !raw.startsWith("---")) cls = "diff_sub";
        return `<span class="${cls}">${esc(raw)}</span>`;
      })
      .join("\n");
    return `<pre class="diff-view regr-diff-pre">${body}</pre>`;
  }

  function regrFeed(u, cls) {
    const changes = u.changes || [];
    const n = changes.length || Number(u.diffs) || 0;
    const missing = changes.length && changes.every((c) => c.kind === "missing");
    const hint = missing
      ? "no ADT/DFT this run"
      : `${n} file(s)`;
    const files = changes
      .map((ch) => `<details class="diff-file regr-diff" data-regr-key="${esc("file:" + (u.id || "") + ":" + (ch.file || ""))}" open>
        <summary class="diff-name"><span class="diff-path">${esc(ch.file || u.id)}</span> <span class="muted">${esc(regrKind(ch.kind))}</span></summary>
        ${regrDiffBody(ch, u.id)}
      </details>`)
      .join("");
    const base = (u.baseline_files || []).join(", ");
    const last = (u.last_files || []).join(", ");
    const extra = u.error ? `<p class="bad">${esc(u.error)}</p>` : "";
    const meta = `<p class="muted">Baseline: ${esc(base || "none")} · This run: ${esc(last || "none")}</p>`;
    return `<details class="db-client cc-client regr-feed" data-regr-key="${esc("feed:" + (u.id || ""))}">
      <summary class="${esc(cls || "")}"><strong>${esc(u.id)}</strong> <span class="muted">${esc(hint)}${u.error ? " · " + esc(u.error) : ""}</span></summary>
      ${extra}${meta}${files || `<p class="muted">${esc(String(n))} diff(s)</p>`}
    </details>`;
  }

  function regrReport(rg) {
    if (!rg) return "";
    const un = rg.unexpected || [];
    const inc = rg.incomplete || [];
    const ex = rg.expected_changed || [];
    const ign = rg.ignored || [];
    const ok = !!rg.ok;
    const head = ok
      ? "Only this feature moved (or nothing else did)."
      : inc.length && !un.length
        ? "This run did not finish collecting ADT/DFT. Missing or extra files here are not field changes — Re-run Regression."
        : "Unexpected feeds changed — those should not have moved.";
    return `<div class="regr-report${ok ? " is-ok" : ""}" id="req-regression-report">
      <p>${head}</p>
      ${inc.length ? `<p class="muted">Incomplete collection</p>${regrFailTable(inc)}` : ""}
      ${un.length ? `<p class="muted">Unexpected</p>${regrFailTable(un)}` : ""}
      ${ex.length ? `<details class="fold regr-fold"><summary>Expected for this feature (${esc(String(ex.length))})</summary>${regrFailTable(ex, esc, true)}</details>` : ""}
      ${ign.length ? `<details class="fold regr-fold"><summary>Ignored differences (${esc(String(ign.length))})</summary><p class="muted">FT1 order and PV1 ordering physician can move without failing the run.</p>${regrFailTable(ign)}</details>` : ""}
      <details class="fold regr-fold"><summary>${esc(String(rg.clean || 0))} feed(s) unchanged</summary><p class="muted">These matched baseline.</p></details>
      ${coverageBlock(rg.coverage)}
    </div>`;
  }

  function coverageBlock(cov) {
    if (!cov || !(cov.categories || []).length) return "";
    const cats = (cov.categories || [])
      .map((c) => `<li><strong>${esc(c.label)}</strong> ${esc(String(c.hit))}/${esc(String(c.total))} (${esc(String(c.pct))}%)</li>`)
      .join("");
    const n = (cov.clients || []).length;
    const coding = cov.coding || {};
    const cr = coding.total ? ` Custom coding ${esc(String(coding.hit || 0))}/${esc(String(coding.total))} (${esc(String(coding.pct))}%).` : "";
    return `<h4>Coverage</h4><ul>${cats}</ul><p class="muted">${esc(String(n))} client(s) produced HL7 this run.${cr} Full table is on Manage → Regression.</p>`;
  }

  function testsHtml(tests) {
    if (!tests || !tests.items) return "";
    return window.pfTests ? window.pfTests.html(tests, esc) : "";
  }

  function renderDetail() {
    const live = $("req-new");
    if (live) newOpen = live.open;
    const c = rows.find((x) => x.slug === selected);
    if (!c) {
      detailEl.innerHTML = '<p class="empty">Client not found.</p>';
      return;
    }
    $("client-detail-title").textContent = c.title;
    const reqs = (detail && detail.requests) || [];
    const open = detail && detail.request;
    const pdfUrl = (open && open.plan_pdf_url) || "";
    const planMd = (open && open.plan) || "";
    const pipe = (detail && detail.pipeline) || pipeline;
    const processing = !!(pipe && pipe.busy && pipe.slug === selected);
    const formOpen = newOpen || !reqs.length || ocrBusy || !!(draft.email || draft.from || draft.subject || (draft.screenshots || []).length);
    const form = `<details class="panel" id="req-new"${formOpen ? " open" : ""}>
      <summary>New email request</summary>
      <form id="req-form" class="req-form">
        <div class="drop-zone" id="req-drop">
          <input type="file" id="req-file" accept="image/*" multiple />
          <strong>Drop or paste a screenshot</strong>
          <span>Drop a file here, paste, or choose a photo. OCR fills From, Subject, and the email.</span>
          <div class="drop-actions"><div class="btn btn-primary drop-paste-btn" id="req-paste-btn" contenteditable="true" role="button" tabindex="0" inputmode="none" spellcheck="false">Paste screenshot</div><button type="button" class="btn" id="req-choose-btn">Choose photo</button></div>
          <p id="req-drop-status" class="muted"></p>
          <div class="draft-shots" id="req-draft-shots"></div>
        </div>
        <label>From<input name="from" type="text" placeholder="Karen Munoz &lt;karen@…&gt;" /></label>
        <label>Subject<input name="subject" type="text" required placeholder="Halifax splitting update" /></label>
        <label>Email date<input name="received_at" type="text" placeholder="2026-08-13" /></label>
        <label class="span2">Email text<textarea name="email" required rows="10" placeholder="Paste the client email, or drop a screenshot above…"></textarea></label>
        <input type="hidden" name="screenshots" value="" />
        <div class="span2 actions">
          <button type="submit" class="btn" data-run="">Save</button>
          <button type="submit" class="btn btn-primary" data-run="1">Save &amp; build plan</button>
        </div>
      </form>
    </details>`;
    const top = window.pfGroup ? window.pfGroup.top(reqs, detail && detail.deploy, processing) : null;
    const hist = window.pfGroup
      ? window.pfGroup.hist(reqs, open, histTab, detail && detail.deploy)
      : `<article class="panel"><h2>Request history</h2><p class="empty">No requests saved yet.</p></article>`;
    let reqPanel = "";
    if (open) {
      const showResults = ["processing", "tested", "ready", "error", "applied"].includes(open.status);
      const testsOk = !!(open.tests && open.tests.ok);
      const testing = !!(pipe && pipe.busy && pipe.kind === "tests" && pipe.request_id === open.id);
      const testProg = testing
        ? (pipe.test_total
          ? `Testing ${pipe.test_step || 0} of ${pipe.test_total}${pipe.test_name ? " — " + pipe.test_name : ""}`
          : (pipe.test_name || pipe.message || "Running tests…"))
        : "";
      const testJump = testing
        ? `<p><span class="test-jump is-run">${esc(testProg)}</span></p>`
        : "";
      const reviewOk = testsOk && !processing && (open.status === "tested" || open.status === "ready" || open.status === "error");
      const canMerge = reviewOk && !open.git_merged;
      const showPlan = planOpen == null ? !!(planMd || pdfUrl) : planOpen;
      const pdfIcon = pdfUrl ? `<a class="pdf-open" href="${esc(pdfUrl)}" target="_blank" rel="noopener" title="Open change plan PDF" aria-label="Open change plan PDF"></a>` : "";
      const pdfBody = planMd
        ? planHtml(planMd)
        : (pdfUrl
          ? `<p class="muted">Plan text is missing. <a href="${esc(pdfUrl)}" target="_blank" rel="noopener">Open the PDF</a>.</p>`
          : '<p class="muted">Build a change plan to inspect eip-root and write the proposed edits.</p>');
      const hasDiff = open.diff && !String(open.diff).startsWith("(no file");
      const diffView = open.diff_html
        ? `<div class="diff-side">${open.diff_html}</div>`
        : (hasDiff ? `<pre class="diff-view">${esc(open.diff)}</pre>` : "");
      const workMsg = (() => {
        let msg = open.message || "";
        msg = msg.replace(/^Tests passed[^.]*\.\s*/i, "").replace(/^Tests passed\s*·\s*/i, "");
        const implemented = !!(open.git_branch || open.tests || open.git_merged || open.deployed);
        if (implemented) {
          msg = msg.replace(/\s*Implement,\s*then\s+/i, " ");
        }
        const stale = /^(Capturing baseline|Running regression|Implementing the planned|Regression:|Ready\s+[—\-].*stopped|Stopped\.?|Regression failed: name '_typical_sec')/i.test(msg);
        const body = stale || !msg ? "" : msg;
        if (!body) return "";
        if (/^tests (passed|failed)/i.test(body)) return "";
        const fail = /fail|error|unexpected/i.test(body);
        return `<p class="${fail ? "bad" : ""}">${esc(body)}</p>`;
      })();
      const recVid = !!(open.video && open.video.status === "running");
      const featNext = !pdfUrl ? "process" : !(showResults || open.git_branch) ? "work" : !testsOk ? "retest" : "";
      const regrNext = open.regression_baseline || /baseline captured/i.test(open.message || "") ? "regression" : "capture";
      const go = (step) => (!processing && (step === featNext || step === regrNext) ? " btn-go" : "");
      const featBusy = processing && pipe && pipe.request_id === open.id && pipe.kind !== "regression";
      const featStatus = testing
        ? testJump
        : featBusy
          ? `<p class="req-status">${esc(pipe.message || "Working…")}</p>`
          : !pdfUrl
            ? `<p class="req-status">Build a change plan first.</p>`
            : !(showResults || open.git_branch)
              ? `<p class="req-status">Plan is ready. Implement next.</p>`
              : !open.tests
                ? `<p class="req-status">Implemented. Re-run tests next.</p>`
                : !testsOk
                  ? `<p class="req-status bad">Feature tests failed. Fix it, then Re-run tests.</p>`
                  : (open.git_merged || open.deployed || open.status === "applied")
                    ? `<p class="req-status ok">Feature tests passed. This change is ${open.deployed || open.status === "applied" ? "applied" : "merged"}.</p>`
                    : canMerge
                      ? `<p class="req-status ok">Feature tests passed. Merge when you're ready.</p>`
                      : `<p class="req-status ok">Feature tests passed.</p>`;
      const liveRegr = !!(pipe && pipe.busy && pipe.request_id === open.id && (pipe.kind === "regression" || (pipe.regression && pipe.regression.busy)));
      const regrStatus = liveRegr ? "" : (/baseline|regression/i.test(open.message || "") ? workMsg : "");
      reqPanel = `<article class="panel">
        <h2 class="req-head">${window.pfGroup ? window.pfGroup.hours(open) : ""}${esc(open.subject || open.id)}<span class="file-icons">${pdfIcon}${window.pfVideo ? window.pfVideo.icon(open, selected, { can: reviewOk && !processing, rec: recVid }) : ""}</span></h2>
        <p class="muted">${esc(open.from)} · ${esc(open.received_at)} · ${esc(statusLabel(open.status))}${open.phase && !(String(open.phase).startsWith("regression") && !processing) ? " · " + esc(open.phase) : ""}</p>
        ${selected === "crl-plus" && c && c.local_url ? `<p>Implementation is the <a href="${esc(c.local_url)}" target="_blank" rel="noopener">CRL Plus Sandbox</a></p>` : ""}
        ${window.pfGroup ? window.pfGroup.where(open, canMerge) : ""}
        <div class="req-action-groups">
          <div class="req-action-group">
            <p class="muted req-action-label">Feature</p>
            <div class="actions">
              <button type="button" class="btn${go("process")}" id="req-process" ${processing ? "disabled" : ""}>${pdfUrl ? "Re-Build plan" : "Build plan"}</button>
              <button type="button" class="btn${go("work")}" id="req-work" ${processing || !pdfUrl ? "disabled" : ""}>${showResults || open.git_branch ? "Re-Implement plan" : "Implement"}</button>
              <button type="button" class="btn${go("retest")}" id="req-retest" ${processing || (!open.tests && !pdfUrl) ? "disabled" : ""}>Re-run tests</button>
              <button type="button" class="btn${testsOk && ((open.changes || []).length || open.applied) && !processing ? " btn-go" : ""}" id="req-package" ${processing || !testsOk || !((open.changes || []).length || (open.applied || []).length) ? "disabled" : ""}>${open.deploy_zip ? "Rebuild TEST zip" : "Create TEST zip"}</button>
            </div>
            ${featStatus}
            ${open.tests ? `<details class="fold tests-fold${testsOk ? " is-ok" : ""}" id="req-tests"${testsOk ? "" : " open"}><summary>Feature tests ${testsOk ? "passed" : "failed"}</summary><div class="tests-block${testsOk ? " is-ok" : ""}">${testsHtml(open.tests)}</div></details>` : ""}
          </div>
          <div class="req-action-group">
            <p class="muted req-action-label">Regression</p>
            <div class="actions">
              <button type="button" class="btn${go("capture")}" id="req-regr-capture" ${processing ? "disabled" : ""}>Capture Regression Baseline</button>
              <button type="button" class="btn${go("regression")}" id="req-regression" ${processing ? "disabled" : ""}>Run Regression</button>
              ${pipe && pipe.busy && (pipe.kind === "regression" || (pipe.regression && pipe.regression.busy)) && pipe.request_id === open.id ? `<button type="button" class="btn" id="req-regr-stop">Stop ${pipe.regression && pipe.regression.capture ? "baseline capture" : "regression"}</button>` : ""}
            </div>
            <div id="req-regr-slot"></div>
            ${regrStatus}
            ${!liveRegr && open.regression ? regrReport(open.regression) : ""}
          </div>
        </div>${window.pfVideo ? window.pfVideo.place(open, selected) : ""}
        ${(open.request_summary || (open.dive && (open.dive.ask || open.dive.summary)) || open.subject) ? `<div class="change-blurb"><strong>What is being requested</strong><p>${esc(open.request_summary || (open.dive && (open.dive.ask || open.dive.summary)) || open.subject)}</p></div>` : ""}
        ${window.pfComments ? window.pfComments.fold(open, commentsOpen) : ""}
        ${(open.dive && (open.dive.delta || []).length) ? `<div class="comment-delta"><strong>From your comments</strong>${open.dive.delta.map((d) => `<p>${esc(d)}</p>`).join("")}</div>` : ""}
        <h3>Email</h3>
        ${(open.screenshot_urls || []).length ? `<div class="req-shots">${(open.screenshot_urls || []).map((u) => `<a href="${esc(u)}" target="_blank" rel="noopener"><img class="req-shot" src="${esc(u)}" alt="Request screenshot" /></a>`).join("")}</div>` : ""}
        <details class="fold"><summary>OCR text</summary><pre class="email-view">${esc(open.email || "")}</pre></details>
        <details class="fold plan-fold" id="req-plan"${showPlan ? " open" : ""}>
          <summary>Proposed changes</summary>
          ${pdfBody}
        </details>
        ${showResults && diffView ? `${(open.change_summary || (open.dive && open.dive.summary)) ? `<div class="change-blurb"><strong>What changed</strong><p>${esc(open.change_summary || open.dive.summary)}</p></div>` : ""}<h3>Code changes</h3>${diffView}` : ""}
      </article>`;
    }
    detailEl.innerHTML =
      `<article class="card">
        <div>
          <h3>${esc(c.title)}</h3>
          <code>${esc(c.path)}</code>
          ${c.local_url ? `<div class="urls"><a href="${esc(c.local_url)}" target="_blank" rel="noopener">Local</a>${c.lan_url ? `<a href="${esc(c.lan_url)}" target="_blank" rel="noopener">LAN</a>` : ""}</div>` : ""}
        </div>
        <div class="actions">
          <button type="button" class="eic-open" data-cact="eiconsole" title="Open eiConsole" aria-label="Open eiConsole"></button>
          <button type="button" class="btn" data-cact="manage">Manage</button>
          <span class="badge ${c.running ? "on" : "off"}">${c.running ? "Running" : "Stopped"}</span>
          <button type="button" class="btn" data-cact="start" ${busy() || c.running || !c.has_sandbox ? "disabled" : ""}>Start sandbox</button>
          <button type="button" class="btn btn-quiet" data-cact="stop" ${busy() || !c.running ? "disabled" : ""}>Stop</button>
          ${top ? top.btn : ""}
        </div>
      </article>` +
      (top ? top.strip : "") +
      form +
      reqPanel +
      hist;
    applyDraft();
    if (window.pfDiff) window.pfDiff.fold(detailEl);
  }

  function captureDraft() {
    const form = $("req-form");
    if (!form) return;
    const fd = new FormData(form);
    draft.from = fd.get("from") || "";
    draft.subject = fd.get("subject") || "";
    draft.received_at = fd.get("received_at") || "";
    draft.email = fd.get("email") || "";
    const st = $("req-drop-status");
    if (st) draft.status = st.textContent || draft.status;
  }

  function applyDraft() {
    const form = $("req-form");
    if (!form) return;
    const set = (name, val) => {
      if (form.elements[name] && val) form.elements[name].value = val;
    };
    set("from", draft.from);
    set("subject", draft.subject);
    set("received_at", draft.received_at);
    set("email", draft.email);
    if (form.elements.screenshots) form.elements.screenshots.value = JSON.stringify(draft.screenshots || []);
    const st = $("req-drop-status");
    if (st) st.textContent = draft.status || "";
    const zone = $("req-drop");
    if (zone) zone.classList.toggle("is-busy", ocrBusy);
    const thumbs = $("req-draft-shots");
    if (thumbs) thumbs.innerHTML = (draft.previews || []).map((u) => `<img src="${esc(u)}" alt="Dropped screenshot" />`).join("");
    const box = $("req-new");
    if (box && (ocrBusy || draft.email || (draft.screenshots || []).length)) box.open = true;
  }

  async function loadList() {
    const resp = await fetch("/api/clients", { cache: "no-store" });
    const data = await resp.json();
    rows = data.clients || [];
    job = data.job || {};
    pipeline = data.pipeline || {};
    paintBanner();
    renderList();
  }

  async function loadDetail() {
    if (!selected) return;
    captureDraft();
    const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests`, { cache: "no-store" });
    const data = await resp.json();
    detail = { requests: data.requests || [], pipeline: data.pipeline || {}, request: null, deploy: data.deploy || null };
    pipeline = detail.pipeline;
    if (selectedReq) {
      const one = await fetch(
        `/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(selectedReq)}`,
        { cache: "no-store" }
      );
      const body = await one.json();
      if (body.request) detail.request = body.request;
      if (body.pipeline) pipeline = body.pipeline;
    }
    paintBanner();
    const r = (detail && detail.request) || {};
    const v = r.video || {};
    const sig = [selected, selectedReq, r.status, r.phase, r.plan_pdf_url, (r.plan || "").length, r.git_merged, !!(r.diff_html), (r.changes || []).length, !!(pipeline && pipeline.busy), pipeline && pipeline.kind, v.status, v.ready, v.phase, detail && detail.deploy && detail.deploy.path, ((detail && detail.requests) || []).map((x) => x.id + x.status).join()].join("|");
    if (sig === viewSig && $("req-form")) return;
    viewSig = sig;
    if (window.pfHub && window.pfHub.holdScroll) window.pfHub.holdScroll(renderDetail);
    else renderDetail();
    paintBanner();
  }

  function schedule() {
    if (timer) clearTimeout(timer);
    const on = $("tab-clients") && !$("tab-clients").hidden;
    if (!on) return;
    const rec = (pipeline && pipeline.busy) || ((detail && detail.request && detail.request.video && detail.request.video.status) === "running");
    timer = setTimeout(async () => {
      try {
        await loadList();
        if (selected) await loadDetail();
      } catch (err) {}
      schedule();
    }, rec ? (pipeline && (pipeline.kind === "tests" || pipeline.kind === "regression") ? 400 : 1000) : 4000);
  }

  async function show() {
    listView.hidden = false;
    detailView.hidden = true;
    if (window.pfManage) window.pfManage.hide();
    selected = "";
    selectedReq = "";
    viewSig = "";
    planOpen = null; commentsOpen = false; newOpen = null;
    draft = emptyDraft();
    remember({ client: "", request: "" });
    await loadList();
    schedule();
  }

  async function openClient(slug, reqId) {
    selected = slug;
    selectedReq = reqId || "";
    viewSig = "";
    planOpen = null; commentsOpen = false; newOpen = null;
    draft = emptyDraft();
    listView.hidden = true;
    detailView.hidden = false;
    if (window.pfManage) window.pfManage.hide();
    remember({ tab: "clients", client: slug, request: selectedReq, manage: false });
    await loadList();
    await loadDetail();
    schedule();
  }

  function restore() {
    const st = (window.pfHub && window.pfHub.read()) || {};
    histTab = st.reqHist === "deployed" ? "deployed" : "active";
    const cq = st.clientQ || "";
    q = cq.trim().toLowerCase();
    if (filter) filter.value = cq;
    if (st.client && st.manage && window.pfManage) return window.pfManage.open(st.client);
    if (st.client) return openClient(st.client, st.request || "");
    return show();
  }

  filter.addEventListener("input", () => {
    q = (filter.value || "").trim().toLowerCase();
    remember({ clientQ: filter.value });
    renderList();
  });
  $("client-back").addEventListener("click", () => show());

  listEl.addEventListener("click", async (ev) => {
    const btn = ev.target.closest("button[data-cact]");
    if (!btn) return;
    const card = btn.closest("[data-cslug]");
    const slug = card && card.dataset.cslug;
    const act = btn.dataset.cact;
    if (!slug) return;
    if (act === "open") {
      openClient(slug);
      return;
    }
    if (act === "manage" && window.pfManage) {
      window.pfManage.open(slug);
      return;
    }
    if (act === "eiconsole") {
      btn.disabled = true;
      const resp = await fetch(`/api/clients/${encodeURIComponent(slug)}/eiconsole`, { method: "POST" });
      const data = await resp.json().catch(() => ({}));
      btn.disabled = false;
      if (!resp.ok) alert(data.error || "Could not open eiConsole");
      return;
    }
    btn.disabled = true;
    await fetch(`/api/clients/${encodeURIComponent(slug)}/${act}`, { method: "POST" });
    loadList();
  });

  async function ingestFiles(files) {
    const seen = new Set();
    files = [...(files || [])].filter((f) => f && (String(f.type || "").startsWith("image/") || /\.(png|jpe?g|gif|webp|tiff?)$/i.test(f.name || "")) && !seen.has(`${f.size}:${f.type}`) && seen.add(`${f.size}:${f.type}`));
    if (!selected || !files.length) return;
    ocrBusy = true;
    draft.status = `Reading ${files.length} screenshot${files.length === 1 ? "" : "s"}…`;
    applyDraft();
    for (const file of files) {
      draft.previews.push(URL.createObjectURL(file));
      const fd = new FormData();
      fd.append("file", file, file.name || "screenshot.png");
      const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/screenshot`, {
        method: "POST",
        body: fd,
      });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) {
        draft.status = data.error || "Could not read that screenshot.";
        continue;
      }
      if (data.path) draft.screenshots.push(data.path);
      ["from", "subject", "received_at"].forEach((k) => { if (data[k] && !draft[k]) draft[k] = data[k]; });
      const chunk = data.email || data.ocr || "";
      if (chunk) draft.email = draft.email ? `${draft.email.trim()}\n\n---\n\n${chunk}` : chunk;
      draft.status = `Read ${draft.screenshots.length} screenshot${draft.screenshots.length === 1 ? "" : "s"} — review the fields, then Save & process.`;
      applyDraft();
    }
    ocrBusy = false;
    applyDraft();
  }

  function clipFiles(cd) {
    const fromItems = [];
    for (const item of [...((cd && cd.items) || [])]) {
      if (String(item.type || "").startsWith("image/")) { const b = item.getAsFile(); if (b) fromItems.push(b); }
    }
    return fromItems.length ? fromItems : [...((cd && cd.files) || [])].filter((f) => String(f.type || "").startsWith("image/"));
  }

  detailEl.addEventListener("input", (ev) => {
    const paste = ev.target.closest("#req-paste-btn");
    if (paste) {
      const imgs = [...paste.querySelectorAll("img")];
      paste.textContent = "Paste screenshot";
      if (imgs.length) Promise.all(imgs.map((img) => fetch(img.src).then((r) => r.blob()).catch(() => null))).then((blobs) => ingestFiles(blobs.filter((b) => b && String(b.type || "").startsWith("image/")).map((b) => new File([b], "screenshot.png", { type: b.type || "image/png" }))));
      return;
    }
    if (ev.target.closest("#req-form")) captureDraft();
  });
  detailEl.addEventListener("keydown", (ev) => {
    if (ev.target.closest("#req-paste-btn") && !ev.metaKey && !ev.ctrlKey) ev.preventDefault();
  });
  detailEl.addEventListener("dragover", (ev) => {
    if (!ev.target.closest("#req-drop")) return;
    ev.preventDefault();
    if (ev.dataTransfer) ev.dataTransfer.dropEffect = "copy";
    $("req-drop").classList.add("is-over");
  });
  detailEl.addEventListener("dragleave", (ev) => {
    const z = $("req-drop");
    if (z && !z.contains(ev.relatedTarget)) z.classList.remove("is-over");
  });
  detailEl.addEventListener("drop", (ev) => {
    const z = $("req-drop");
    if (z) z.classList.remove("is-over");
    if (!ev.target.closest("#req-drop")) return;
    ev.preventDefault();
    const files = [...((ev.dataTransfer && ev.dataTransfer.files) || [])];
    if (files.length) ingestFiles(files);
  });
  detailEl.addEventListener("click", (ev) => {
    if (ev.target.closest("#req-paste-btn")) return;
    const zone = ev.target.closest("#req-drop");
    if (zone && ev.target.id !== "req-file" && $("req-file")) $("req-file").click();
  });
  detailEl.addEventListener("change", (ev) => {
    if (ev.target.id !== "req-file") return;
    ingestFiles([...(ev.target.files || [])]);
    ev.target.value = "";
  });
  window.addEventListener("paste", (ev) => {
    if (!($("tab-clients") && !$("tab-clients").hidden && selected && detailView && !detailView.hidden)) return;
    if ($("req-notes-fold") && $("req-notes-fold").open) return;
    const files = clipFiles(ev.clipboardData);
    if (!files.length) return;
    ev.preventDefault();
    ingestFiles(files);
  });

  detailEl.addEventListener("toggle", (ev) => {
    if (ev.target.id === "req-plan") planOpen = ev.target.open; else if (ev.target.id === "req-notes-fold") commentsOpen = ev.target.open;
  });

  detailEl.addEventListener("click", async (ev) => {
    const manageBtn = ev.target.closest("button[data-cact=\"manage\"]");
    if (manageBtn && selected && window.pfManage) {
      window.pfManage.open(selected);
      return;
    }
    const eic = ev.target.closest("button[data-cact=\"eiconsole\"]");
    if (eic && selected) {
      eic.disabled = true;
      const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/eiconsole`, { method: "POST" });
      const data = await resp.json().catch(() => ({}));
      eic.disabled = false;
      if (!resp.ok) alert(data.error || "Could not open eiConsole");
      return;
    }
    const backAct = ev.target.closest("button[data-cact]");
    if (backAct && selected) {
      const act = backAct.dataset.cact;
      backAct.disabled = true;
      await fetch(`/api/clients/${encodeURIComponent(selected)}/${act}`, { method: "POST" });
      await loadList();
      await loadDetail();
      return;
    }
    const histBtn = ev.target.closest("[data-hist]");
    if (histBtn) {
      histTab = histBtn.dataset.hist === "deployed" ? "deployed" : "active";
      remember({ reqHist: histTab });
      viewSig = "";
      renderDetail();
      return;
    }
    const item = ev.target.closest("button[data-rid]");
    if (item) {
      selectedReq = item.dataset.rid;
      planOpen = null; commentsOpen = false;
      remember({ request: selectedReq });
      await loadDetail();
      return;
    }
    if (window.pfGroup && await window.pfGroup.handle(ev, selected, () => loadDetail())) return;
    if (window.pfComments && await window.pfComments.handle(ev, selected, selectedReq, () => { commentsOpen = true; return loadDetail(); })) return;
    if (window.pfVideo && await window.pfVideo.handle(ev, selected, selectedReq, () => loadDetail())) return;
    const stopBtn = ev.target.closest("#req-regr-stop");
    if (stopBtn && selected) {
      stopBtn.disabled = true;
      await fetch(`/api/clients/${encodeURIComponent(selected)}/regression/stop`, { method: "POST" });
      await loadDetail();
      return;
    }
    const packBtn = ev.target.closest("#req-package");
    if (packBtn && selected && selectedReq) {
      packBtn.disabled = true;
      const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(selectedReq)}/package`, { method: "POST" });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) alert(data.error || "Could not create the TEST zip");
      histTab = "deployed";
      await loadDetail();
      return;
    }
    const actBtn = ev.target.closest("#req-process, #req-work, #req-merge, #req-retest, #req-regression, #req-regr-capture");
    if (actBtn && selectedReq) {
      const kind = actBtn.id === "req-process" ? "process" : actBtn.id === "req-merge" ? "merge" : actBtn.id === "req-retest" ? "retest" : actBtn.id === "req-regr-capture" || actBtn.id === "req-regression" ? "regression" : "work";
      if (kind === "work") planOpen = false; else if (kind === "process") planOpen = true;
      actBtn.disabled = true;
      const comments = kind === "process" && $("req-comments") ? $("req-comments").value : "";
      const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests/${encodeURIComponent(selectedReq)}/${kind}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ comments, capture: actBtn.id === "req-regr-capture" }) });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) alert(data.error || "Request failed");
      await loadDetail();
    }
  });

  detailEl.addEventListener("submit", async (ev) => {
    const form = ev.target.closest("#req-form");
    if (!form || !selected) return;
    ev.preventDefault();
    const run = ev.submitter && ev.submitter.getAttribute("data-run") === "1";
    const fd = new FormData(form);
    captureDraft();
    let shots = draft.screenshots || [];
    try {
      const parsed = JSON.parse(fd.get("screenshots") || "[]");
      if (Array.isArray(parsed) && parsed.length) shots = parsed;
    } catch (err) {}
    const payload = {
      from: fd.get("from") || "",
      subject: fd.get("subject") || "",
      received_at: fd.get("received_at") || "",
      email: fd.get("email") || "",
      screenshots: shots,
      process: run,
    };
    const resp = await fetch(`/api/clients/${encodeURIComponent(selected)}/requests`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) { alert(data.error || "Could not save request"); return; }
    selectedReq = data.request && data.request.id;
    remember({ request: selectedReq || "" });
    draft = emptyDraft();
    form.reset();
    await loadList();
    await loadDetail();
  });

  if (window.pfComments) window.pfComments.bind(detailEl, () => ({ selected, selectedReq, reload() { commentsOpen = true; return loadDetail(); } }));
  window.pfClients = { show, openClient, restore };
  if (window.pfHub && window.pfHub.boot) window.pfHub.boot();
})();
