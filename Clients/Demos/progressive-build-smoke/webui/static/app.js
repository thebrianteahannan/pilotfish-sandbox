
document.querySelectorAll(".main-tab").forEach((btn) => {
  btn.addEventListener("click", () => {
    const tab = btn.dataset.mainTab;
    document.querySelectorAll(".main-tab").forEach((b) => {
      b.classList.toggle("active", b === btn);
    });
    const routes = document.getElementById("tab-routes");
    const timing = document.getElementById("tab-timing");
    const info = document.getElementById("tab-info");
    if (routes) routes.hidden = tab !== "routes";
    if (timing) timing.hidden = tab !== "timing";
    if (info) info.hidden = tab !== "info";
  });
});
