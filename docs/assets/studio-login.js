(()=>{'use strict';
const api=StudioSession.client(),$=s=>document.querySelector(s),form=$('#login-form'),user=$('#username'),password=$('#password'),otp=$('#otp'),submit=$('#submit'),resend=$('#resend'),back=$('#change-account'),status=$('#status');
let stage='password',busy=false,cooldown=0,sessionUser='',focusNext=null;
StudioSession.clearLegacy();
function text(value){status.textContent=value;}
function lock(value){busy=value;submit.disabled=value;user.disabled=password.disabled=otp.disabled=value;back.disabled=value;resend.disabled=value||Date.now()<cooldown;form.setAttribute('aria-busy',String(value));}
function show(value){stage=value;const code=value==='otp';$('#credentials-fields').hidden=code;$('#otp-fields').hidden=!code;resend.hidden=back.hidden=!code;user.required=password.required=!code;otp.required=code;submit.textContent=code?'Verify & enter Studio':'Send my code';$('#step').textContent=code?'02 / VERIFY YOUR ACCESS':'01 / YOUR ACCOUNT';focusNext=code?otp:user;}
form.addEventListener('submit',async event=>{event.preventDefault();if(busy)return;
 if(stage==='otp'&&!/^\d{6}$/.test(otp.value)){text('Enter the six-digit code.');otp.focus();return;}
 lock(true);text('Connecting securely…');
 try{
  if(stage==='password'){
   sessionUser=user.value.trim();if(!sessionUser||!password.value)throw Error('Enter your username and password.');
   const result=await api.call('/auth/login',{username:sessionUser,password:password.value});
   if(result.otp_sent!==true)throw Error('A code was not confirmed. Please try again.');
   password.value='';show('otp');cooldown=Date.now()+30000;text('Code sent. Check the delivery channel registered to your account.');
  }else{
   await api.call('/auth/otp/verify',{username:sessionUser,otp:otp.value});otp.value='';
   await api.call('/entitlements');text('Verified. Opening your Studio…');location.replace('../dashboard/');
  }
 }catch(e){text(StudioSession.message(e));}
 finally{password.value='';lock(false);if(focusNext){focusNext.focus();focusNext=null;}}
});
resend.addEventListener('click',async()=>{if(busy||Date.now()<cooldown)return;lock(true);try{await api.call('/auth/otp/resend',{username:sessionUser});cooldown=Date.now()+30000;text('A new code has been requested.');}catch(e){text(StudioSession.message(e));}finally{lock(false);}});
back.addEventListener('click',()=>{if(busy)return;otp.value=password.value='';sessionUser='';show('password');text('');user.focus();});
otp.addEventListener('input',()=>{otp.value=otp.value.replace(/\D/g,'').slice(0,6);});
const timer=setInterval(()=>{const seconds=Math.max(0,Math.ceil((cooldown-Date.now())/1000));resend.textContent=seconds?'Resend in '+seconds+'s':'Resend code';if(!busy)resend.disabled=seconds>0;},1000);
addEventListener('pagehide',()=>{clearInterval(timer);password.value=otp.value='';});
show('password');
})();
