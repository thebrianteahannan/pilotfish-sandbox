(function () {
  const $ = (id) => document.getElementById(id);
  const view = $("client-manage-view");
  const box = $("client-manage");
  if (!view || !box) return;

  const esc = (s) => String(s || "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  window.pfRegrLiveLists = function (job, escapeHtml) {
    const e = escapeHtml || esc;
    const inboundN = Number(job.inbound_n != null ? job.inbound_n : (job.inbound || []).length) || 0;
    const pickedN = Number(job.picked_n != null ? job.picked_n : (job.picked || []).length) || 0;
    const outputN = Number(job.output_n != null ? job.output_n : (job.outputs || []).length) || 0;
    if (!inboundN && !pickedN && !outputN && !job.stage && !job.queue) return "";
    const col = (title, n, items) => {
      const list = items || [];
      const more = n > list.length ? ` <span class="muted">+${e(String(n - list.length))} more</span>` : "";
      const lis = list.length ? list.map((x) => `<li><code>${e(x)}</code></li>`).join("") : '<li class="muted">None</li>';
      return `<div class="regr-live-col"><h4>${e(title)} (${e(String(n))})${more}</h4><ul>${lis}</ul></div>`;
    };
    const stage = job.where || job.stage ? `<p><strong>EIP now:</strong> ${e(job.where || job.stage)}</p>` : "";
    const feed = job.feed && job.feed !== (job.stage || "") ? `<p class="muted">Last feed in log: ${e(job.feed)}</p>` : "";
    const queue = job.queue ? `<p class="muted">Work queue: ${e(String(job.queue))} transaction(s)</p>` : "";
    return `${stage}${feed}${queue}<div class="regr-live-cols">${col("Still in data/in", inboundN, job.inbound)}${col("Picked up", pickedN, job.picked)}${col("ADT/DFT written", outputN, job.outputs)}</div>`;
  };

  window.pfRegrEta = function (job, elapsed) {
    const fmt = (s) => {
      s = Math.max(0, Math.round(Number(s) || 0));
      const m = Math.floor(s / 60);
      const r = s % 60;
      return m ? `${m}m ${String(r).padStart(2, "0")}s` : `${r}s`;
    };
    const exp = Number(job && (job.capture_sec || job.expected_sec)) || 0;
    if (!exp) {
      return { pct: null, text: `elapsed ${fmt(elapsed)} · no capture duration yet` };
    }
    const raw = Math.round((elapsed / exp) * 100);
    const pct = Math.min(100, Math.max(1, raw));
    const over = elapsed > exp;
    return {
      pct,
      text: over
        ? `${raw}% · elapsed ${fmt(elapsed)} of capture ${fmt(exp)} · still running`
        : `${raw}% · elapsed ${fmt(elapsed)} of capture ${fmt(exp)} · ${fmt(exp - elapsed)} left`,
    };
  };
  let slug = "";
  let state = { eip_version: "", people: [], title: "" };
  let db = null;
  let dbPane = "clients";
  let dbTable = "";
  let dbFilter = "";
  let dbRaw = null;
  let regr = null;
  let regrTimer = 0;
  let regrFilter = "";
  let manPane = "people";
  let h2Asked = false;
  let coding = null;
  let codingFilter = "";
  let codingAsked = false;
  let codingPane = "by-client";
  let mues = null;
  let muesAsked = false;

  function tableHtml(cols, rows) {
    if (!cols || !cols.length) return '<p class="empty">No columns.</p>';
    const head = cols.map((c) => `<th>${esc(c)}</th>`).join("");
    const body = (rows || [])
      .map((r) => `<tr>${cols.map((c) => `<td>${esc(r[c] == null ? "" : r[c])}</td>`).join("")}</tr>`)
      .join("");
    return `<div class="db-scroll"><table class="db-table"><thead><tr>${head}</tr></thead><tbody>${body || `<tr><td colspan="${cols.length}">No rows</td></tr>`}</tbody></table></div>`;
  }

  function clientCards() {
    const q = dbFilter.trim().toLowerCase();
    const list = ((db && db.clients) || []).filter((c) => {
      if (!q) return true;
      const blob = [c.name, c.partition, c.client, c.software_id, JSON.stringify(c.regression || [])].join(" ").toLowerCase();
      return blob.includes(q);
    });
    if (!list.length) return '<p class="empty">No clients match.</p>';
    return list
      .map((c) => {
        const facCols = c.facilities && c.facilities[0] ? Object.keys(c.facilities[0]) : ["FACILITY", "FACILITY_CODE"];
        const codeCols = c.codes && c.codes[0] ? Object.keys(c.codes[0]) : ["CODE", "FACILITY", "COMPARATOR"];
        const stripCols = c.strip_locations && c.strip_locations[0] ? Object.keys(c.strip_locations[0]) : ["LOCATION", "LOCATION2"];
        const ruleCols = ["PARTITION", "CLIENT", "RULE_NAME"];
        const files = c.regression || [];
        const fileHtml = files.length
          ? `<ul class="regr-files">${files
              .map((f) => {
                const ins = (f.inputs || []).join(", ") || "no in/ sample";
                const zips = (f.zips || []).join(", ");
                return `<li><strong>${esc(f.title || f.id)}</strong> <span class="muted">${esc(f.id)}</span><div class="muted">in/: ${esc(ins)}</div>${zips ? `<div class="muted">zips: ${esc(zips)}</div>` : ""}</li>`;
              })
              .join("")}</ul>`
          : '<p class="empty">No regression test files for this client yet.</p>';
        const nfiles = files.reduce((n, f) => n + (f.inputs || []).length + (f.zips || []).length, 0);
        return `<details class="db-client">
          <summary><strong>${esc(c.name || c.client || c.id)}</strong> <span class="muted">${esc(c.partition)} / ${esc(c.client)} · software ${esc(c.software_id)} · ${esc(String((c.facilities || []).length))} facilities · ${esc(String(nfiles))} test file(s)</span></summary>
          <p class="muted">FLG locations ${esc(String(c.flg_count || 0))} · MUE edits ${esc(String(c.mue_count || 0))} (full lists are on Raw tables)</p>
          <h4>Regression test files</h4>${fileHtml}
          <h4>Facilities / splits</h4>${tableHtml(facCols, c.facilities)}
          <h4>Client codes</h4>${tableHtml(codeCols, c.codes)}
          <h4>Strip locations</h4>${tableHtml(stripCols, c.strip_locations)}
          <h4>Stripping rules</h4>${tableHtml(ruleCols, c.stripping_rules)}
          <h4>Tweaking rules</h4>${tableHtml(ruleCols, c.tweaking_rules)}
        </details>`;
      })
      .join("");
  }

  function dbHtml() {
    if (slug !== "med-rec") return "";
    if (!db) {
      if (!h2Asked) loadH2();
      return `<article class="panel"><h2>H2 database</h2><p class="muted">Loading…</p></article>`;
    }
    if (!db.ok) return `<article class="panel"><h2>H2 database</h2><p class="empty">${esc(db.error || "Could not read H2")}</p></article>`;
    const tabs = `<div class="toolbar"><button type="button" class="btn${dbPane === "clients" ? " btn-primary" : ""}" data-dbpane="clients">By client</button><button type="button" class="btn${dbPane === "raw" ? " btn-primary" : ""}" data-dbpane="raw">Raw tables</button><button type="button" class="btn${dbPane === "shared" ? " btn-primary" : ""}" data-dbpane="shared">Shared codes</button></div>`;
    if (dbPane === "raw") {
      const opts = (db.tables || []).map((t) => `<option value="${esc(t.name)}" ${dbTable === t.name ? "selected" : ""}>${esc(t.name)} (${esc(String(t.count))})</option>`).join("");
      const raw = dbRaw
        ? `${dbRaw.capped ? `<p class="muted">Showing first ${esc(String((dbRaw.rows || []).length))} of ${esc(String(dbRaw.count))} rows.</p>` : `<p class="muted">${esc(String(dbRaw.count))} rows.</p>`}${tableHtml(dbRaw.columns, dbRaw.rows)}`
        : '<p class="muted">Pick a table.</p>';
      return `<article class="panel"><h2>H2 database</h2><p class="hint">${esc(db.note || "")} File: <code>${esc(db.path || "")}</code></p>${tabs}<label class="db-pick">Table <select id="db-table"><option value="">Choose a table…</option>${opts}</select></label>${raw}</article>`;
    }
    if (dbPane === "shared") {
      const s = db.shared || {};
      return `<article class="panel"><h2>H2 database</h2><p class="hint">Codes that are not per-client. ${esc(db.note || "")}</p>${tabs}
        <h4>ER insurance plan codes</h4>${tableHtml(s.er_ins_plan_codes && s.er_ins_plan_codes[0] ? Object.keys(s.er_ins_plan_codes[0]) : ["CODE"], s.er_ins_plan_codes)}
        <h4>Strip performing sites</h4>${tableHtml(s.strip_performing_sites && s.strip_performing_sites[0] ? Object.keys(s.strip_performing_sites[0]) : ["MNEMONIC"], s.strip_performing_sites)}
        <h4>Bad group numbers</h4>${tableHtml(s.bad_group_nums && s.bad_group_nums[0] ? Object.keys(s.bad_group_nums[0]) : ["CODE"], s.bad_group_nums)}
        <h4>Bad secondary insurances</h4>${tableHtml(s.bad_secondary_insurances && s.bad_secondary_insurances[0] ? Object.keys(s.bad_secondary_insurances[0]) : ["CODE"], s.bad_secondary_insurances)}
        <h4>Secondary insurance company codes</h4>${tableHtml(s.secondary_insurance_company_codes && s.secondary_insurance_company_codes[0] ? Object.keys(s.secondary_insurance_company_codes[0]) : ["CODE"], s.secondary_insurance_company_codes)}
      </article>`;
    }
    return `<article class="panel"><h2>H2 database</h2><p class="hint">${esc(db.note || "")} File: <code>${esc(db.path || "")}</code></p>${tabs}
      <label>Filter clients <input id="db-filter" type="search" value="${esc(dbFilter)}" placeholder="Halifax, NGP, software id…" /></label>
      ${clientCards()}</article>`;
  }

  function coverageHtml(cov) {
    if (!cov || !(cov.categories || []).length) return "";
    const cats = (cov.categories || [])
      .map((c) => {
        const pct = Number(c.pct) || 0;
        const missed = (c.missed || []).length
          ? `<details class="cc-miss"><summary class="muted">${esc(String((c.missed || []).length + (c.missed_more || 0)))} not hit</summary><p class="muted">${esc((c.missed || []).join(", "))}${(c.missed_more || 0) ? " …" : ""}</p></details>`
          : "";
        return `<div class="cov-cat">
          <div class="cov-cat-top"><strong>${esc(c.label)}</strong><span>${esc(String(c.hit))}/${esc(String(c.total))} · ${esc(String(pct))}%</span></div>
          <progress max="100" value="${esc(String(pct))}"></progress>
          ${missed}
        </div>`;
      })
      .join("");
    const rows = (cov.clients || [])
      .map((c) => {
        const fac = (c.facilities_hit || []).join(", ");
        const all = (c.facilities || []).length;
        return `<tr>
          <td>${esc(c.name || c.client || "")}</td>
          <td>${esc(c.partition || "")} / ${esc(c.client || "")}</td>
          <td>${esc(c.software_id || "")}</td>
          <td>${esc(String(c.splits_hit || 0))}/${esc(String(c.splits_total || 0))}</td>
          <td>${esc(String((c.facilities_hit || []).length))}/${esc(String(all))} ${fac ? "· " + esc(fac) : ""}</td>
        </tr>`;
      })
      .join("");
    return `<div class="cov-report">
      <h3>Coverage</h3>
      <p class="muted">From ADT/DFT written this run, matched to CLIENT_SPLITS. ${esc(String(cov.cases_ok || 0))} of ${esc(String(cov.cases_ran || 0))} case(s) produced output.</p>
      <div class="cov-cats">${cats}</div>
      ${rows ? `<div class="db-scroll"><table class="db-table"><thead><tr><th>Client</th><th>Partition / split</th><th>Software</th><th>Splits hit</th><th>Facilities hit</th></tr></thead><tbody>${rows}</tbody></table></div>` : ""}
      ${codingHtml(cov.coding)}
    </div>`;
  }

  function codingHtml(coding) {
    if (!coding || !coding.total) return "";
    const types = (coding.by_type || [])
      .map((t) => `<tr><td>${esc(t.title)}</td><td>${esc(String(t.hit))}/${esc(String(t.total))}</td><td>${esc(String(t.pct))}%</td></tr>`)
      .join("");
    const cli = (coding.by_client || [])
      .map((c) => `<tr><td>${esc(c.name || c.client || "")}</td><td>${esc(c.partition || "")} / ${esc(c.client || "")}</td><td>${esc(String(c.hit))}/${esc(String(c.total))}</td><td>${esc(String(c.pct))}%</td></tr>`)
      .join("");
    return `<h4>Custom coding</h4>
      <p class="muted">Did a 50-record sample (or its ADT/DFT) hit that special-case? Feed-only gates count if that client produced HL7. Location/MUE/GT1-style rules also need a matching token in the sample.</p>
      ${types ? `<div class="db-scroll"><table class="db-table"><thead><tr><th>Rule</th><th>Instances covered</th><th>%</th></tr></thead><tbody>${types}</tbody></table></div>` : ""}
      ${cli ? `<div class="db-scroll"><table class="db-table"><thead><tr><th>Client</th><th>Partition / split</th><th>Rules covered</th><th>%</th></tr></thead><tbody>${cli}</tbody></table></div>` : ""}`;
  }

  function regrKind(kind) {
    if (kind === "missing") return "missing this run";
    if (kind === "extra") return "new this run";
    return "changed";
  }

  function packCompare(cid, cmp, title) {
    const diffs = (cmp && cmp.diffs) || [];
    const changes = diffs.map((d) => {
      if (!d || typeof d !== "object") return { file: "", kind: "changed", lines: [String(d)] };
      const kind = d.kind || "changed";
      const name = d.file || "";
      let lines = d.lines || [];
      if (kind === "missing") lines = [`Baseline had ${name}. This run did not write that file.`];
      else if (kind === "extra") lines = [`This run wrote ${name}. It was not in the baseline.`];
      else lines = (lines || []).map((x) => String(x).replace(/\n$/, "")).slice(0, 80);
      return { file: name, kind, lines };
    });
    return {
      id: title || cid,
      error: (cmp && cmp.error) || "",
      diffs: diffs.length,
      changes,
      baseline_files: (cmp && (cmp.baseline_files || cmp.baseline)) || [],
      last_files: (cmp && (cmp.last_files || cmp.files)) || [],
    };
  }

  function regrDiffBody(ch) {
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
    const hint = missing ? "no ADT/DFT this run" : n ? `${n} file(s)` : "pass";
    const files = changes
      .map((ch) => `<details class="diff-file regr-diff" open>
        <summary class="diff-name"><span class="diff-path">${esc(ch.file || u.id)}</span> <span class="muted">${esc(regrKind(ch.kind))}</span></summary>
        ${regrDiffBody(ch)}
      </details>`)
      .join("");
    const base = (u.baseline_files || []).join(", ");
    const last = (u.last_files || []).join(", ");
    const extra = u.error ? `<p class="bad">${esc(u.error)}</p>` : "";
    const meta = `<p class="muted">Baseline: ${esc(base || "none")} · This run: ${esc(last || "none")}</p>`;
    return `<details class="db-client cc-client regr-feed">
      <summary class="${esc(cls || "")}"><strong>${esc(u.id)}</strong> <span class="muted">${esc(hint)}${u.error ? " · " + esc(u.error) : ""}</span></summary>
      ${extra}${meta}${files || `<p class="muted">${u.ok === false ? "No output compared." : "No differences."}</p>`}
    </details>`;
  }

  function lastRunHtml() {
    const cases = regr.cases || [];
    const withCmp = cases.filter((c) => c.compare && (c.compare.ok === false || (c.compare.diffs || []).length || (c.last || []).length || (c.baseline || []).length));
    if (!withCmp.length) return "";
    const q = regrFilter.trim().toLowerCase();
    const failed = [];
    const passed = [];
    withCmp.forEach((c) => {
      const blob = [c.id, c.title, c.partition, c.client, JSON.stringify(c.compare || {})].join(" ").toLowerCase();
      if (q && !blob.includes(q)) return;
      const packed = packCompare(c.id, c.compare || {}, c.title || c.id);
      packed.ok = !((c.compare && c.compare.ok === false) || (packed.changes || []).length);
      if (packed.ok) passed.push(packed);
      else failed.push(packed);
    });
    if (!failed.length && !passed.length) return "";
    return `<div class="tests-block${failed.length ? "" : " is-ok"}" id="man-regression-report">
      <h3>Last run results</h3>
      <p>${failed.length ? esc(String(failed.length)) + " feed(s) differ from baseline. Open a feed to see each file." : "No differences from baseline."}</p>
      ${failed.length ? failed.map((u) => regrFeed(u, "bad")).join("") : ""}
      ${passed.length ? `<details class="fold"><summary class="muted">${esc(String(passed.length))} feed(s) unchanged</summary>${passed.map((u) => regrFeed(u, "")).join("")}</details>` : ""}
    </div>`;
  }

  function caseDiffHtml(files) {
    const byId = Object.fromEntries((regr.cases || []).map((c) => [c.id, c]));
    return files
      .map((f) => {
        const rec = byId[f.id];
        if (!rec || !rec.compare) return "";
        const packed = packCompare(rec.id, rec.compare, rec.title || rec.id);
        packed.ok = !((rec.compare.ok === false) || (packed.changes || []).length);
        return regrFeed(packed, packed.ok ? "" : "bad");
      })
      .join("");
  }
    const names = (c.expected_files || []).filter(Boolean);
    const pats = (c.filename_patterns || []).filter(Boolean);
    if (!names.length && !pats.length) return '<p class="empty">No test files yet. No inbound filename pattern found on the listener.</p>';
    const look = names.map((n) => `<code>${esc(n)}</code>`).join(" or ");
    const raw = pats.length ? `<div class="muted">Listener pattern: ${esc(pats.join(" · "))}</div>` : "";
    return `<p class="empty">No test files yet. Look for ${look}</p>${raw}`;
  }

  function regrHtml() {
    if (!regr) return `<article class="panel"><h2>Regression suite</h2><p class="muted">Loading…</p></article>`;
    if (!regr.ok) return `<article class="panel"><h2>Regression suite</h2><p class="empty">${esc(regr.error || "Could not load")}</p></article>`;
    const job = regr.job || {};
    const busy = !!job.busy;
    const step = Number(job.step) || 0;
    const total = Number(job.step_total) || 0;
    const wait = Number(job.wait_sec) || 0;
    const tmax = Number(job.timeout_sec) || 0;
    const started = Date.parse(job.started_at || "") || 0;
    const elapsed = Math.max(
      Number(job.wait_sec) || 0,
      started && busy ? Math.max(0, Math.round((Date.now() - started) / 1000)) : 0
    );
    const pct = total ? Math.min(100, Math.round((step / total) * 100)) : busy ? 8 : 0;
    const log = (job.log || []).slice(-8).map((l) => `<li>${esc(l)}</li>`).join("");
    const lists = window.pfRegrLiveLists ? window.pfRegrLiveLists(job, esc) : "";
    const pickedN = Number(job.picked_n) || 0;
    const totalIn = Number(job.step_total) || total;
    const cap = (regr.timings && regr.timings.capture && (regr.timings.capture.last_sec || regr.timings.capture.typical_sec)) || 0;
    const timed = { ...job, capture_sec: job.capture_sec || cap || window.pfRegrCaptureSec || 0 };
    const eta = window.pfRegrEta ? window.pfRegrEta(timed, elapsed) : { pct: null, text: `elapsed ${elapsed}s` };
    const pctLive = eta.pct != null ? eta.pct : 0;
    const pctLabel = eta.pct != null ? `${eta.pct}%` : "—";
    const lastDur = regr.last_run && regr.last_run.duration_sec;
    const typ = (regr.timings && (regr.timings.typical_sec || (regr.timings.capture && regr.timings.capture.typical_sec))) || (regr.last_run && regr.last_run.typical_sec) || 0;
    const fmt = (s) => {
      s = Math.max(0, Math.round(Number(s) || 0));
      const m = Math.floor(s / 60);
      const r = s % 60;
      return m ? `${m}m ${String(r).padStart(2, "0")}s` : `${r}s`;
    };
    const typicalHint = typ ? ` Typical full run ~${fmt(typ)} (capture and after-change should match).` : "";
    const lastHint = lastDur ? ` Last run ${fmt(lastDur)}.` : "";
    const progress = busy || job.message
      ? `<div class="regr-progress${job.error ? " is-err" : ""}">
          <p class="video-phase">${esc(busy ? (job.capture ? "Capturing baseline" : "Running regression") : "Last run")}</p>
          <p class="video-msg">${esc(job.message || (busy ? "Working…" : ""))}</p>
          ${busy ? `<div class="regr-bar-row"><strong class="regr-pct">${esc(pctLabel)}</strong><progress max="100" value="${esc(String(pctLive))}"></progress></div>
          <p class="muted">${esc(eta.text)}</p>
          <p class="muted">Picked ${esc(String(pickedN || step))}/${esc(String(totalIn || "?"))} inbound · ${esc(String(job.output_n || job.files || 0))} ADT/DFT</p>` : ""}
          ${lists}
          ${job.error ? `<p class="video-err">${esc(job.error)}</p>` : ""}
          ${log ? `<ul class="video-log">${log}</ul>` : ""}
        </div>`
      : "";
    const list = regr.clients && regr.clients.length ? regr.clients : null;
    const q = regrFilter.trim().toLowerCase();
    const cards = (list || (regr.cases || []).map((c) => ({
      name: c.title || c.id,
      partition: c.partition,
      client: c.client,
      software_id: c.software_id,
      facilities: c.facilities || [],
      regression: [c],
      has_files: !!(c.inputs && c.inputs.length) || !!(c.zips && c.zips.length),
    })))
      .filter((c) => {
        if (!q) return true;
        const blob = [c.name, c.partition, c.client, c.software_id, JSON.stringify(c.regression || []), JSON.stringify(c.expected_files || [])].join(" ").toLowerCase();
        return blob.includes(q);
      })
      .map((c) => {
        const files = c.regression || [];
        const has = !!c.has_files || files.some((f) => (f.inputs || []).length || (f.zips || []).length);
        const fac = (c.facilities || []).map((f) => (typeof f === "string" ? f : f.FACILITY || f.FACILITY_CODE || "")).filter(Boolean).join(", ");
        const fileHtml = has
          ? `<ul class="regr-files">${files
              .map((f) => {
                const ins = (f.inputs || []).join(", ");
                const zips = (f.zips || []).join(", ");
                return `<li><strong>${esc(f.title || f.id)}</strong>${ins ? `<div>in/: ${esc(ins)}</div>` : ""}${zips ? `<div class="muted">zips: ${esc(zips)}</div>` : ""}</li>`;
              })
              .join("")}</ul>${caseDiffHtml(files)}`
          : expectHtml(c);
        return `<div class="db-client${has ? "" : " regr-miss"}">
          <strong>${esc(c.name || c.client || "")}</strong>
          <div class="muted">${esc(c.partition || "")} / ${esc(c.client || "")} · software ${esc(c.software_id || "")}${fac ? " · " + esc(fac) : ""}</div>
          ${fileHtml}
        </div>`;
      })
      .join("");
    const missing = (list || []).filter((c) => !c.has_files).length;
    const totalCli = (list || []).length;
    return `<article class="panel"><h2>Regression suite</h2>
      <p class="hint">${esc(regr.note || "")} ${totalCli ? esc(String(totalCli - missing)) + " of " + esc(String(totalCli)) + " clients have test files." : ""} Missing files are in red.${esc(typicalHint)}${esc(lastHint)}</p>
      <div class="toolbar">
        <button type="button" class="btn" id="regr-capture" ${busy ? "disabled" : ""}>Capture baseline</button>
        <button type="button" class="btn btn-primary" id="regr-run" ${busy ? "disabled" : ""}>Run regression</button>
        ${busy ? `<button type="button" class="btn" id="regr-stop">Stop ${job.capture ? "baseline capture" : "regression"}</button>` : ""}
      </div>
      ${progress}
      ${lastRunHtml()}
      ${coverageHtml(regr.coverage)}
      <label>Filter <input id="regr-filter" type="search" value="${esc(regrFilter)}" placeholder="Halifax, CON, software id…" /></label>
      ${cards || '<p class="empty">No clients yet.</p>'}
    </article>`;
  }

  function codingTabs() {
    return `<div class="toolbar"><button type="button" class="btn${codingPane === "by-client" ? " btn-primary" : ""}" data-codingpane="by-client">By client</button><button type="button" class="btn${codingPane === "common" ? " btn-primary" : ""}" data-codingpane="common">Common rules</button><button type="button" class="btn${codingPane === "mue" ? " btn-primary" : ""}" data-codingpane="mue">MUE edits</button></div>`;
  }

  function mueHtml() {
    if (!mues) {
      if (!muesAsked) loadMues();
      return `<article class="panel"><h2>Client custom coding</h2>${codingTabs()}<p class="muted">Loading MUE edits from H2…</p></article>`;
    }
    if (!mues.ok) return `<article class="panel"><h2>Client custom coding</h2>${codingTabs()}<p class="empty">${esc(mues.error || "Could not load MUE edits")}</p></article>`;
    const q = codingFilter.trim().toLowerCase();
    const list = (mues.clients || []).filter((c) => {
      if (!q) return true;
      const blob = [c.name, c.partition, c.client, c.software_id, JSON.stringify(c.edits || [])].join(" ").toLowerCase();
      return blob.includes(q);
    });
    const cards = list
      .map((c) => {
        const n = (c.edits || []).length;
        return `<details class="db-client cc-client">
          <summary><strong>${esc(c.name || c.client || c.software_id)}</strong> <span class="muted">${esc(c.partition)} / ${esc(c.client)} · software ${esc(c.software_id)} · ${esc(String(n))} MUE edit(s)</span></summary>
          ${tableHtml(["CPT", "MAX_VALUE_PER_LINE", "CDM"], c.edits)}
        </details>`;
      })
      .join("");
    return `<article class="panel"><h2>Client custom coding</h2>
      <p class="hint">${esc(mues.note || "")} ${esc(String(mues.client_count || 0))} software id(s) · ${esc(String(mues.edit_count || 0))} row(s).</p>
      ${codingTabs()}
      <label>Filter <input id="coding-filter" type="search" value="${esc(codingFilter)}" placeholder="Halifax, 750, CPT…" /></label>
      ${cards || '<p class="empty">No MUE edits matched that filter.</p>'}</article>`;
  }

  function codingHtml() {
    if (slug !== "med-rec") return "";
    if (codingPane === "mue") return mueHtml();
    if (!coding) {
      if (!codingAsked) loadCoding();
      return `<article class="panel"><h2>Client custom coding</h2>${codingTabs()}<p class="muted">Scanning interface OGNL, XSLT, and routes…</p></article>`;
    }
    if (!coding.ok) return `<article class="panel"><h2>Client custom coding</h2>${codingTabs()}<p class="empty">${esc(coding.error || "Could not load")}</p></article>`;
    const q = codingFilter.trim().toLowerCase();
    const groups = (coding.groups || []).filter((g) => {
      if (!q) return true;
      const blob = [g.title, g.partition, g.client, g.software_id, JSON.stringify(g.rules || [])].join(" ").toLowerCase();
      return blob.includes(q);
    });
    const tabs = codingTabs();
    const pdfHref = `/api/clients/${encodeURIComponent(slug)}/custom-coding.pdf${q ? `?q=${encodeURIComponent(codingFilter)}` : ""}`;
    const head = `<article class="panel"><h2 class="req-head">Client custom coding<span class="file-icons"><a class="pdf-open" href="${esc(pdfHref)}" target="_blank" rel="noopener" title="Download custom coding PDF" aria-label="Download custom coding PDF"></a></span></h2>
      <p class="hint">${esc(coding.note || "")} ${esc(String(coding.clients_with_rules || 0))} clients with named special-cases.</p>
      ${tabs}
      <label>Filter <input id="coding-filter" type="search" value="${esc(codingFilter)}" placeholder="NGP, MUE, GT1, Halifax…" /></label>`;
    if (codingPane === "common") {
      const commons = (coding.commons || []).filter((c) => {
        if (!q) return true;
        const blob = [c.title, c.about, c.rule_id, (c.clients || []).join(" ")].join(" ").toLowerCase();
        return blob.includes(q);
      });
      const rows = commons
        .map((c) => {
          const who = (c.clients || []).map((n) => `<li>${esc(n)}</li>`).join("");
          const kinds = Object.entries(c.kinds || {})
            .map(([k, n]) => `${k} ${n}`)
            .join(" · ");
          return `<details class="db-client cc-client">
            <summary><strong>${esc(c.title || c.rule_id)}</strong> <span class="muted">${esc(String(c.instances || 0))} instance(s) · ${esc(String(c.client_count || 0))} client(s)${kinds ? " · " + esc(kinds) : ""}</span></summary>
            <p class="cc-about">${esc(c.about || "")}</p>
            <ul class="cc-who">${who}</ul>
          </details>`;
        })
        .join("");
      return `${head}${rows || '<p class="empty">No common rules matched that filter.</p>'}</article>`;
    }
    const cards = groups
      .map((g) => {
        const byFile = new Map();
        (g.rules || []).forEach((r) => {
          const key = r.file || "";
          if (!byFile.has(key)) byFile.set(key, []);
          byFile.get(key).push(r);
        });
        const files = [...byFile.entries()]
          .map(([file, list]) => {
            const short = (file.split("/").slice(-2).join("/") || file);
            const byType = new Map();
            list.forEach((r) => {
              const key = r.rule_id || r.title || r.name || "condition";
              if (!byType.has(key)) byType.set(key, []);
              byType.get(key).push(r);
            });
            const rows = [...byType.values()]
              .map((pack) => {
                const first = pack[0];
                const kind = String(first.kind || "Route").toLowerCase();
                const hits = pack
                  .map((r) => {
                    const k = String(r.kind || "Route").toLowerCase();
                    return `<div class="cc-rule">
                      <div class="cc-rule-top"><span class="cc-kind ${esc(k)}">${esc(r.kind || "Route")}</span><span class="muted">L${esc(String(r.line || ""))}</span></div>
                      <pre class="cc-cond">${esc(r.text || "")}</pre>
                    </div>`;
                  })
                  .join("");
                const head = `<div class="cc-rule-top"><span class="cc-kind ${esc(kind)}">${esc(first.kind || "Route")}</span><strong>${esc(first.title || first.name || "condition")}</strong>${pack.length > 1 ? `<span class="muted">${esc(String(pack.length))} places</span>` : `<span class="muted">L${esc(String(first.line || ""))}</span>`}</div>
                  <p class="cc-about">${esc(first.about || "")}</p>`;
                if (pack.length === 1) {
                  return `<div class="cc-rule">${head}<pre class="cc-cond">${esc(first.text || "")}</pre></div>`;
                }
                return `<details class="cc-bundle"><summary>${head}</summary>${hits}</details>`;
              })
              .join("");
            return `<div class="cc-file"><div class="cc-file-head" title="${esc(file)}">${esc(short)}<span class="muted"> · ${esc(String(list.length))}</span></div>${rows}</div>`;
          })
          .join("");
        const fac = (g.facilities || []).filter(Boolean).slice(0, 12).join(", ");
        return `<details class="db-client cc-client">
          <summary><strong>${esc(g.title || g.client)}</strong> <span class="muted">${esc(g.partition || "—")} / ${esc(g.client || "")} · software ${esc(g.software_id || "—")} · ${esc(String((g.rules || []).length))} rule(s)${g.unlisted ? " · not in CLIENT_SPLITS" : ""}</span></summary>
          ${fac ? `<p class="cc-fac">Facilities ${esc(fac)}</p>` : ""}
          ${files}
        </details>`;
      })
      .join("");
    return `${head}${cards || '<p class="empty">No custom coding matched that filter.</p>'}</article>`;
  }

  function render() {
    $("client-manage-title").textContent = (state.title || slug) + " · Manage";
    const people = state.people || [];
    const rows = people
      .map(
        (p) => `<div class="person-row" data-pid="${esc(p.id)}">
          <div>
            <strong>${esc(p.name || "(no name)")}</strong>
            <div class="muted">${esc(p.email || "no email")}${p.source === "email" ? " · from requests" : ""}</div>
          </div>
          <div class="actions">
            <button type="button" class="btn" data-pcopy="${esc(p.email || "")}" ${p.email ? "" : "disabled"}>Copy email</button>
            <button type="button" class="btn btn-quiet" data-pdel="${esc(p.id)}">Remove</button>
          </div>
        </div>`
      )
      .join("");
    const wars = state.eip_wars || [];
    const cur = state.eip_version || "";
    const opts = ['<option value="">Not tagged (23R1)</option>'];
    const seen = new Set();
    wars.forEach((w) => {
      const fam = w.family || w.build;
      if (fam && !seen.has(fam)) {
        seen.add(fam);
        opts.push(`<option value="${esc(fam)}" ${cur === fam ? "selected" : ""}>${esc(fam)} · ${esc(w.build)}${w.size_mb ? " · " + w.size_mb + " MB" : ""}</option>`);
      }
    });
    if (cur && !seen.has(cur)) opts.push(`<option value="${esc(cur)}" selected>${esc(cur)} (no WAR yet)</option>`);
    const warOpts = opts.join("");
    if ((manPane === "h2" || manPane === "coding") && slug !== "med-rec") manPane = "people";
    const peoplePanel = `<article class="panel">
        <h2>People</h2>
        <p class="hint">Names and emails from request screenshots, or add them here. Copy puts the address on the clipboard.</p>
        <div class="toolbar">
          <button type="button" class="btn" id="people-scan">Scan requests</button>
        </div>
        ${rows || '<p class="empty">No people yet. Scan requests or add someone below.</p>'}
        <form id="people-add" class="req-form" style="margin-top:0.8rem">
          <label>Name<input name="name" type="text" placeholder="Karen Munoz" /></label>
          <label>Email<input name="email" type="email" placeholder="karen@client.com" /></label>
          <div class="span2 actions"><button type="submit" class="btn btn-primary">Add person</button></div>
        </form>
      </article>`;
    const sub = `<nav class="subtabs" role="tablist">
        <button type="button" class="tab${manPane === "people" ? " is-on" : ""}" data-manpane="people">People</button>
        ${slug === "med-rec" ? `<button type="button" class="tab${manPane === "h2" ? " is-on" : ""}" data-manpane="h2">H2 database</button>` : ""}
        <button type="button" class="tab${manPane === "regression" ? " is-on" : ""}" data-manpane="regression">Regression</button>
        ${slug === "med-rec" ? `<button type="button" class="tab${manPane === "coding" ? " is-on" : ""}" data-manpane="coding">Client custom coding</button>` : ""}
      </nav>`;
    const body = manPane === "h2" ? dbHtml() : manPane === "regression" ? regrHtml() : manPane === "coding" ? codingHtml() : peoplePanel;
    box.innerHTML = `
      <article class="panel">
        <h2>eiPlatform version</h2>
        <p class="hint">This is the eiPlatform WAR used when you Start sandbox. WARs live in the Documentation project under <code>PilotFish WARs</code>. Add a new <code>eip.war.hs.*</code> file there to offer another release.</p>
        <div class="eip-tag">
          <label>Version <select id="eip-ver">${warOpts}</select></label>
          <button type="button" class="btn btn-primary" id="eip-save">Save</button>
        </div>
      </article>
      ${sub}
      ${body}`;
  }

  async function load() {
    const resp = await fetch(`/api/clients/${encodeURIComponent(slug)}/manage`, { cache: "no-store" });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) {
      box.innerHTML = `<p class="empty">${esc(data.error || "Could not load")}</p>`;
      return;
    }
    state = data;
    render();
  }

  async function loadRegr() {
    try {
      const rg = await fetch(`/api/clients/${encodeURIComponent(slug)}/regression`, { cache: "no-store" });
      regr = await rg.json();
    } catch (err) {
      regr = { ok: false, error: "Could not load regression" };
    }
    render();
  }

  function pollRegr() {
    if (regrTimer) clearTimeout(regrTimer);
    regrTimer = setTimeout(async () => {
      await loadRegr();
      if (regr && regr.job && regr.job.busy) pollRegr();
    }, 1000);
  }

  async function loadCoding() {
    if (slug !== "med-rec" || codingAsked) return;
    codingAsked = true;
    try {
      const resp = await fetch(`/api/clients/${encodeURIComponent(slug)}/custom-coding`, { cache: "no-store" });
      coding = await resp.json();
    } catch (err) {
      coding = { ok: false, error: "Could not load custom coding" };
    }
    render();
  }

  async function loadMues() {
    if (slug !== "med-rec" || muesAsked) return;
    muesAsked = true;
    try {
      const resp = await fetch(`/api/clients/${encodeURIComponent(slug)}/mue-edits`, { cache: "no-store" });
      mues = await resp.json();
    } catch (err) {
      mues = { ok: false, error: "Could not load MUE edits" };
    }
    render();
  }

  async function loadH2() {
    if (slug !== "med-rec" || h2Asked) return;
    h2Asked = true;
    try {
      const h2 = await fetch(`/api/clients/${encodeURIComponent(slug)}/h2`, { cache: "no-store" });
      db = await h2.json();
    } catch (err) {
      db = { ok: false, error: "Could not read H2" };
    }
    render();
  }

  async function open(next) {
    slug = next;
    db = null;
    regr = null;
    coding = null;
    codingAsked = false;
    mues = null;
    muesAsked = false;
    h2Asked = false;
    const list = $("client-list-view");
    const detail = $("client-detail-view");
    if (list) list.hidden = true;
    if (detail) detail.hidden = true;
    view.hidden = false;
    box.innerHTML = `<article class="panel"><h2>Manage</h2><p class="muted">Loading…</p></article>`;
    if (window.pfHub) window.pfHub.write({ tab: "clients", client: slug, request: "", manage: true });
    try {
      await load();
    } catch (err) {
      box.innerHTML = `<p class="empty">Could not load Manage. ${esc(err && err.message ? err.message : err)}</p>`;
    }
  }

  function hide() {
    view.hidden = true;
    slug = "";
  }

  $("client-manage-back").addEventListener("click", () => {
    hide();
    if (window.pfClients) window.pfClients.show();
  });

  box.addEventListener("click", async (ev) => {
    const copy = ev.target.closest("[data-pcopy]");
    if (copy) {
      const email = copy.dataset.pcopy || "";
      if (!email) return;
      try {
        await navigator.clipboard.writeText(email);
        copy.textContent = "Copied";
        setTimeout(() => {
          copy.textContent = "Copy email";
        }, 1200);
      } catch (err) {
        alert(email);
      }
      return;
    }
    const del = ev.target.closest("[data-pdel]");
    if (del && slug) {
      await fetch(`/api/clients/${encodeURIComponent(slug)}/people/${encodeURIComponent(del.dataset.pdel)}`, { method: "DELETE" });
      await load();
      return;
    }
    if (ev.target.closest("#people-scan") && slug) {
      ev.target.disabled = true;
      await fetch(`/api/clients/${encodeURIComponent(slug)}/people/scan`, { method: "POST" });
      await load();
      return;
    }
    if (ev.target.closest("[data-manpane]")) {
      manPane = ev.target.closest("[data-manpane]").dataset.manpane || "people";
      if (manPane === "h2") loadH2();
      if (manPane === "regression") loadRegr();
      if (manPane === "coding") {
        if (codingPane === "mue") loadMues();
        else loadCoding();
      }
      render();
      return;
    }
    if (ev.target.closest("[data-codingpane]")) {
      codingPane = ev.target.closest("[data-codingpane]").dataset.codingpane || "by-client";
      if (codingPane === "mue") loadMues();
      else loadCoding();
      render();
      return;
    }
    if (ev.target.closest("[data-dbpane]")) {
      dbPane = ev.target.closest("[data-dbpane]").dataset.dbpane;
      render();
      return;
    }
    const regrStop = ev.target.closest("#regr-stop");
    if (regrStop && slug) {
      regrStop.disabled = true;
      await fetch(`/api/clients/${encodeURIComponent(slug)}/regression/stop`, { method: "POST" });
      await loadRegr();
      return;
    }
    const regrBtn = ev.target.closest("#regr-capture, #regr-run");
    if (regrBtn && slug) {
      regrBtn.disabled = true;
      manPane = "regression";
      const resp = await fetch(`/api/clients/${encodeURIComponent(slug)}/regression/run`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ capture: regrBtn.id === "regr-capture" }),
      });
      const data = await resp.json().catch(() => ({}));
      regr = regr || { ok: true, cases: [], job: {} };
      regr.job = { ...(regr.job || {}), ...data, busy: data.ok !== false ? true : !!data.busy };
      if (!data.ok && data.error) regr.job.error = data.error;
      render();
      pollRegr();
      return;
    }
    if (ev.target.closest("#eip-save") && slug) {
      const ver = ($("eip-ver") && $("eip-ver").value) || "";
      ev.target.disabled = true;
      const resp = await fetch(`/api/clients/${encodeURIComponent(slug)}/eip-version`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ eip_version: ver }),
      });
      const data = await resp.json().catch(() => ({}));
      if (!resp.ok) alert(data.error || "Could not save version");
      else state.eip_version = data.eip_version || ver;
      render();
    }
  });

  box.addEventListener("change", async (ev) => {
    if (ev.target.id === "db-table" && slug === "med-rec") {
      dbTable = ev.target.value || "";
      dbRaw = null;
      render();
      if (!dbTable) return;
      const resp = await fetch(`/api/clients/${encodeURIComponent(slug)}/h2/tables/${encodeURIComponent(dbTable)}`, { cache: "no-store" });
      dbRaw = await resp.json().catch(() => ({ ok: false, columns: [], rows: [] }));
      render();
    }
  });
  box.addEventListener("input", (ev) => {
    if (ev.target.id !== "db-filter" && ev.target.id !== "regr-filter" && ev.target.id !== "coding-filter") return;
    if (ev.target.id === "db-filter") dbFilter = ev.target.value || "";
    else if (ev.target.id === "coding-filter") codingFilter = ev.target.value || "";
    else regrFilter = ev.target.value || "";
    const hold = ev.target;
    const start = hold.selectionStart;
    render();
    const again = $(ev.target.id);
    if (again) {
      again.focus();
      again.setSelectionRange(start, start);
    }
  });
  box.addEventListener("submit", async (ev) => {
    if (!ev.target.closest("#people-add") || !slug) return;
    ev.preventDefault();
    const fd = new FormData(ev.target);
    const resp = await fetch(`/api/clients/${encodeURIComponent(slug)}/people`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: fd.get("name") || "", email: fd.get("email") || "" }),
    });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) {
      alert(data.error || "Could not add");
      return;
    }
    state = data;
    render();
  });

  window.pfManage = { open, hide };
})();
