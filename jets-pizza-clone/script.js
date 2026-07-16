(() => {
  const body = document.body;
  const toggle = document.querySelector(".menu-toggle");
  const drawer = document.getElementById("order");
  const closeBtn = document.querySelector(".drawer-close");

  if (toggle) {
    toggle.addEventListener("click", () => {
      const open = body.classList.toggle("nav-open");
      toggle.setAttribute("aria-expanded", String(open));
      toggle.setAttribute("aria-label", open ? "Close menu" : "Open menu");
    });
  }

  const openOrder = () => {
    if (!drawer) return;
    drawer.hidden = false;
    body.style.overflow = "hidden";
  };

  const closeOrder = () => {
    if (!drawer) return;
    drawer.hidden = true;
    body.style.overflow = "";
  };

  document.querySelectorAll('[data-action="order"], a[href="#order"]').forEach((el) => {
    el.addEventListener("click", (event) => {
      event.preventDefault();
      openOrder();
    });
  });

  closeBtn?.addEventListener("click", closeOrder);
  drawer?.addEventListener("click", (event) => {
    if (event.target === drawer) closeOrder();
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeOrder();
  });

  const revealTargets = document.querySelectorAll(
    ".promo, .rewards, .merch, .franchise"
  );
  revealTargets.forEach((el) => el.classList.add("reveal"));

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.18 }
    );
    revealTargets.forEach((el) => observer.observe(el));
  } else {
    revealTargets.forEach((el) => el.classList.add("is-visible"));
  }
})();
