async function getJson(url, opts) {
  const res = await fetch(url, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
}

function setStatus(msg, isError) {
  const el = document.getElementById("status");
  el.textContent = msg || "";
  el.style.color = isError ? "#fca5a5" : "";
}

function renderFiles(containerId, viewId, files) {
  const list = document.getElementById(containerId);
  const view = document.getElementById(viewId);
  list.innerHTML = "";
  if (!files.length) {
    view.textContent = "(none yet)";
    return;
  }
  files.slice(0, 12).forEach((f, i) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.textContent = f.name;
    btn.addEventListener("click", () => {
      [...list.querySelectorAll("button")].forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      view.textContent = f.content;
    });
    list.appendChild(btn);
    if (i === 0) {
      btn.classList.add("active");
      view.textContent = f.content;
    }
  });
}

async function refresh() {
  const [json, archive] = await Promise.all([
    getJson("/api/json"),
    getJson("/api/archive"),
  ]);
  renderFiles("json-list", "json-view", json.files || []);
  renderFiles("archive-list", "archive-view", archive.files || []);
}

async function loadSamples() {
  const data = await getJson("/api/samples");
  const select = document.getElementById("sample");
  (data.files || []).forEach((f) => {
    const opt = document.createElement("option");
    opt.value = f.name;
    opt.textContent = f.name;
    select.appendChild(opt);
  });
  select.addEventListener("change", () => {
    const name = select.value;
    const match = (data.files || []).find((f) => f.name === name);
    document.getElementById("csv").value = match ? match.content : "";
  });
}

document.getElementById("inject-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const sample = document.getElementById("sample").value;
  const csv = document.getElementById("csv").value;
  setStatus("Submitting…");
  try {
    const result = await getJson("/api/inject", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sample, csv }),
    });
    setStatus(`Dropped ${result.file}. Waiting for JSON…`);
    const waited = await getJson(
      `/api/wait-json?file=${encodeURIComponent(result.file)}&timeout=60`
    );
    setStatus(`Wrote ${waited.file?.name || "JSON"}`);
    await refresh();
  } catch (err) {
    setStatus(err.message || String(err), true);
  }
});

document.getElementById("refresh-btn").addEventListener("click", () => {
  refresh().catch((err) => setStatus(err.message, true));
});

document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => {
    const tab = btn.dataset.mainTab;
    document.querySelectorAll(".main-tab").forEach((b) => {
      b.classList.toggle("active", b === btn);
      b.setAttribute("aria-selected", b === btn ? "true" : "false");
    });
    document.getElementById("tab-demo").hidden = tab !== "demo";
    document.getElementById("tab-routes").hidden = tab !== "routes";
    const xslt = document.getElementById("tab-xslt");
    if (xslt) xslt.hidden = tab !== "xslt";
    const nav = document.getElementById("demo-nav");
    if (nav) nav.style.display = tab === "demo" ? "" : "none";
  });
});

loadSamples().catch(console.error);
refresh().catch(console.error);
