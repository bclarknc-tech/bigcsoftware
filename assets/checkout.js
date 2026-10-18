/* ============================================================
   STRIPE PAYMENT LINKS
   Test mode. To go live, replace these six URLs with the live
   Payment Links. Nothing else on this page needs to change.
   In Stripe, set each link's after-payment redirect to:
   https://bigcsoftware.com/thank-you.html
   ============================================================ */
var STRIPE_PAYMENT_LINKS = {
  "2c-monthly": "https://buy.stripe.com/test_8x2fZae3P3147rm57XgjC00",
  "2c-yearly": "https://buy.stripe.com/test_eVq4gsbVH59cbHC1VLgjC01",
  "6c-monthly": "https://buy.stripe.com/test_4gMfZa7FrdFIdPK2ZPgjC02",
  "6c-yearly": "https://buy.stripe.com/test_7sY8wI6Bn7hk2729odgjC03",
  "state-monthly": "https://buy.stripe.com/test_fZu9AM7FrdFIcLG57XgjC04",
  "state-yearly": "https://buy.stripe.com/test_cNi4gs6BndFIaDygQFgjC05"
};

var BIGCS_PLANS = {
  counties2: {
    monthly: {
      label: "$49.99",
      suffix: "/mo",
      alt: "Or $499.90/yr (2 months free).",
      url: STRIPE_PAYMENT_LINKS["2c-monthly"]
    },
    yearly: {
      label: "$499.90",
      suffix: "/yr",
      alt: "2 months free. That's 10 months at $49.99.",
      url: STRIPE_PAYMENT_LINKS["2c-yearly"]
    }
  },
  counties6: {
    monthly: {
      label: "$99.99",
      suffix: "/mo",
      alt: "Or $999.90/yr (2 months free).",
      url: STRIPE_PAYMENT_LINKS["6c-monthly"]
    },
    yearly: {
      label: "$999.90",
      suffix: "/yr",
      alt: "2 months free. That's 10 months at $99.99.",
      url: STRIPE_PAYMENT_LINKS["6c-yearly"]
    }
  },
  state: {
    monthly: {
      label: "$169.99",
      suffix: "/mo",
      alt: "Or $1,699.90/yr (2 months free).",
      url: STRIPE_PAYMENT_LINKS["state-monthly"]
    },
    yearly: {
      label: "$1,699.90",
      suffix: "/yr",
      alt: "2 months free. That's 10 months at $169.99.",
      url: STRIPE_PAYMENT_LINKS["state-yearly"]
    }
  }
};

(function () {
  var monthlyBtn = document.getElementById("bill-monthly");
  var yearlyBtn = document.getElementById("bill-yearly");
  if (!monthlyBtn || !yearlyBtn) return;

  var period = "monthly";
  var params = new URLSearchParams(window.location.search);
  if (params.get("billing") === "yearly") period = "yearly";

  function render() {
    monthlyBtn.setAttribute("aria-pressed", period === "monthly" ? "true" : "false");
    yearlyBtn.setAttribute("aria-pressed", period === "yearly" ? "true" : "false");
    Object.keys(BIGCS_PLANS).forEach(function (id) {
      var plan = BIGCS_PLANS[id][period];
      var amount = document.querySelector('[data-amount="' + id + '"]');
      var suffix = document.querySelector('[data-suffix="' + id + '"]');
      var alt = document.querySelector('[data-alt="' + id + '"]');
      var link = document.querySelector('[data-plan="' + id + '"]');
      if (amount) amount.textContent = plan.label;
      if (suffix) suffix.textContent = plan.suffix;
      if (alt) alt.textContent = plan.alt;
      if (link) link.href = plan.url;
    });
  }

  monthlyBtn.addEventListener("click", function () {
    period = "monthly";
    render();
  });
  yearlyBtn.addEventListener("click", function () {
    period = "yearly";
    render();
  });
  render();
})();
