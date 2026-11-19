(() => {
  'use strict';
  const video = document.getElementById('garden-motion');
  const button = document.querySelector('[data-motion-toggle]');
  if (!video || !button) return;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let inView = false;
  let manualPause = false;
  let explicitPlay = false;
  function update() {
    button.textContent = video.paused ? 'Reproducir imagen' : 'Pausar imagen';
  }
  async function play() {
    try { await video.play(); } catch { update(); }
  }
  function reconcile() {
    if (!inView || document.hidden) { video.pause(); return; }
    const autoAllowed = !reduced.matches && !navigator.connection?.saveData && !manualPause;
    if (explicitPlay || autoAllowed) play();
    else video.pause();
  }
  video.muted = true;
  video.controls = false;
  button.hidden = false;
  video.addEventListener('play', update);
  video.addEventListener('pause', update);
  video.addEventListener('error', () => { video.controls = true; button.hidden = true; });
  button.addEventListener('click', () => {
    if (!video.paused) {
      manualPause = true;
      explicitPlay = false;
      video.pause();
    } else {
      manualPause = false;
      explicitPlay = true;
      play();
    }
  });
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      const entry = entries[0];
      inView = entry.isIntersecting && entry.intersectionRatio >= 0.25;
      reconcile();
    }, { threshold: [0, 0.25] });
    observer.observe(video);
  }
  document.addEventListener('visibilitychange', reconcile);
  window.addEventListener('pagehide', () => video.pause());
  reduced.addEventListener('change', () => { explicitPlay = false; reconcile(); });
  navigator.connection?.addEventListener('change', reconcile);
  update();
})();
