// Microsoft Clarity, only with the player's consent (LGPD). The project id comes from CLARITY_ID at build
// time; without it nothing is loaded and the privacy controls stay hidden. track() is safe to call always.
const CLARITY_ID=/* CLARITY_ID */'',CONSENT_KEY='pipaConsentV1';
function consentChoice(){try{return localStorage.getItem(CONSENT_KEY);}catch{return null;}}
function loadClarity(){
 if(!CLARITY_ID||window.clarity)return;
 window.clarity=function(){(window.clarity.q=window.clarity.q||[]).push(arguments);};
 const tag=document.createElement('script');tag.async=true;tag.src='https://www.clarity.ms/tag/'+encodeURIComponent(CLARITY_ID);document.head.append(tag);
 window.clarity('consent');
}
function track(name,tags){if(!window.clarity||consentChoice()!=='yes')return;try{window.clarity('event',name);if(tags)for(const [k,v] of Object.entries(tags))window.clarity('set',k,String(v));}catch{}}
function setConsent(yes){try{localStorage.setItem(CONSENT_KEY,yes?'yes':'no');}catch{}$('consentBar').hidden=true;if(yes)loadClarity();else if(window.clarity)location.reload();}
function openConsent(){$('consentBar').hidden=false;}
if(CLARITY_ID){
 $('privacyButton').hidden=false;$('privacyButton').onclick=openConsent;
 $('consentYes').onclick=()=>setConsent(true);$('consentNo').onclick=()=>setConsent(false);
 const choice=consentChoice();if(choice==='yes')loadClarity();else if(choice!=='no')openConsent();
}
