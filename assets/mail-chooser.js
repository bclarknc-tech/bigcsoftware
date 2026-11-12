/* Email links: many PCs have no default mail app, so a plain mailto: click does nothing.
   On click we copy the address, show a short toast, and offer Gmail / Outlook / mail app. The href stays mailto: for no-JS. */
(function(){
var css='.bmc-pop{position:absolute;z-index:9999;background:#fff;border:1px solid #c9d3e0;border-radius:8px;box-shadow:0 6px 24px rgba(10,30,60,.18);padding:6px;min-width:210px;font:15px/1.3 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}'+
'.bmc-pop a{display:block;padding:9px 12px;border-radius:6px;color:#0b2545;text-decoration:none;white-space:nowrap}.bmc-pop a:hover,.bmc-pop a:focus{background:#eef3f9;outline:none}'+
'.bmc-pop .bmc-h{padding:6px 12px 4px;color:#4a5a70;font-size:13px}'+
'.bmc-toast{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);z-index:10000;background:#0b2545;color:#fff;padding:10px 16px;border-radius:8px;font:15px/1.3 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;box-shadow:0 6px 20px rgba(0,0,0,.25);max-width:90vw}';
var st=document.createElement('style');st.textContent=css;document.head.appendChild(st);
var pop=null,toastT=null;
function close(){if(pop){pop.remove();pop=null}}
function toast(t){var e=document.querySelector('.bmc-toast');if(!e){e=document.createElement('div');e.className='bmc-toast';e.setAttribute('role','status');document.body.appendChild(e)}e.textContent=t;e.style.display='block';clearTimeout(toastT);toastT=setTimeout(function(){e.style.display='none'},2500)}
function copy(a){if(navigator.clipboard&&window.isSecureContext){return navigator.clipboard.writeText(a).then(function(){return true},function(){return legacy(a)})}return Promise.resolve(legacy(a))}
function legacy(a){try{var t=document.createElement('textarea');t.value=a;t.setAttribute('readonly','');t.style.position='fixed';t.style.opacity='0';document.body.appendChild(t);t.select();var ok=document.execCommand('copy');t.remove();return ok}catch(e){return false}}
function parse(href){var m=href.replace(/^mailto:/i,'');var q=m.indexOf('?'),to=decodeURIComponent(q<0?m:m.slice(0,q)),subj='';
  if(q>=0){var ps=new URLSearchParams(m.slice(q+1));subj=ps.get('subject')||''}return{to:to,subj:subj}}
function item(label,href,blank){var a=document.createElement('a');a.href=href;a.textContent=label;if(blank){a.target='_blank';a.rel='noopener'}a.addEventListener('click',function(){setTimeout(close,0)});return a}
document.addEventListener('click',function(ev){
  var l=ev.target.closest&&ev.target.closest('a[href^="mailto:"]');
  if(!l){if(pop&&!pop.contains(ev.target))close();return}
  if(pop&&pop.contains(l))return;
  if(ev.button!==0||ev.metaKey||ev.ctrlKey||ev.shiftKey||ev.altKey)return;
  ev.preventDefault();close();
  var p=parse(l.getAttribute('href')),to=p.to,s=p.subj,e=encodeURIComponent;
  copy(to).then(function(ok){toast(ok?to+' copied':'Email us at '+to)});
  pop=document.createElement('div');pop.className='bmc-pop';pop.setAttribute('role','menu');
  var h=document.createElement('div');h.className='bmc-h';h.textContent=to;pop.appendChild(h);
  pop.appendChild(item('Open in Gmail','https://mail.google.com/mail/?view=cm&fs=1&to='+e(to)+(s?'&su='+e(s):''),true));
  pop.appendChild(item('Open in Outlook','https://outlook.office.com/mail/deeplink/compose?to='+e(to)+(s?'&subject='+e(s):''),true));
  pop.appendChild(item('Use my email app',l.getAttribute('href'),false));
  document.body.appendChild(pop);
  var r=l.getBoundingClientRect(),w=pop.offsetWidth,x=Math.max(8,Math.min(r.left+window.scrollX,window.scrollX+document.documentElement.clientWidth-w-8)),y=r.bottom+window.scrollY+6;
  if(r.bottom+pop.offsetHeight+10>window.innerHeight&&r.top>pop.offsetHeight+10)y=r.top+window.scrollY-pop.offsetHeight-6;
  pop.style.left=x+'px';pop.style.top=y+'px';
  var first=pop.querySelector('a');if(first)first.focus({preventScroll:true});
},true);
document.addEventListener('keydown',function(e){if(e.key==='Escape')close()});
window.addEventListener('resize',close);
})();
