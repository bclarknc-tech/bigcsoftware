/* GA4 events: Buy clicks and trial links. No personal data is sent. */
(function () {
  function send(name, params) {
    if (typeof window.gtag !== "function") return;
    params.transport_type = "beacon";
    window.gtag("event", name, params);
  }
  function txt(el) { return (el && el.textContent || "").replace(/\s+/g, " ").trim(); }
  document.addEventListener("click", function (e) {
    var a = e.target && e.target.closest ? e.target.closest("a[href]") : null;
    if (!a) return;
    var href = a.href || "";
    var label = txt(a);
    if (href.indexOf("buy.stripe.com") !== -1) {
      var p = { page_path: location.pathname, link_text: label, link_url: href };
      var row = a.closest("tr");
      var card = a.closest(".price-card, section");
      var plan = "";
      if (row) { var th = row.querySelector("th"); if (th) plan = txt(th.firstChild); }
      else if (card) { var t = card.querySelector(".tier, h2, h3"); if (t) plan = txt(t); }
      if (plan) p.plan_name = plan;
      if (/monthly/i.test(label)) p.billing = "monthly";
      else if (/yearly/i.test(label)) p.billing = "yearly";
      send("begin_checkout", p);
    } else if (a.pathname === "/trial.html" && a.host === location.host) {
      send("trial_cta_click", { page_path: location.pathname, link_text: label });
    }
  }, true);
})();
