(()=>{'use strict';
const $=s=>document.querySelector(s),key='blendstory_studio_v1',api=StudioAccess.api,client=new BlendStoryClient();
let project={nodes:[],edges:[],nextId:100},active=null,dirty=false,initialized=false,storageFailed=false,run=null,suggestion='',runNode=null;
function status(text){$('#studio-status').textContent=text;}
function valid(data){return data&&Array.isArray(data.nodes)&&Array.isArray(data.edges)&&data.nodes.every(n=>n&&typeof n.id==='string'&&typeof n.label==='string'&&(n.content===undefined||typeof n.content==='string'))&&new Set(data.nodes.map(n=>n.id)).size===data.nodes.length;}
function persist(){try{localStorage.setItem(key,JSON.stringify(project));storageFailed=false;return true;}catch{storageFailed=true;status('This browser could not save your draft. Export a copy before leaving.');return false;}}
function load(){
 try{
  const raw=localStorage.getItem(key);let data;
  if(raw!==null)data=JSON.parse(raw);
  else if(localStorage.getItem('forge_nodes')!==null){data={nodes:JSON.parse(localStorage.getItem('forge_nodes')),edges:JSON.parse(localStorage.getItem('forge_edges')||'[]'),nextId:Number(localStorage.getItem('forge_nid'))||100};status('Your previous story board is here. The original browser data has been preserved.');}
  else data={nodes:[{id:'n1',type:'world',label:'A world of your own',content:'',x:70,y:90},{id:'n2',type:'character',label:'Someone worth following',content:'',x:400,y:190},{id:'n3',type:'scene',label:'The first possibility',content:'',x:740,y:90}],edges:[{from:'n1',to:'n2'},{from:'n2',to:'n3'}],nextId:100};
  if(!valid(data))throw Error('invalid');project=data;project.edges=project.edges.filter(e=>e&&typeof e.from==='string'&&typeof e.to==='string');project.nextId=Number.isSafeInteger(data.nextId)?data.nextId:100;
  project.nodes.forEach((n,i)=>{n.type=typeof n.type==='string'?n.type:'idea';n.content=n.content||'';n.x=Number.isFinite(n.x)?Math.max(0,n.x):70+i*280;n.y=Number.isFinite(n.y)?Math.max(0,n.y):90;});
 }catch{storageFailed=true;status('Your existing draft could not be read. It has not been overwritten. Export or recover the browser data before starting a new project.');return false;}
 return true;
}
function el(tag,text,cls){const n=document.createElement(tag);if(text!==undefined)n.textContent=text;if(cls)n.className=cls;return n;}
function changed(){dirty=true;$('#save-state').textContent='Unsaved changes';}
function confirmLeave(){return !dirty||confirm('Discard unsaved changes to this idea?');}
function select(id){if(!confirmLeave())return;stop();active=id;dirty=false;suggestion='';$('#suggestion').hidden=$('#use-suggestion').hidden=true;render();}
function render(){
 const list=$('#node-list');list.replaceChildren();$('#node-count').textContent=project.nodes.length;
 project.nodes.forEach(n=>{const b=el('button',undefined,'idea');b.type='button';b.setAttribute('aria-pressed',String(n.id===active));b.append(el('span',n.type),el('strong',n.label||'Untitled idea'),el('p',n.content||'Room for your imagination.'));b.addEventListener('click',()=>select(n.id));list.append(b);});
 const n=project.nodes.find(n=>n.id===active);$('#empty-state').hidden=!!n;$('#editor').hidden=!n;
 if(n){$('#node-kind').textContent=n.type;$('#node-title').value=n.label;$('#node-content').value=n.content;$('#save-state').textContent=storageFailed?'Not saved — export a copy':'Saved on this device';renderConnections(n);}
 renderMap();
}
function renderConnections(n){
 const target=$('#link-target');target.replaceChildren();project.nodes.filter(other=>other.id!==n.id).forEach(other=>{const o=el('option',other.label||'Untitled idea');o.value=other.id;target.append(o);});$('#link-add').disabled=!target.options.length;
 const links=$('#links');links.replaceChildren();project.edges.filter(e=>e.from===n.id||e.to===n.id).forEach(edge=>{const other=project.nodes.find(x=>x.id===(edge.from===n.id?edge.to:edge.from));if(!other)return;const line=el('div',undefined,'connection'),remove=el('button','Remove connection');line.append(el('span',(edge.from===n.id?'→ ':'← ')+other.label),remove);remove.addEventListener('click',()=>{project.edges=project.edges.filter(e=>e!==edge);persist();renderConnections(n);renderMap();});links.append(line);});
}
function save(){const n=project.nodes.find(n=>n.id===active);if(!n)return;n.label=$('#node-title').value.trim()||'Untitled idea';n.content=$('#node-content').value;if(persist()){dirty=false;status('Saved on this device.');}render();}
function add(type){if(!StudioAccess.active||!confirmLeave())return;stop();let id;do{id='n'+project.nextId++;}while(project.nodes.some(n=>n.id===id));project.nodes.push({id,type,label:'Untitled '+type,content:'',x:70+(project.nodes.length%4)*280,y:90+Math.floor(project.nodes.length/4)*190});active=id;dirty=false;persist();render();$('#node-title').focus();}
function stop(){if(run)run.abort();run=null;$('#stop').hidden=true;$('#generate').disabled=!$('#model').value;}
function renderMap(){
 const surface=$('#map-surface'),cards=$('#map-nodes');cards.replaceChildren();surface.style.width=Math.max(1400,...project.nodes.map(n=>n.x+260))+'px';surface.style.height=Math.max(800,...project.nodes.map(n=>n.y+180))+'px';
 project.nodes.forEach(n=>{const card=el('button',undefined,'map-card');card.style.left=n.x+'px';card.style.top=n.y+'px';card.append(el('span',n.type),el('strong',n.label||'Untitled idea'));card.setAttribute('aria-label','Edit '+n.label);let drag=null,moved=false;
 card.addEventListener('pointerdown',e=>{if(e.button!==0)return;drag={x:e.clientX,y:e.clientY,nx:n.x,ny:n.y};moved=false;card.setPointerCapture(e.pointerId);});
 card.addEventListener('pointermove',e=>{if(!drag)return;const dx=e.clientX-drag.x,dy=e.clientY-drag.y;if(Math.abs(dx)+Math.abs(dy)>4)moved=true;n.x=Math.max(0,drag.nx+dx);n.y=Math.max(0,drag.ny+dy);card.style.left=n.x+'px';card.style.top=n.y+'px';drawLinks();});
 card.addEventListener('pointerup',()=>{if(drag&&moved){persist();surface.style.width=Math.max(1400,...project.nodes.map(n=>n.x+260))+'px';surface.style.height=Math.max(800,...project.nodes.map(n=>n.y+180))+'px';}drag=null;});card.addEventListener('pointercancel',()=>{drag=null;persist();});
 card.addEventListener('click',()=>{if(!moved){select(n.id);$('#editor').scrollIntoView({block:'start'});}moved=false;});cards.append(card);});drawLinks();
}
function drawLinks(){const svg=$('#map-lines');svg.replaceChildren();for(const edge of project.edges){const a=project.nodes.find(n=>n.id===edge.from),b=project.nodes.find(n=>n.id===edge.to);if(!a||!b)continue;const path=document.createElementNS('http://www.w3.org/2000/svg','path'),x=a.x+210,y=a.y+48,x2=b.x,y2=b.y+48;path.setAttribute('d',`M ${x} ${y} C ${x+70} ${y}, ${x2-70} ${y2}, ${x2} ${y2}`);path.setAttribute('stroke','#a58d57');path.setAttribute('stroke-width','1.5');path.setAttribute('fill','none');svg.append(path);}}
function start(){if(initialized)return;initialized=true;if(!load()){for(const b of document.querySelectorAll('#workspace button:not(#logout)'))b.disabled=true;return;}active=project.nodes[0]?.id||null;render();}
addEventListener('studio:ready',start);if(StudioAccess.active)start();addEventListener('studio:locked',stop);
$('#node-title').addEventListener('input',changed);$('#node-content').addEventListener('input',changed);$('#save').addEventListener('click',save);
for(const type of ['character','scene','world'])$('#add-'+type).addEventListener('click',()=>add(type));
$('#delete').addEventListener('click',()=>{if(!confirm('Delete this idea and its connections?'))return;stop();project.nodes=project.nodes.filter(n=>n.id!==active);project.edges=project.edges.filter(e=>e.from!==active&&e.to!==active);active=project.nodes[0]?.id||null;dirty=false;persist();render();});
$('#link-add').addEventListener('click',()=>{const to=$('#link-target').value;if(!to||project.edges.some(e=>e.from===active&&e.to===to))return;project.edges.push({from:active,to});persist();renderConnections(project.nodes.find(n=>n.id===active));renderMap();});
$('#board-toggle').addEventListener('click',()=>{const map=$('#story-map');map.hidden=!map.hidden;$('#board-toggle').setAttribute('aria-pressed',String(!map.hidden));if(!map.hidden)map.scrollIntoView({block:'start'});});
$('#export').addEventListener('click',()=>{const data=JSON.parse(JSON.stringify(project));if(dirty){const n=data.nodes.find(n=>n.id===active);if(n){n.label=$('#node-title').value;n.content=$('#node-content').value;}}const url=URL.createObjectURL(new Blob([JSON.stringify({version:1,...data},null,2)],{type:'application/json'})),a=document.createElement('a');a.href=url;a.download='blendstory-project.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);status('Project exported, including your current edits.');});
$('#load-models').addEventListener('click',async()=>{const b=$('#load-models');b.disabled=true;status('Checking available writing models…');try{const models=await client.chatModels({timeoutMs:15000});const select=$('#model');select.replaceChildren();const empty=el('option','Choose a writing model');empty.value='';select.append(empty);models.forEach(name=>{if(typeof name==='string'){const o=el('option',name);o.value=name;select.append(o);}});select.disabled=select.options.length<2;$('#generate').disabled=true;status(select.disabled?'No writing models are available right now. Your draft is still here.':'Choose a model to explore this idea.');}catch(e){status(StudioSession.message(e));}finally{b.disabled=false;}});
$('#model').addEventListener('change',()=>{$('#generate').disabled=!$('#model').value;});
$('#generate').addEventListener('click',async()=>{if(run||!active||!$('#model').value||!StudioAccess.active)return;const controller=new AbortController();run=controller;runNode=active;suggestion='';$('#suggestion').textContent='';$('#suggestion').hidden=false;$('#use-suggestion').hidden=true;$('#generate').disabled=true;$('#stop').hidden=false;status('Exploring your idea…');
 try{await client.chat({model:$('#model').value,signal:controller.signal,messages:[{role:'system',content:'You are a fanfiction co-writer. Follow the author’s supplied notes, tone and language. Offer a vivid passage or development of their idea. Do not claim to save or publish anything.'},{role:'user',content:$('#node-title').value+'\n\n'+$('#node-content').value}],onDelta:delta=>{if(run!==controller||active!==runNode)return;suggestion+=delta;$('#suggestion').textContent=suggestion;}});if(run===controller)status(suggestion?'Your suggestion is ready. Add it to your draft or keep writing.':'No text was returned. Please try again.');}
 catch(e){if(run===controller)status(e.name==='AbortError'?'Generation stopped.':StudioSession.message(e));}
 finally{if(run===controller){run=null;$('#stop').hidden=true;$('#generate').disabled=!$('#model').value;$('#use-suggestion').hidden=!suggestion;}}
});
$('#stop').addEventListener('click',()=>{stop();status('Generation stopped.');$('#use-suggestion').hidden=!suggestion;});
$('#use-suggestion').addEventListener('click',()=>{if(!suggestion||active!==runNode)return;$('#node-content').value+=($('#node-content').value?'\n\n':'')+suggestion;changed();$('#use-suggestion').hidden=true;});
$('#logout').addEventListener('click',async()=>{if(!confirmLeave())return;const b=$('#logout');b.disabled=true;stop();try{await api.call('/auth/logout',{});StudioSession.clearLegacy();location.replace('../login/');}catch(e){status('Sign-out was not confirmed. '+StudioSession.message(e));}finally{b.disabled=false;}});
addEventListener('beforeunload',e=>{if(dirty||storageFailed){e.preventDefault();e.returnValue='';}});addEventListener('pagehide',stop);
})();
