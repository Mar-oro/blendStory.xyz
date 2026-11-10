/* An authenticated response is not a payment entitlement. Paid API access remains server-enforced. */
(()=>{'use strict';const api=StudioSession.client();StudioSession.clearLegacy();
const gate=document.querySelector('#session-gate'),workspace=document.querySelector('#workspace'),status=document.querySelector('#gate-status'),retry=document.querySelector('#gate-retry');
let pending=false;window.StudioAccess={active:false,api,check,lock};
function lock(error){window.StudioAccess.active=false;workspace.hidden=true;gate.hidden=false;status.textContent=StudioSession.message(error);retry.hidden=false;window.dispatchEvent(new Event('studio:locked'));}
async function check(){if(pending)return;pending=true;retry.disabled=true;try{await api.call('/entitlements');window.StudioAccess.active=true;gate.hidden=true;workspace.hidden=false;window.dispatchEvent(new Event('studio:ready'));}catch(e){lock(e);if(e.status===401)location.replace('../login/');}finally{pending=false;retry.disabled=false;}}
retry.addEventListener('click',check);addEventListener('pageshow',e=>{if(e.persisted){lock(Error('Checking your session…'));check();}});
// Defer one task so the Studio listener is installed before the result.
setTimeout(check,0);
})();
