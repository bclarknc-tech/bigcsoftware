/* Opt this browser out of GA4 reporting and out of our lead / Google Ads conversions.
   One visit to /?internal=1 stores the flag. /?internal=0 clears it.
   Headless automation (navigator.webdriver) is treated as internal for that page only. */
(function () {
  var NAME = "bigcs_internal";
  var YEAR = 60 * 60 * 24 * 365;
  var ADS_ID = "18566210536";
  var ADS_LABEL = "jBReCLiBrLUdEOjHh5VF";

  function readCookie() {
    var parts = ("; " + document.cookie).split("; " + NAME + "=");
    if (parts.length < 2) return "";
    return decodeURIComponent(parts.pop().split(";").shift() || "");
  }

  function writeCookie(on) {
    document.cookie = on
      ? NAME + "=1; Max-Age=" + YEAR + "; Path=/; SameSite=Lax"
      : NAME + "=; Max-Age=0; Path=/; SameSite=Lax";
  }

  function readStore() {
    try { return window.localStorage.getItem(NAME) === "1"; }
    catch (e) { return false; }
  }

  function writeStore(on) {
    try {
      if (on) window.localStorage.setItem(NAME, "1");
      else window.localStorage.removeItem(NAME);
    } catch (e) {}
  }

  var param = null;
  try { param = new URLSearchParams(window.location.search).get("internal"); }
  catch (e) {}

  if (param === "1") {
    writeCookie(true);
    writeStore(true);
  } else if (param === "0") {
    writeCookie(false);
    writeStore(false);
  }

  var automated = false;
  try { automated = window.navigator.webdriver === true; } catch (e) {}
  window.bigcsInternal = readCookie() === "1" || readStore() || automated;

  if (window.bigcsInternal) {
    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({ traffic_type: "internal" });
    /* gtag() is defined by the snippet below this file. Queue the set now so it
       is already ahead of gtag('config') when that snippet runs. */
    if (typeof window.gtag !== "function") {
      window.gtag = function () { window.dataLayer.push(arguments); };
    }
    window.gtag("set", { traffic_type: "internal" });
    blockAdsHits();
  }

  function text(value) {
    return value == null ? "" : String(value);
  }

  /* True when this browser should not emit generate_lead (or any other lead hit). */
  window.bigcsSkipLead = function (fields) {
    if (window.bigcsInternal === true) return true;
    try { if (window.navigator.webdriver === true) return true; } catch (e) {}
    if (!fields) return false;
    if (text(fields.email).toLowerCase().indexOf("test@") !== -1) return true;
    if (text(fields.name).toLowerCase().indexOf("test@") !== -1) return true;
    for (var key in fields) {
      if (!Object.prototype.hasOwnProperty.call(fields, key)) continue;
      if (text(fields[key]).replace(/^\s+|\s+$/g, "").toLowerCase() === "bigcs-test") return true;
    }
    return false;
  };

  function asText(value) {
    if (value == null) return "";
    try {
      if (typeof value === "string") return value;
      if (typeof URL !== "undefined" && value instanceof URL) return String(value);
      if (typeof URLSearchParams !== "undefined" && value instanceof URLSearchParams) return value.toString();
      if (typeof FormData !== "undefined" && value instanceof FormData) {
        var parts = [];
        value.forEach(function (v, k) { parts.push(k + "=" + v); });
        return parts.join("&");
      }
      if (typeof Request !== "undefined" && value instanceof Request) return value.url;
      if (typeof Blob !== "undefined" && value instanceof Blob) return "";
      return String(value);
    } catch (e) {
      return "";
    }
  }

  /* GTM-P3G3TB7T's only destination is Google Ads AW-18566210536. Its conversion
     (label jBReCLiBrLUdEOjHh5VF) is a copy of the page_view hit on /trial.html.
     The container does not read traffic_type, so drop that account's hits here,
     including the doubleclick transport that omits the id from the URL.
     GA4 (google-analytics.com / analytics.google.com) and gtm.js / gtag.js are left alone. */
  function isAdsHit() {
    for (var i = 0; i < arguments.length; i++) {
      var s = asText(arguments[i]);
      if (!s) continue;
      if (s.indexOf("google-analytics.com") !== -1 || s.indexOf("analytics.google.com") !== -1) continue;
      if (s.indexOf("googletagmanager.com/gtm.js") !== -1 || s.indexOf("googletagmanager.com/gtag/") !== -1) continue;
      if (s.indexOf(ADS_LABEL) !== -1 || s.indexOf(ADS_ID) !== -1 || s.indexOf("AW-" + ADS_ID) !== -1) return true;
      if (s.indexOf("doubleclick.net") !== -1 || s.indexOf("googleadservices.com") !== -1) return true;
    }
    return false;
  }

  function blockAdsHits() {
    if (typeof window.fetch === "function") {
      var origFetch = window.fetch;
      window.fetch = function (input, init) {
        var url = input;
        if (input && typeof input === "object" && "url" in input) url = input.url;
        if (isAdsHit(url, init && init.body)) {
          try { return Promise.resolve(new Response("", { status: 204 })); }
          catch (e) { return Promise.resolve(); }
        }
        return origFetch.apply(this, arguments);
      };
    }

    try {
      var beaconDesc = window.Navigator && Object.getOwnPropertyDescriptor(Navigator.prototype, "sendBeacon");
      if (beaconDesc && typeof beaconDesc.value === "function" && beaconDesc.configurable) {
        var origBeacon = beaconDesc.value;
        Object.defineProperty(Navigator.prototype, "sendBeacon", {
          configurable: true,
          writable: true,
          value: function (url, data) {
            if (isAdsHit(url, data)) return true;
            return origBeacon.apply(this, arguments);
          }
        });
      }
    } catch (e) {}

    var origOpen = XMLHttpRequest.prototype.open;
    var origSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.open = function (method, url) {
      this.__bigcsAdsUrl = url;
      return origOpen.apply(this, arguments);
    };
    XMLHttpRequest.prototype.send = function (body) {
      if (isAdsHit(this.__bigcsAdsUrl, body)) return;
      return origSend.apply(this, arguments);
    };

    function patchSrc(proto) {
      if (!proto) return;
      var desc = Object.getOwnPropertyDescriptor(proto, "src");
      if (!desc || typeof desc.set !== "function" || typeof desc.get !== "function" || !desc.configurable) return;
      Object.defineProperty(proto, "src", {
        configurable: true,
        enumerable: desc.enumerable,
        get: desc.get,
        set: function (value) {
          if (isAdsHit(value)) return;
          return desc.set.call(this, value);
        }
      });
    }
    patchSrc(window.HTMLImageElement && HTMLImageElement.prototype);
    patchSrc(window.HTMLScriptElement && HTMLScriptElement.prototype);

    var origAttr = Element.prototype.setAttribute;
    Element.prototype.setAttribute = function (name, value) {
      if (String(name).toLowerCase() === "src" && isAdsHit(value)) return;
      return origAttr.apply(this, arguments);
    };
  }
})();
