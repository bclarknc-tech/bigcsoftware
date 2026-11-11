(function () {
  if (!document.body.classList.contains("mock-combo")) return;
  var main = document.querySelector("main");
  if (!main) return;
  var band = document.querySelector(".mock-hero-band");
  if (!band) {
    band = document.createElement("div");
    band.className = "mock-hero-band";
    band.setAttribute("aria-hidden", "true");
    var pat = document.createElement("div");
    pat.className = "mock-hero-pattern";
    var img = document.createElement("img");
    img.src = "/assets/plat-lots.svg";
    img.alt = "";
    img.width = 1200;
    img.height = 640;
    pat.appendChild(img);
    band.appendChild(pat);
    main.insertBefore(band, main.firstChild);
  }
  function layout() {
    var copy = document.querySelector(".hero-copy");
    var demo = document.querySelector(".demo");
    if (!copy || !demo) return;
    var end = Math.max(copy.getBoundingClientRect().bottom, demo.getBoundingClientRect().bottom) + 64;
    band.style.top = "0px";
    band.style.height = Math.max(0, end - main.getBoundingClientRect().top) + "px";
  }
  layout();
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(layout);
  window.addEventListener("resize", layout);
  window.addEventListener("load", layout);
})();
