/* OTP contract: host-only HttpOnly cookie. No bearer/authorize fallback. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;else root.StudioSession=api;})(globalThis,()=>{
'use strict';
const hosts=Object.freeze({'blendstory.xyz':'https://sar1a.blendstory.xyz','www.blendstory.xyz':'https://sar1a.blendstory.xyz'});
function resolve(host){if(!Object.hasOwn(hosts,host))throw Object.assign(Error('Secure sign-in is available at blendstory.xyz. This preview does not start a session.'),{code:'unsupported_host'});return hosts[host];}
function clearLegacy(storage=globalThis.sessionStorage){try{for(const key of ['blendstory_token','blendstory_refresh','blendstory_user'])storage?.removeItem(key);}catch{}}
function message(e){
 if(e.code==='invalid_credentials')return 'The username or password is incorrect.';
 if(e.code==='invalid_otp')return 'That code is not valid. Check it and try again.';
 if(e.code==='otp_expired')return 'Your code has expired. Request another code.';
 if(e.status===429||e.code==='otp_locked')return 'Too many attempts. Please wait before trying again.';
 if(e.status===401)return 'Your session has expired. Sign in again to continue.';
 if(e.status===402)return 'Your account needs active Studio access. Please contact Blendstory about your plan.';
 if(e.status===403)return 'Studio access is not enabled for this account. Please contact Blendstory.';
 return e.message||'Studio is temporarily unavailable. Please try again.';
}
function client(fetcher=globalThis.fetch,hostname=globalThis.location?.hostname){
 const base=()=>resolve(hostname);
 async function request(path,init={}){
  if(typeof path!=='string'||!path.startsWith('/')||path.startsWith('//')||/[\\\r\n]/.test(path))throw Error('Invalid API path.');
  const url=new URL(path,base());
  if(url.origin!==base()||url.hash||!/^\/(?:auth\/(?:login|otp\/verify|otp\/resend|logout)$|entitlements$|orch\/|img\/)/.test(url.pathname))throw Error('Unsupported API path.');
  const headers=new Headers(init.headers||{});for(const h of ['Authorization','X-Forwarded-User-Id','Cookie'])headers.delete(h);
  if(!headers.has('Accept'))headers.set('Accept','application/json');
  const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),20000);
  const signal=init.signal?AbortSignal.any([controller.signal,init.signal]):controller.signal;
  try{return await fetcher(url.href,{...init,headers,credentials:'include',cache:'no-store',redirect:'error',signal});}
  catch(e){if(init.signal?.aborted)throw new DOMException('Cancelled','AbortError');throw Object.assign(Error('Cannot reach secure sign-in. Please try again when the Studio gateway is available.'),{code:'unavailable'});}
  finally{clearTimeout(timer);}
 }
 async function call(path,body){
  const r=await request(path,{method:body===undefined?'GET':'POST',...(body===undefined?{}:{headers:{'Content-Type':'application/json'},body:JSON.stringify(body)})});
  if(r.status===204&&path==='/auth/logout')return {};
  let data;try{data=await r.json();}catch{throw Object.assign(Error('The gateway returned an unexpected response. Please try again.'),{status:r.status,code:'invalid_response'});}
  if(!r.ok){const detail=path.startsWith('/auth/')&&typeof data?.error==='object'?data.error:{};throw Object.assign(Error('The request could not be completed.'),{status:r.status,code:detail?.code});}
  if(!data||typeof data!=='object'||Array.isArray(data))throw Error('The gateway returned an invalid session response.');
  return data;
 }
 return {base,request,call};
}
return {resolve,clearLegacy,message,client};
});
