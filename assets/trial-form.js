(function(){
// ===== CONFIG: replace both placeholders before launch. While either is a placeholder, the form never submits. =====
var TRIAL_ENDPOINT_URL="PLACEHOLDER_TRIAL_ENDPOINT_URL";   // Worker endpoint that receives trial requests (POST JSON)
var TURNSTILE_SITE_KEY="PLACEHOLDER_TURNSTILE_SITE_KEY";   // Cloudflare Turnstile site key (invisible/managed)
// ======================================================================================================
var LIVE=TRIAL_ENDPOINT_URL.indexOf("PLACEHOLDER")<0&&TURNSTILE_SITE_KEY.indexOf("PLACEHOLDER")<0;
var MAIL='<a href="mailto:sales@bigcsoftware.com?subject=BIGCS%20trial%20request">sales@bigcsoftware.com</a>';
var f=document.getElementById("trial-form"),st=document.getElementById("t-status"),btn=document.getElementById("t-submit"),
    sSel=document.getElementById("t-state"),cSel=document.getElementById("t-county"),t0=Date.now(),tsToken="";
var C=window.BIGCS_TRIAL_COUNTIES||{};
sSel.addEventListener("change",function(){var l=C[sSel.value]||[];cSel.innerHTML='<option value="">'+(sSel.value?"Select a county":"Select a state first")+'</option>';
  l.forEach(function(n){var o=document.createElement("option");o.textContent=n;cSel.appendChild(o)});cSel.disabled=!l.length;});
function msg(cls,h){st.className="f-status"+(cls?" "+cls:"");st.innerHTML=h}
if(LIVE){window.bigcsTs=function(t){tsToken=t};var s=document.createElement("script");s.src="https://challenges.cloudflare.com/turnstile/v0/api.js";s.async=true;s.defer=true;
  var w=document.getElementById("t-turnstile");w.setAttribute("data-sitekey",TURNSTILE_SITE_KEY);w.setAttribute("data-size","invisible");w.setAttribute("data-callback","bigcsTs");document.head.appendChild(s);}
else{msg("","Online trial requests open soon. Until then, email "+MAIL+" to ask about a trial.");}
var RL="bigcsTrialSends";
function recent(){try{return (JSON.parse(localStorage.getItem(RL))||[]).filter(function(t){return Date.now()-t<3600e3})}catch(e){return[]}}
function check(){var v=function(id){return document.getElementById(id).value.trim()},e=[];
  var n=v("t-name");if(n.length<2)e.push("your full name");
  if(!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v("t-email")))e.push("a valid work email");
  if(v("t-company").length<2)e.push("your company name");
  var p=v("t-phone");if(p){var d=p.replace(/\s*(x|ext\.?)\s*\d+$/i,"");var ok=/^\+\d{8,15}$/.test(d.replace(/[\s().-]/g,""))||/^1?\d{10}$/.test(d.replace(/[\s().+-]/g,""));if(!ok)e.push("a valid phone number, or leave it blank");}
  if(!sSel.value)e.push("a state");if(!cSel.value)e.push("a county");
  if(!document.getElementById("t-consent").checked)e.push("your agreement to be contacted");return e}
f.addEventListener("submit",function(ev){ev.preventDefault();
  var e=check();if(e.length){msg("err","Please enter "+e.join(", ")+".");return}
  if(f.website.value){msg("err","Sorry, that did not go through. Please email "+MAIL+".");return}
  if(Date.now()-t0<3000){msg("err","Please take a moment to check your details, then try again.");return}
  if(!LIVE){msg("","Online trial requests open soon. Until then, email "+MAIL+" to ask about a trial.");return}
  if(recent().length>=3){msg("err","You've sent several requests already. We'll be in touch, or email "+MAIL+".");return}
  if(!tsToken){msg("err","Still checking your browser. Please wait a moment and try again.");return}
  btn.disabled=true;msg("","Sending...");
  var data={};new FormData(f).forEach(function(v,k){data[k]=v});data.email=data.email.trim().toLowerCase();data["cf-turnstile-response"]=tsToken;
  fetch(TRIAL_ENDPOINT_URL,{method:"POST",headers:{"Content-Type":"application/json","Accept":"application/json"},body:JSON.stringify(data)})
  .then(function(r){if(r.status===429)throw "rl";if(!r.ok)throw 0;
    var l=recent();l.push(Date.now());localStorage.setItem(RL,JSON.stringify(l));var em=data.email.replace(/[<>&"]/g,"");f.reset();cSel.disabled=true;
    msg("ok","Thanks. We've received your request and will reply by email to "+em+". Check your spam folder if you don't see it.")})
  .catch(function(x){msg("err",x==="rl"?"Too many requests from your connection right now. Please try again later, or email "+MAIL+".":"Sorry, that did not go through. Please email "+MAIL+".")})
  .then(function(){btn.disabled=false;tsToken="";if(window.turnstile)try{turnstile.reset()}catch(e){}});});
})();
