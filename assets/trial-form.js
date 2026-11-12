(function(){
// ===== CONFIG. If either value is set back to a "PLACEHOLDER..." string, the form never submits. =====
var TRIAL_ENDPOINT_URL="https://bigcs-license.bigcs.workers.dev/v1/trial/request"; // Worker endpoint (POST JSON)
var TURNSTILE_SITE_KEY="0x4AAAAAAFpF0eX9jM5cZmgJ";   // Cloudflare Turnstile site key (invisible)
// ======================================================================================================
var LIVE=TRIAL_ENDPOINT_URL.indexOf("PLACEHOLDER")<0&&TURNSTILE_SITE_KEY.indexOf("PLACEHOLDER")<0;
var MAIL='<a href="mailto:sales@bigcsoftware.com?subject=BIGCS%20trial%20request">sales@bigcsoftware.com</a>';
var f=document.getElementById("trial-form"),st=document.getElementById("t-status"),btn=document.getElementById("t-submit"),
    sSel=document.getElementById("t-state"),cSel=document.getElementById("t-county"),t0=Date.now(),tsToken="";
var C=window.BIGCS_TRIAL_COUNTIES||{};
sSel.addEventListener("change",function(){var l=C[sSel.value]||[];cSel.innerHTML='<option value="">'+(sSel.value?"Select a county":"Select a state first")+'</option>';
  l.forEach(function(n){var o=document.createElement("option");o.textContent=n;cSel.appendChild(o)});cSel.disabled=!l.length;});

function msg(cls,h){st.className="f-status"+(cls?" "+cls:"");st.innerHTML=h}
// Bot check (Cloudflare Turnstile). If it errors, is blocked, or gives no token within TS_WAIT ms,
// show the fallback box (Retry + phone + email). An expired token is cleared and the widget reset.
var TS_WAIT=12000,tsTimer=0,tsFailed=false,fb=document.getElementById("t-ts-fallback"),fbRetry=document.getElementById("t-ts-retry");
function tsShowFallback(){tsFailed=true;clearTimeout(tsTimer);if(fb)fb.hidden=false}
function tsHideFallback(){tsFailed=false;if(fb)fb.hidden=true}
function tsWatch(){clearTimeout(tsTimer);tsTimer=setTimeout(function(){if(!tsToken)tsShowFallback()},TS_WAIT)}
function tsLoad(){var old=document.getElementById("t-ts-script");if(old)old.parentNode.removeChild(old);
  var s=document.createElement("script");s.id="t-ts-script";s.src="https://challenges.cloudflare.com/turnstile/v0/api.js";s.async=true;s.defer=true;
  s.onerror=tsShowFallback;document.head.appendChild(s);tsWatch()}
function tsRetry(){tsHideFallback();tsToken="";if(st.className.indexOf("err")>=0)msg("","");
  if(window.turnstile){try{turnstile.reset();tsWatch();return}catch(e){}}
  tsLoad()}
if(LIVE){window.bigcsTs=function(t){tsToken=t;clearTimeout(tsTimer);tsHideFallback()};
  window.bigcsTsError=function(){tsToken="";tsShowFallback();return true};
  window.bigcsTsExpired=function(){tsToken="";if(window.turnstile)try{turnstile.reset();tsWatch()}catch(e){}};
  window.bigcsTsTimeout=function(){tsToken="";tsShowFallback()};
  var w=document.getElementById("t-turnstile");w.setAttribute("data-sitekey",TURNSTILE_SITE_KEY);w.setAttribute("data-size","invisible");w.setAttribute("data-callback","bigcsTs");
  w.setAttribute("data-error-callback","bigcsTsError");w.setAttribute("data-expired-callback","bigcsTsExpired");w.setAttribute("data-timeout-callback","bigcsTsTimeout");
  if(fbRetry)fbRetry.addEventListener("click",tsRetry);
  tsLoad();}
else{msg("","Online trial requests open soon. Until then, email "+MAIL+" to ask about a trial.");}
var RL="bigcsTrialSends",THANKS_URL="/thank-you.html?type=trial",sent=false;
function recent(){try{return (JSON.parse(localStorage.getItem(RL))||[]).filter(function(t){return Date.now()-t<3600e3})}catch(e){return[]}}
// Optional phone: empty is fine. Otherwise it must be a 10-digit US number (a leading 1 / +1 is allowed)
// or an international number starting with + and 8-15 digits. Returns "" when OK, else the message to show.
var ph=document.getElementById("t-phone"),phErr=document.getElementById("t-phone-err");
function phoneProblem(raw){var p=String(raw||"").trim();if(!p)return "";
  var d=p.replace(/\s*(x|ext\.?)\s*\d+$/i,"");
  if(/[^\d\s().+-]/.test(d)||/.\+/.test(d))return "Please enter a valid phone number, or leave it blank.";
  var dg=d.replace(/\D/g,"");
  if(d.charAt(0)==="+"){if(dg.length>=8&&dg.length<=15&&(dg.charAt(0)!=="1"||dg.length===11))return "";}
  else if(/^1?\d{10}$/.test(dg))return "";
  if(dg.length===7&&d.charAt(0)!=="+")return "Please include your area code.";
  return "Please enter a valid phone number, or leave it blank."}
function phoneShow(m){if(!ph||!phErr)return;phErr.textContent=m;phErr.hidden=!m;if(m)ph.setAttribute("aria-invalid","true");else ph.removeAttribute("aria-invalid")}
if(ph)ph.addEventListener("input",function(){if(phErr&&!phErr.hidden&&!phoneProblem(ph.value)){phoneShow("");if(st.className.indexOf("err")>=0)msg("","")}});
function check(){var v=function(id){return document.getElementById(id).value.trim()},e=[];
  var n=v("t-name");if(n.length<2)e.push("your full name");
  if(!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v("t-email")))e.push("a valid work email");
  if(v("t-company").length<2)e.push("your company name");
  if(!sSel.value)e.push("a state");if(!cSel.value)e.push("a county");
  if(!document.getElementById("t-consent").checked)e.push("your agreement to be contacted");return e}
f.addEventListener("submit",function(ev){ev.preventDefault();
  var pm=ph?phoneProblem(ph.value):"";phoneShow(pm);
  var e=check();if(e.length){msg("err","Please enter "+e.join(", ")+".");return}
  if(pm){msg("err",pm);ph.focus();return}
  if(f.website.value){msg("err","Sorry, that did not go through. Please email "+MAIL+".");return}
  if(Date.now()-t0<3000){msg("err","Please take a moment to check your details, then try again.");return}
  if(!LIVE){msg("","Online trial requests open soon. Until then, email "+MAIL+" to ask about a trial.");return}
  if(recent().length>=3){msg("err","You've sent several requests already. We'll be in touch, or email "+MAIL+".");return}
  if(!tsToken){if(tsFailed){msg("err","The security check didn't finish. Use Retry below, or call or email us.");return}msg("err","Still checking your browser. Please wait a moment and try again.");tsWatch();return}
  btn.disabled=true;msg("","Sending...");
  var data={};new FormData(f).forEach(function(v,k){data[k]=v});data.email=data.email.trim().toLowerCase();data["cf-turnstile-response"]=tsToken;
  var FAIL="Couldn't send that. Email "+MAIL+" to ask about a trial.";
  var LBL={name:"your full name",email:"your work email",company:"your company name",phone:"your phone number",state:"your state",county:"your county",consent:"your agreement to be contacted",source:"how you heard about us"};
  fetch(TRIAL_ENDPOINT_URL,{method:"POST",headers:{"Content-Type":"application/json","Accept":"application/json"},body:JSON.stringify(data)})
  .then(function(r){return r.json().catch(function(){return {}}).then(function(j){
    if(r.ok&&j.status==="ok"){var l=recent();l.push(Date.now());localStorage.setItem(RL,JSON.stringify(l));var em=data.email.replace(/[<>&"]/g,"");
      msg("ok","Thanks. We've received your request. A confirmation email is on its way to "+em+", and we'll reply there. Check your spam folder if you don't see it.");
      sent=true;var went=false;function go(){if(went)return;went=true;window.location.assign(THANKS_URL)}
      if(typeof window.gtag==="function"&&!(window.bigcsSkipLead&&window.bigcsSkipLead(data))){
        /* Don't pass event_callback:go — gtag can fire it before the Ads conversion
           fetch (AW-18566210536/TyBICMWx1LUdEOjHh5VF) finishes, and the redirect aborts the hit. */
        window.gtag("event","generate_lead",{form:"trial",state:String(data.state||"")});
        setTimeout(go,1500)}
      else go();
      return}
    var s=j.status||"";
    if(r.status===429||s==="rate_limited")throw "Too many requests from your connection right now. Please try again later, or email "+MAIL+".";
    if(s==="invalid"&&j.fields&&j.fields.length)throw "Please check "+j.fields.map(function(k){return LBL[k]||k}).join(", ")+".";
    if(s==="turnstile_failed"||s==="turnstile_missing")throw "We couldn't confirm your browser. Please reload the page and try again, or email "+MAIL+".";
    throw FAIL;})})
  .catch(function(x){msg("err",typeof x==="string"?x:FAIL)})
  .then(function(){if(sent)return;btn.disabled=false;tsToken="";if(window.turnstile)try{turnstile.reset();tsWatch()}catch(e){}});});
})();
