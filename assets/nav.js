(function () {
  var toggle = document.querySelector(".nav-toggle");
  var nav = document.querySelector("nav");
  var panel = document.getElementById("site-nav");
  if (!toggle || !nav || !panel) return;

  function setOpen(open) {
    nav.classList.toggle("nav-open", open);
    toggle.setAttribute("aria-expanded", open ? "true" : "false");
  }

  toggle.addEventListener("click", function () {
    setOpen(toggle.getAttribute("aria-expanded") !== "true");
  });

  panel.addEventListener("click", function (event) {
    if (event.target.closest("a")) setOpen(false);
  });

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") setOpen(false);
  });

  window.addEventListener("resize", function () {
    if (window.innerWidth > 980) setOpen(false);
  });
})();
