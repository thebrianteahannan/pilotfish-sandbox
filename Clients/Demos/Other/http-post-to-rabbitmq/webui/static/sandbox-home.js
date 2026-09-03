(function () {
  if (document.getElementById("pf-sandbox-home")) return;
  var port = "8077";
  var host = location.hostname || "127.0.0.1";
  if (host === "localhost") host = "127.0.0.1";
  var href = (location.protocol || "http:") + "//" + host + ":" + port + "/";
  if (!document.getElementById("pf-sandbox-home-css")) {
    var style = document.createElement("style");
    style.id = "pf-sandbox-home-css";
    style.textContent =
      ".pf-sandbox-home{margin-left:auto;display:inline-flex;align-items:center;" +
      "font:inherit;font-weight:700;text-decoration:none;color:#fff;" +
      "background:#007cba;border:1px solid #007cba;border-radius:6px;" +
      "padding:0.4rem 0.75rem;white-space:nowrap}" +
      ".pf-sandbox-home:hover{background:#005a87;border-color:#005a87}";
    document.head.appendChild(style);
  }
  var a = document.createElement("a");
  a.id = "pf-sandbox-home";
  a.className = "pf-sandbox-home";
  a.href = href;
  a.textContent = "Sandbox";
  a.title = "Back to the PilotFish Sandbox hub";
  var bar = document.querySelector(".app-bar") || document.querySelector("header");
  if (bar) bar.appendChild(a);
  else document.body.insertBefore(a, document.body.firstChild);
})();
