(()=>{'use strict';
const root=document.documentElement,reduce=matchMedia('(prefers-reduced-motion: reduce)');
const stops=[{accent:[107,225,151],secondary:[26,112,72],line:[28,64,43]},{accent:[226,133,171],secondary:[109,36,106],line:[66,27,57]},{accent:[245,153,105],secondary:[144,40,30],line:[77,33,23]}];
let elapsed=0,last=performance.now(),paused=reduce.matches,timer;
const mix=(a,b,f)=>a.map((v,i)=>Math.round(v+(b[i]-v)*f));
const api={current:stops[0],get paused(){return paused},setPaused(value){paused=value;last=performance.now();updateButton()},};
function updateButton(){const button=document.querySelector('#color-motion');if(button){button.textContent=paused?'Resume colors':'Pause colors';button.setAttribute('aria-pressed',String(paused))}}
function paint(){const cycle=(elapsed/84000)%1*3,i=Math.floor(cycle),raw=cycle-i,f=raw*raw*(3-2*raw),a=stops[i],b=stops[(i+1)%3];api.current={accent:mix(a.accent,b.accent,f),secondary:mix(a.secondary,b.secondary,f),line:mix(a.line,b.line,f)};for(const key of ['accent','secondary','line'])root.style.setProperty('--'+key+'-rgb',api.current[key].join(' '))}
function tick(){const now=performance.now();if(!paused&&!document.hidden)elapsed+=Math.min(now-last,250);last=now;paint();timer=setTimeout(tick,120)}
document.querySelector('#color-motion')?.addEventListener('click',()=>api.setPaused(!paused));
reduce.addEventListener('change',()=>api.setPaused(reduce.matches));document.addEventListener('visibilitychange',()=>{last=performance.now()});
window.blendstoryTheme=api;paint();updateButton();tick();
})();
