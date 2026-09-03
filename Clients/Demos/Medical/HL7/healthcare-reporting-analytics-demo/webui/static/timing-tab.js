/* Sandbox Timing tab — load after app.js. Playbook §4.1 / §6.6. */
(function () {
  const OTHER_TABS = [
    "tab-demo",
    "tab-routes",
    "tab-experience",
    "tab-xslt",
    "tab-info",
    "tab-video",
    "tab-clinic",
    "tab-eligibility",
  ];

  let timingLoaded = false;

  function esc(s) {
    return String(s ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function fmtWhen(iso) {
    if (!iso) return "—";
    try {
      return new Date(iso).toLocaleString();
    } catch {
      return String(iso);
    }
  }

  function listBlock(title, items) {
    const arr = Array.isArray(items) ? items.filter(Boolean) : [];
    if (!arr.length) return "";
    return `<div class="timing-block"><h3>${esc(title)}</h3><ul>${arr
      .map((x) => `<li>${esc(x)}</li>`)
      .join("")}</ul></div>`;
  }

  function deriveSummary(t, phases) {
    // Wall-clock from earliest start → latest end when top-level fields were left null.
    let started = t.started_at || null;
    let completed = t.completed_at || null;
    for (const p of phases) {
      if (p.started_at && (!started || p.started_at < started)) started = p.started_at;
      if (p.ended_at && (!completed || p.ended_at > completed)) completed = p.ended_at;
    }
    let mins = Number(t.duration_minutes);
    if (!Number.isFinite(mins) || mins <= 0) {
      if (started && completed) {
        mins = Math.max(
          1,
          Math.round((new Date(completed) - new Date(started)) / 60000)
        );
      } else {
        mins = null;
      }
    }
    return {
      started_at: started,
      completed_at: completed,
      duration_minutes: mins,
      completed_by: t.completed_by || null,
    };
  }

  function renderTiming(data) {
    const t = data.timing || data;
    const phases = Array.isArray(t.phases) ? t.phases : [];
    const summary = deriveSummary(t, phases);
    const maxMin = Math.max(
      1,
      ...phases.map((p) => Number(p.duration_minutes) || 0),
      Number(summary.duration_minutes) || 0
    );
    const docker = t.docker_at_completion || {};
    const slow = Array.isArray(t.slowest_phases) ? t.slowest_phases : [];
    const phaseName = (id) => {
      const hit = phases.find((p) => p.id === id);
      return hit?.name || id;
    };

    const phaseRows = phases
      .map((p) => {
        const mins = Number(p.duration_minutes) || 0;
        const pct = Math.max(4, Math.round((mins / maxMin) * 100));
        return `<div class="timing-phase">
        <div class="timing-phase-meta">
          <strong>${esc(p.name || p.id)}</strong>
          <span>${mins} min</span>
        </div>
        <div class="timing-bar"><span style="width:${pct}%"></span></div>
        <div class="timing-phase-sub muted">${esc(fmtWhen(p.started_at))} → ${esc(fmtWhen(p.ended_at))}${
          p.notes ? ` · ${esc(p.notes)}` : ""
        }</div>
      </div>`;
      })
      .join("");

    const slowHtml = slow.length
      ? `<ol class="timing-slow">${slow
          .map(
            (s) =>
              `<li><strong>${esc(phaseName(s.id))}</strong> — ${Number(s.duration_minutes) || 0} min</li>`
          )
          .join("")}</ol>`
      : "";

    const containers = Array.isArray(docker.this_demo_containers)
      ? docker.this_demo_containers
      : [];
    const projects = Array.isArray(docker.running_projects) ? docker.running_projects : [];

    return `
    <div class="timing-hero">
      <div>
        <p class="timing-kicker">${esc(t.interface || t.slug || "Interface")}</p>
        <p class="timing-duration">${summary.duration_minutes ?? "—"} <span>minutes</span></p>
        <p class="muted">${esc(fmtWhen(summary.started_at))} → ${esc(fmtWhen(summary.completed_at))}</p>
      </div>
      <dl class="timing-facts">
        <div><dt>Slug</dt><dd><code>${esc(t.slug || "")}</code></dd></div>
        <div><dt>Compose project</dt><dd><code>${esc(t.compose_project || "")}</code></dd></div>
        <div><dt>Completed by</dt><dd>${esc(summary.completed_by || "—")}</dd></div>
        <div><dt>Path</dt><dd><code>${esc(t.path || "")}</code></dd></div>
      </dl>
    </div>
    <div class="timing-block">
      <h3>Phases</h3>
      ${phaseRows || "<p class='muted'>No phases recorded.</p>"}
    </div>
    <div class="timing-grid">
      <div class="timing-block">
        <h3>Slowest phases</h3>
        ${slowHtml || "<p class='muted'>None listed.</p>"}
      </div>
      ${listBlock("Bottlenecks", t.bottlenecks)}
      ${listBlock("Speedup ideas", t.speedup_ideas)}
    </div>
    <div class="timing-block">
      <h3>Docker at completion</h3>
      <p class="muted">Sandbox projects: <strong>${esc(docker.sandbox_compose_projects_running ?? "—")}</strong>
        · containers: <strong>${esc(docker.sandbox_demo_containers_running ?? "—")}</strong>
        ${docker.captured_at ? ` · captured ${esc(fmtWhen(docker.captured_at))}` : ""}</p>
      ${
        containers.length
          ? `<p><strong>This demo:</strong> ${containers.map((c) => `<code>${esc(c)}</code>`).join(" ")}</p>`
          : ""
      }
      ${
        projects.length
          ? `<p><strong>Running projects:</strong> ${projects.map((p) => `<code>${esc(p)}</code>`).join(" ")}</p>`
          : ""
      }
      ${docker.inventory_command ? `<p class="muted"><code>${esc(docker.inventory_command)}</code></p>` : ""}
    </div>`;
  }

  async function loadTimingTab(force) {
    const root = document.getElementById("timing-root");
    const status = document.getElementById("timing-status");
    if (!root) return;
    if (timingLoaded && !force) return;
    if (status) status.textContent = "Loading…";
    try {
      const res = await fetch("/api/build-timing");
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        root.innerHTML = `<p class="muted">No <code>documents/build-timing.json</code> yet.
          Copy <code>docs/templates/build-timing.example.json</code> and fill phases per playbook §4.1.</p>
          <p class="muted">${esc(data.error || res.statusText)}</p>`;
        timingLoaded = true;
        if (status) status.textContent = "Not recorded yet";
        return;
      }
      root.innerHTML = renderTiming(data);
      timingLoaded = true;
      if (status) status.textContent = data.path ? `Loaded ${data.path}` : "";
    } catch (e) {
      root.innerHTML = `<p class="muted">Failed to load build timing.</p>`;
      if (status) status.textContent = e.message || String(e);
    }
  }

  function setTabButtons(active) {
    document.querySelectorAll("[data-main-tab], [data-tab]").forEach((b) => {
      const id = b.dataset.mainTab || b.dataset.tab;
      const on = id === active;
      b.classList.toggle("active", on);
      if (b.getAttribute("role") === "tab" || b.hasAttribute("aria-selected")) {
        b.setAttribute("aria-selected", on ? "true" : "false");
      }
    });
  }

  function showTimingOnly() {
    OTHER_TABS.forEach((id) => {
      const el = document.getElementById(id);
      if (el) el.hidden = true;
    });
    const timing = document.getElementById("tab-timing");
    if (timing) timing.hidden = false;
    const nav = document.getElementById("demo-nav");
    if (nav) nav.hidden = true;
    document.body.classList.remove("routes-mode");
    setTabButtons("timing");
    loadTimingTab(false);
  }

  function hideTiming() {
    const timing = document.getElementById("tab-timing");
    if (timing) timing.hidden = true;
  }

  function wire() {
    if (!document.getElementById("tab-timing")) return;

    document.addEventListener("click", (ev) => {
      const btn = ev.target.closest("[data-main-tab], [data-tab]");
      if (!btn) return;
      const tab = btn.dataset.mainTab || btn.dataset.tab;
      if (tab === "timing") {
        // After app.js handlers (if any), enforce Timing view
        queueMicrotask(showTimingOnly);
      } else {
        queueMicrotask(hideTiming);
      }
    });

    const refresh = document.getElementById("timing-refresh-btn");
    if (refresh) {
      refresh.addEventListener("click", () => {
        timingLoaded = false;
        loadTimingTab(true);
      });
    }

    // Patch setMainTab when demos define it
    if (typeof window.setMainTab === "function") {
      const orig = window.setMainTab;
      window.setMainTab = function patchedSetMainTab(tab) {
        const r = orig.apply(this, arguments);
        const timing = document.getElementById("tab-timing");
        if (timing) timing.hidden = tab !== "timing";
        if (tab === "timing") loadTimingTab(false);
        else hideTiming();
        return r;
      };
    }

    if (location.hash === "#timing") {
      queueMicrotask(showTimingOnly);
    }
  }

  window.TimingTab = { load: loadTimingTab, show: showTimingOnly };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", wire);
  } else {
    wire();
  }
})();
