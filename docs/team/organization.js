(()=>{'use strict';
 const sections=[...document.querySelectorAll('[data-area]')],buttons=[...document.querySelectorAll('[data-filter]')],status=document.querySelector('#team-filter-status');
 const labels={all:'Showing the whole team.',leadership:'Leadership: Cesiah, Rebecca and K.',design:'Design: Rosy Oro and Sussy.',technology:'Technology & frontend: Lilith and Sophie.'};
 function select(area){if(!Object.hasOwn(labels,area))return;sections.forEach(section=>{section.hidden=area!=='all'&&section.dataset.area!==area;});buttons.forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.filter===area)));status.textContent=labels[area];}
 function reveal(hash){let id;try{id=decodeURIComponent(hash.slice(1));}catch{return;}const target=document.getElementById(id),section=target?.closest('[data-area]');if(section?.hidden){select(section.dataset.area);requestAnimationFrame(()=>target.scrollIntoView({block:'start'}));}}
 buttons.forEach(b=>b.addEventListener('click',()=>select(b.dataset.filter)));
 document.querySelector('.team-filter').hidden=false;
 document.querySelector('.org-map').addEventListener('click',event=>{const link=event.target.closest('a[href^="#"]');if(link)reveal(link.hash);});
 addEventListener('hashchange',()=>reveal(location.hash));reveal(location.hash);
})();
