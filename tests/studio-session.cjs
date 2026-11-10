const assert=require('node:assert/strict');
const S=require('../docs/assets/studio-session.js');
(async()=>{
assert.equal(S.resolve('blendstory.xyz'),'https://sar1a.blendstory.xyz');
for(const host of ['havoc','localhost','evil.example','blendstory.xyz.evil.test'])assert.throws(()=>S.resolve(host));
const removed=[];S.clearLegacy({removeItem:k=>removed.push(k)});assert.deepEqual(removed,['blendstory_token','blendstory_refresh','blendstory_user']);
const requests=[];const api=S.client(async(url,init)=>{requests.push({url,init});return new Response(JSON.stringify({otp_sent:true}),{status:200});},'blendstory.xyz');
await api.call('/auth/login',{username:'test',password:'fixture'});
assert.equal(requests[0].init.credentials,'include');assert.equal(requests[0].init.redirect,'error');assert.equal(requests[0].init.cache,'no-store');
for(const path of ['/auth/token','/auth/authorize','/auth/signup','//evil.test/auth/login','/x/../auth/token','https://evil.test/','/orch/../../auth/authorize'])await assert.rejects(()=>api.request(path));
await api.request('/orch/v1/models',{headers:{Authorization:'unsafe','X-Forwarded-User-Id':'1',Cookie:'unsafe'}});
for(const name of ['Authorization','Cookie','X-Forwarded-User-Id'])assert(!requests.at(-1).init.headers.has(name));
const controller=new AbortController();await api.request('/orch/v1/chat/completions',{signal:controller.signal});controller.abort();assert(requests.at(-1).init.signal.aborted,'abort remains connected after response headers');
const empty=S.client(async()=>new Response(null,{status:204}),'blendstory.xyz');assert.deepEqual(await empty.call('/auth/logout',{}),{});
const forbidden=S.client(async()=>new Response(JSON.stringify({error:{code:'invalid_otp'}}),{status:403}),'blendstory.xyz');await assert.rejects(()=>forbidden.call('/auth/otp/verify',{}),e=>e.code==='invalid_otp'&&e.status===403);
const malformed=S.client(async()=>new Response('<html>oops</html>'),'blendstory.xyz');await assert.rejects(()=>malformed.call('/entitlements'),e=>e.code==='invalid_response');
console.log('PASS: OTP transport origin/path restrictions, cookie credentials, stripped identity headers, cancellation, errors, legacy cleanup.');
})().catch(e=>{console.error(e);process.exitCode=1});
