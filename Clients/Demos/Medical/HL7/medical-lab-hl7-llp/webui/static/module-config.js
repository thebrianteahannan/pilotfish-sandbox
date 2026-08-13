/**
 * Parse and render PilotFish modules/*.xml for the route viewer.
 */
(function (global) {
  const TAG_KIND = {
    Listener: "listener",
    Processor: "processor",
    Transport: "transport",
    RoutingModule: "routing",
    Transform: "transform",
    "Post-Processor": "post-processor",
    PostProcessor: "post-processor",
  };

  const CONFIG_GROUPS = [
    {
      id: "basic",
      title: "Basic",
      keys: [
        "RequestPath",
        "Timeout",
        "TimeoutHandlingMechanism",
        "Synchronous",
        "RequireSSL",
        "HTTPHeaders",
        "SoapVersion",
        "PollingInterval",
        "TargetDirectory",
        "SourceDirectory",
        "FileName",
        "ExecuteProcessor",
        "AttributeScope",
        "ServiceName",
        "CallbackListenerName",
        "SelectionMode",
      ],
    },
    {
      id: "wsdl",
      title: "WSDL",
      keys: ["WsdlFile", "WsdlContentType", "ValidateAtListenerLevel"],
    },
    {
      id: "auth",
      title: "Authentication",
      keys: ["USE_BASIC_AUTH", "AUTH_FILE", "REALM"],
    },
    {
      id: "xpath",
      title: "XPath / Expressions",
      keys: [
        "XPathExpressions",
        "GlobalAttributeExpressions",
        "Namespaces",
        "Namespace",
        "XPath1Compatibility",
      ],
    },
    {
      id: "throttling",
      title: "Throttling",
      prefix: "Throttling",
    },
    {
      id: "inactivity",
      title: "Inactivity",
      keys: [
        "CheckInactivity",
        "InactivityTransactionCount",
        "InactivityPolling",
        "MonitoringTime",
        "InactivityExcludedDays",
        "InactivityIncludeErrors",
      ],
      prefix: "Inactivity",
    },
    {
      id: "advanced",
      title: "Advanced",
      keys: [
        "IS_TRIGGERABLE_LISTENER",
        "CLIAllowed",
        "RESTART_ON_ERROR_TAG",
        "FIFOQueueName",
        "FIFOQueueDelay",
      ],
      prefix: "TransactionLogging",
    },
    {
      id: "resources",
      title: "Resources",
      keys: ["AdditionalResources"],
    },
  ];

  function escapeHtml(s) {
    return String(s ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  /** Env props from environment-settings.conf (secrets already redacted by API). */
  let envMap = Object.create(null);
  let envSettingsLoaded = false;
  const SENSITIVE_NAME_RE =
    /password|secret|token|apikey|api[_-]?key|private[_-]?key|passphrase|credential/i;
  const ENV_REF_RE = /\$\$([A-Za-z0-9_.-]+)/g;

  function isSensitiveName(name) {
    return SENSITIVE_NAME_RE.test(String(name || ""));
  }

  async function ensureEnvSettings() {
    if (envSettingsLoaded) return;
    envSettingsLoaded = true;
    try {
      const res = await fetch("/api/v2/environment-settings");
      if (!res.ok) return;
      const data = await res.json();
      envMap = data.settings || {};
    } catch (err) {
      console.warn("Environment settings load failed", err);
    }
  }

  /** Resolve $$ENV_NAME using environment-settings.conf; mask secrets. */
  function resolveEnvRefs(configKey, raw) {
    const text = String(raw ?? "");
    if (!text.includes("$$")) {
      return { display: text, title: text };
    }
    const display = text.replace(ENV_REF_RE, (match, name) => {
      if (isSensitiveName(name) || isSensitiveName(configKey)) return "••••••••";
      if (Object.prototype.hasOwnProperty.call(envMap, name)) return String(envMap[name]);
      return match;
    });
    return {
      display,
      title: display === text ? text : `${text} → ${display}`,
    };
  }

  function decodeXmlEntities(s) {
    return String(s ?? "")
      .replace(/&amp;/g, "&")
      .replace(/&quot;/g, '"')
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&#39;/g, "'")
      .replace(/&apos;/g, "'");
  }

  function friendlyAttr(name) {
    if (name === "com.pilotfish.FileName") return "sourceFileName";
    return name;
  }

  function extractOgnl(raw) {
    const text = decodeXmlEntities(String(raw ?? "").trim());
    const m = text.match(/^\{ognl:([\s\S]*)\}$/i);
    if (!m) return null;
    return { full: `{ognl:${m[1]}}`, expr: m[1].trim() };
  }

  /** Short human reading of common PilotFish OGNL patterns. */
  function summarizeOgnlExpr(expr) {
    const e = decodeXmlEntities(expr).replace(/\s+/g, " ").trim();

    let m = e.match(
      /^'([^']*)'\s*\+\s*@java\.lang\.System@currentTimeMillis\(\)\s*\+\s*'([^']*)'$/
    );
    if (m) return `${m[1]}<timestamp>${m[2]}`;

    m = e.match(/^getAttribute\('([^']+)'\)\s*\+\s*'([^']*)'$/);
    if (m) return `{${friendlyAttr(m[1])}}${m[2]}`;

    m = e.match(/^getAttribute\('([^']+)'\)$/);
    if (m) return `{${friendlyAttr(m[1])}}`;

    if (
      /getAttribute\('ClaimId'\)\s*!=\s*null/.test(e) &&
      (/isEmpty\(\)/.test(e) || /trim\(\)/.test(e))
    ) {
      return "only when ClaimId is set";
    }

    if (/#xpath\(/.test(e) && /IsBatch/.test(e)) {
      return "only when //IsBatch is true/1";
    }

    m = e.match(/^getAttribute\('([^']+)'\)\s*==\s*'([^']+)'$/);
    if (m) return `only when {${friendlyAttr(m[1])}} is '${m[2]}'`;

    // Template-style concatenations of attrs + literals (+ optional timestamp)
    if (/getAttribute\(/.test(e) && e.includes("+") && !/[!<>=]|&&|\|\|/.test(e)) {
      const bits = [];
      let ok = true;
      for (const tok of e.split(/\s*\+\s*/)) {
        const t = tok.trim();
        if ((m = t.match(/^getAttribute\('([^']+)'\)$/))) {
          bits.push(`{${friendlyAttr(m[1])}}`);
        } else if ((m = t.match(/^'([^']*)'$/))) {
          bits.push(m[1]);
        } else if (t === "@java.lang.System@currentTimeMillis()") {
          bits.push("<timestamp>");
        } else {
          ok = false;
          break;
        }
      }
      if (ok && bits.length) return bits.join("");
    }

    return e
      .replace(/@java\.lang\.System@currentTimeMillis\(\)/g, "currentTimeMillis()")
      .replace(/getAttribute\('([^']+)'\)/g, (_, a) => `attr(${friendlyAttr(a)})`)
      .replace(/#xpath\("([^"]+)"\)/g, "xpath($1)")
      .replace(/@java\.lang\.String@valueOf\(([^)]+)\)/g, "String($1)")
      .replace(/&&/g, " and ")
      .replace(/\|\|/g, " or ");
  }

  function describeValue(configKey, raw) {
    const resolved = resolveEnvRefs(configKey, raw);
    const ognl = extractOgnl(resolved.display);
    if (!ognl) {
      return {
        kind: "plain",
        display: resolved.display,
        title: resolved.title,
        summary: null,
        full: null,
      };
    }
    const summary = summarizeOgnlExpr(ognl.expr);
    return {
      kind: "ognl",
      display: summary,
      summary,
      full: ognl.full,
      title: `${summary}\n${ognl.full}`,
    };
  }

  function parseEipPairs(raw) {
    if (!raw || !String(raw).includes("eip_pair")) return null;
    const pairs = [];
    const re = /\[eip_pair:(.*?):eip_name:(.*?):eip_value\]/g;
    let m;
    while ((m = re.exec(raw))) {
      pairs.push({ name: m[1], value: m[2] });
    }
    return pairs.length ? pairs : null;
  }

  function formatValue(raw, configKey = "") {
    const pairs = parseEipPairs(raw);
    if (pairs) {
      return (
        `<table class="pair-table"><tbody>` +
        pairs
          .map((p) => {
            const described = describeValue(p.name || configKey, p.value);
            if (described.kind === "ognl") {
              return `<tr><th>${escapeHtml(p.name)}</th><td class="ognl-cell">
                <div class="ognl-summary">${escapeHtml(described.summary)}</div>
                <code class="wrap ognl-raw" title="${escapeHtml(described.full)}">${escapeHtml(described.full)}</code>
              </td></tr>`;
            }
            return `<tr><th>${escapeHtml(p.name)}</th><td><code title="${escapeHtml(described.title)}">${escapeHtml(described.display)}</code></td></tr>`;
          })
          .join("") +
        `</tbody></table>`
      );
    }
    if (raw === "" || raw == null) return `<span class="empty">(empty)</span>`;
    if (raw === "true" || raw === "false") return `<code>${raw}</code>`;
    const described = describeValue(configKey, raw);
    if (described.kind === "ognl") {
      return `<div class="ognl-value">
        <div class="ognl-summary">${escapeHtml(described.summary)}</div>
        <code class="wrap ognl-raw" title="${escapeHtml(described.full)}">${escapeHtml(described.full)}</code>
      </div>`;
    }
    return `<code title="${escapeHtml(described.title)}">${escapeHtml(described.display)}</code>`;
  }

  /** Conservative PilotFish ModuleConfig defaults — values matching these are hidden in "changed" mode. */
  const DEFAULT_CONFIG = {
    IS_TRIGGERABLE_LISTENER: "false",
    CLIAllowed: "false",
    RESTART_ON_ERROR_TAG: "false",
    StopWhenPollingFailure: "true",
    FIFOQueueName: "",
    FIFOQueueDelay: "500",
    TransactionLoggingAllowed: "false",
    TransactionLoggingStoreData: "false",
    TransactionLoggingStoreDataBase64: "false",
    TransactionLoggingStoreAttributes: "false",
    TransactionLoggingLogAllAttributes: "false",
    TransactionLoggingAllowedLoggedAttributes: "",
    CheckInactivity: "false",
    InactivityTransactionCount: "1",
    InactivityPolling: "500",
    InactivityExcludedDays: "",
    InactivityIncludeErrors: "false",
    ThrottlingMode: "None",
    ThrottlingMechanism: "Blocking",
    ThrottlingConcurrentMessages: "1",
    ThrottlingTimedInterval: "1",
    ThrottlingSynchronousTimeout: "60",
    FileNameRestriction: "",
    UseFullFilePath: "Disabled",
    FullPathToFile: "",
    CompatModeMoved: "false",
    Tokenizers: "",
    SerializedTransactionsTag: "1",
    SubFolderIterationTag: "false",
    FullFolderPathRestrictionsTag: "",
    HiddenFilesTag: "false",
    SchedulerStartTag: "",
    SchedulerEndTag: "",
    ExcludeDaysTag: "",
    ExcludeDatesTag: "",
    TimeZone: "System Default",
    MinDaysSinceFileModified: "-1",
    MaxDaysSinceFileModified: "-1",
    CombineFiles: "false",
    HeaderLines: "0",
    SynchResponse: "false",
    Timeout: "60",
    FileSortingMethod: "System Default",
    FileSortingDirection: "Ascending",
    ExecuteProcessor: "true",
    CacheXSLTToXML: "false",
    XSLTEngine: "Saxon",
    XSLTParameters: "null",
    SaxonConverterHandling: "Throw Exception",
    SaxonConverterEncoding: "UTF-8",
    WriteQuery: "false",
    Query: "",
    QueryParams: "",
    UseDataSource: "false",
    DataSource: "",
    KeepConnection: "false",
    Autocommit: "false",
    UseJdbcGeneratedKeys: "true",
    RestrictMetaDataToCatalog: "",
    RestrictMetaDataToSchema: "",
    RestrictMetaDataToTable: "%",
    UseSingleOutputStream: "true",
    RefreshHandler: "false",
    ErrorOnUnknownElement: "false",
    JDBCProperties: "null",
    LogMetadata: "false",
    LogSQL: "false",
    AppendToFile: "Overwrite",
    MAXIMUM_MEMORY_SIZE: "-1",
    FileNameConflictPattern: "",
    BatchSensitive: "false",
    Command: "",
    Shell: "/bin/bash",
    CallbackListenerName: "",
    CallingRoutes: "",
    InputFile: "",
    AttributeScope: "Transaction",
    GlobalAttributes: "BUCKET",
    Namespaces: "null",
    Namespace: "",
    XPath1Compatibility: "false",
    GlobalAttributeExpressions: "",
    Synchronous: "false",
    RequireSSL: "false",
    ExecuteTransformation: "true",
  };

  const INTERESTING_IF_EMPTY = new Set([
    "PollingDirectory",
    "TargetDirectory",
    "XSLTPath",
    "FileName",
    "FileExtension",
    "JdbcURL",
    "JdbcDriver",
    "UserName",
    "Password",
    "ServiceName",
    "InputFile",
    "PollingInterval",
  ]);

  function normalizeConfigValue(v) {
    if (v == null) return "";
    return String(v).trim();
  }

  function isDefaultConfigValue(key, value) {
    const v = normalizeConfigValue(value);
    if (Object.prototype.hasOwnProperty.call(DEFAULT_CONFIG, key)) {
      const d = normalizeConfigValue(DEFAULT_CONFIG[key]);
      if (v.toLowerCase() === d.toLowerCase()) return true;
      return v === d;
    }
    // Unknown keys: empty / null-ish count as default; anything else is a change.
    return v === "" || v.toLowerCase() === "null";
  }

  function summarizeRoutingPorts(xmlEl) {
    if (!xmlEl) return [];
    const rows = [];
    Array.from(xmlEl.querySelectorAll("outputs > output")).forEach((o, idx) => {
      const name = o.getAttribute("name") || `Rule ${idx + 1}`;
      const cond = (o.querySelector("condition")?.textContent || "").trim().replace(/\s+/g, " ");
      rows.push({
        key: name,
        value: cond || "(no condition)",
        special: "routing",
      });
    });
    return rows;
  }

  function getInlineEntries(mod, mode) {
    if (!mod || !mod.config) return [];
    const entries = [];
    mod.config.forEach((e) => {
      if (e.special === "routingPorts") {
        summarizeRoutingPorts(e.xml).forEach((r) => entries.push(r));
        return;
      }
      entries.push({ key: e.key, value: e.value ?? "" });
    });
    if (mode === "all") return entries;
    if (mode === "changed") {
      return entries.filter((e) => {
        if (e.special === "routing") return true;
        if (INTERESTING_IF_EMPTY.has(e.key) && normalizeConfigValue(e.value) !== "") return true;
        return !isDefaultConfigValue(e.key, e.value);
      });
    }
    return [];
  }

  function truncateInline(s, max) {
    const t = String(s ?? "").replace(/\s+/g, " ").trim();
    if (t.length <= max) return t;
    return `${t.slice(0, max - 1)}…`;
  }

  function renderInlineValue(described) {
    if (described.kind === "ognl") {
      // Show readable meaning + full OGNL (lightly truncated only if extremely long).
      const raw = truncateInline(described.full, 160);
      return `<span class="cfg-v cfg-v-stack">
        <span class="cfg-ognl-sum">${escapeHtml(described.summary)}</span>
        <span class="cfg-ognl-raw">${escapeHtml(raw)}</span>
      </span>`;
    }
    return `<span class="cfg-v">${escapeHtml(truncateInline(described.display, 96))}</span>`;
  }

  function renderInlineConfig(mod, mode) {
    if (mode === "compact") return "";
    const entries = getInlineEntries(mod, mode);
    if (!entries.length) {
      return `<div class="route-node-config empty">${mode === "changed" ? "No non-default settings" : "No ModuleConfig"}</div>`;
    }
    const maxRows = 14;
    const shown = entries.slice(0, maxRows);
    const more = entries.length - shown.length;
    return `<div class="route-node-config">
      ${shown
        .map((e) => {
          const described = describeValue(e.key, e.value);
          const rowClass =
            described.kind === "ognl" ? "cfg-inline-row cfg-has-ognl" : "cfg-inline-row";
          return `<div class="${rowClass}" title="${escapeHtml(e.key)}: ${escapeHtml(described.title)}">
              <span class="cfg-k">${escapeHtml(e.key)}</span>
              ${renderInlineValue(described)}
            </div>`;
        })
        .join("")}
      ${more > 0 ? `<div class="cfg-inline-more">+${more} more (see panel)</div>` : ""}
    </div>`;
  }

  function estimateInlineSize(mod, mode, label) {
    if (mode === "compact") {
      const text = String(label || "");
      const width = Math.min(320, Math.max(230, 28 + text.length * 6.4));
      const height = text.length > 36 ? 92 : text.length > 22 ? 80 : 72;
      return { width, height, rows: 0 };
    }
    const entries = getInlineEntries(mod, mode);
    const shown = entries.slice(0, 14);
    let lineUnits = 0;
    let hasOgnl = false;
    shown.forEach((e) => {
      const described = describeValue(e.key, e.value);
      if (described.kind === "ognl") {
        hasOgnl = true;
        const rawLen = (described.full || "").length;
        lineUnits += 1 + Math.min(3, Math.max(1, Math.ceil(rawLen / 48)));
      } else {
        lineUnits += 1;
      }
    });
    if (!shown.length) lineUnits = 1;
    return {
      width: hasOgnl ? 400 : 340,
      height:
        76 +
        lineUnits * 13 +
        (entries.length > 14 ? 16 : 0) +
        (entries.length === 0 ? 8 : 0),
      rows: lineUnits,
    };
  }

  function kindFromTag(tag) {
    return TAG_KIND[tag] || "processor";
  }

  function displayType(mod) {
    if (!mod) return "Module";
    const t = mod.type || "";
    const tag = mod.tag || "";
    if (tag === "Listener" && !/listener/i.test(t)) return `${t} Listener`.trim();
    if (tag === "Processor" && !/processor/i.test(t)) return `${t} Processor`.trim();
    if (tag === "Transport" && !/transport/i.test(t)) return `${t} Transport`.trim();
    return t || tag || "Module";
  }

  function parseModuleXml(xmlText) {
    const doc = new DOMParser().parseFromString(xmlText, "application/xml");
    if (doc.querySelector("parsererror")) throw new Error("Invalid module XML");
    const root = doc.documentElement;
    const config = [];
    const cfg = root.querySelector("ModuleConfig");
    if (cfg) {
      Array.from(cfg.children).forEach((child) => {
        if (child.tagName === "RoutingPorts") {
          config.push({
            key: "RoutingPorts",
            special: "routingPorts",
            xml: child,
          });
          return;
        }
        config.push({
          key: child.tagName,
          value: child.textContent ?? "",
        });
      });
    }
    return {
      id: root.getAttribute("id"),
      name: root.getAttribute("name") || "",
      tag: root.getAttribute("tag") || "",
      type: root.getAttribute("type") || "",
      className: root.getAttribute("class") || "",
      version: root.getAttribute("version") || "",
      kind: kindFromTag(root.getAttribute("tag") || ""),
      displayType: null,
      config,
    };
  }

  function finalizeModule(mod) {
    if (!mod) return mod;
    mod.displayType = displayType(mod);
    return mod;
  }

  function renderRoutingPorts(xmlEl) {
    if (!xmlEl) return "";
    const mode = xmlEl.getAttribute("version") || "";
    const outputs = Array.from(xmlEl.querySelectorAll("outputs > output"));
    const inputs = Array.from(xmlEl.querySelectorAll("inputs > input"));
    let html = `<div class="routing-ports">`;
    if (inputs.length) {
      html += `<div class="rp-block"><div class="rp-label">Inputs</div><ul>`;
      inputs.forEach((i) => {
        html += `<li>${escapeHtml(i.getAttribute("name") || i.getAttribute("id"))}</li>`;
      });
      html += `</ul></div>`;
    }
    outputs.forEach((o, idx) => {
      const cond = o.querySelector("condition")?.textContent || "";
      const nss = Array.from(o.querySelectorAll("namespaces > namespace"))
        .map((n) => `${n.getAttribute("prefix")}=${n.getAttribute("uri")}`)
        .join(", ");
      html += `<div class="rp-rule">
        <div class="rp-title">${escapeHtml(o.getAttribute("name") || `Rule ${idx + 1}`)}
          <span class="badge">${escapeHtml(o.getAttribute("type") || "")}</span>
        </div>
        <div class="config-field"><label>Condition</label><div class="value"><code class="wrap">${escapeHtml(cond)}</code></div></div>
        ${nss ? `<div class="config-field"><label>Namespaces</label><div class="value"><code class="wrap">${escapeHtml(nss)}</code></div></div>` : ""}
      </div>`;
    });
    html += `</div>`;
    return html;
  }

  function groupEntries(entries) {
    const used = new Set();
    const groups = [];
    CONFIG_GROUPS.forEach((g) => {
      const items = [];
      entries.forEach((e) => {
        if (e.special || used.has(e.key)) return;
        const matchKey = g.keys && g.keys.includes(e.key);
        const matchPrefix = g.prefix && e.key.startsWith(g.prefix);
        if (matchKey || matchPrefix) {
          used.add(e.key);
          items.push(e);
        }
      });
      if (items.length) groups.push({ title: g.title, items });
    });
    const rest = entries.filter((e) => !e.special && !used.has(e.key));
    if (rest.length) groups.push({ title: "Other", items: rest });
    const specials = entries.filter((e) => e.special);
    return { groups, specials };
  }

  function renderConfigSections(mod) {
    if (!mod) return `<p class="config-empty">Module XML not found under <code>modules/</code>.</p>`;
    const { groups, specials } = groupEntries(mod.config);
    let html = "";
    specials.forEach((s) => {
      if (s.special === "routingPorts") {
        html += `<details class="cfg-section" open>
          <summary>Routing Ports</summary>
          <div class="cfg-body">${renderRoutingPorts(s.xml)}</div>
        </details>`;
      }
    });
    groups.forEach((g, i) => {
      html += `<details class="cfg-section"${i === 0 && !specials.length ? " open" : ""}>
        <summary>${escapeHtml(g.title)}</summary>
        <div class="cfg-body">
          <table class="cfg-table"><tbody>
            ${g.items
              .map(
                (e) =>
                  `<tr><th>${escapeHtml(e.key)}</th><td>${formatValue(e.value, e.key)}</td></tr>`
              )
              .join("")}
          </tbody></table>
        </div>
      </details>`;
    });
    if (!html) html = `<p class="config-empty">No ModuleConfig entries.</p>`;
    return html;
  }

  function renderSummary(mod, routeName, extra) {
    if (!mod) {
      return `
        <div class="config-field"><label>Name</label><div class="value">${escapeHtml(extra.label || "")}</div></div>
        <div class="config-field"><label>Module ID</label><div class="value"><code>${escapeHtml(extra.moduleId || "")}</code></div></div>
        <p class="config-empty">No matching file in <code>modules/${escapeHtml(extra.moduleId || "")}.xml</code></p>`;
    }
    return `
      <div class="config-field"><label>Selection</label><div class="value"><span class="badge">${escapeHtml(mod.tag || mod.kind)}</span></div></div>
      <div class="config-field"><label>Type</label><div class="value">${escapeHtml(mod.displayType)}</div></div>
      <div class="config-field"><label>Name</label><div class="value">${escapeHtml(mod.name)}</div></div>
      <div class="config-field"><label>Route</label><div class="value">${escapeHtml(routeName || "")}</div></div>
      <div class="config-field"><label>Module Class</label><div class="value"><code class="wrap">${escapeHtml(mod.className)}</code></div></div>
      <div class="config-field"><label>Module ID</label><div class="value"><code class="wrap">${escapeHtml(mod.id)}</code></div></div>
      <h3 class="cfg-heading">${escapeHtml(mod.displayType)}</h3>
      ${renderConfigSections(mod)}
    `;
  }

  async function loadModules(moduleIds) {
    await ensureEnvSettings();
    const base = (global.ROUTE_VIEWER_BASE || ".").replace(/\/$/, "");
    const map = new Map();
    await Promise.all(
      moduleIds.map(async (id) => {
        if (!id) return;
        try {
          const res = await fetch(`${base}/modules/${id}.xml`);
          if (!res.ok) return;
          const mod = finalizeModule(parseModuleXml(await res.text()));
          map.set(id, mod);
        } catch (err) {
          console.warn("Module load failed", id, err);
        }
      })
    );
    return map;
  }

  global.RouteModuleConfig = {
    loadModules,
    ensureEnvSettings,
    resolveEnvRefs,
    describeValue,
    summarizeOgnlExpr,
    renderSummary,
    renderInlineConfig,
    getInlineEntries,
    estimateInlineSize,
    isDefaultConfigValue,
    kindFromTag,
    displayType,
    escapeHtml,
  };
})(window);
