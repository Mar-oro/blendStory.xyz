(() => {
  'use strict';
  const canvas = document.getElementById('editorial-flow');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  const motion = matchMedia('(prefers-reduced-motion: reduce)');
  let width = 0, height = 0, scroll = scrollY, phase = 0, frame = 0, last = 0;
  let dirty = true;
  function resize() {
    width = innerWidth; height = innerHeight;
    const dpr = Math.min(devicePixelRatio || 1, 1.5);
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    dirty = true;
  }
  function draw() {
    ctx.clearRect(0, 0, width, height);
    const mobile = width < 700;
    const progress = Math.min(scroll / Math.max(1, document.documentElement.scrollHeight - height), 1);
    const cx = width * (mobile ? .79 : .76) - Math.sin(progress * Math.PI) * width * .15;
    const cy = height * (.49 + progress * .15);
    const scale = Math.min(width * (mobile ? 1.05 : .52), height * .79);
    const time = phase * .00016;
    const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, scale * 1.2);
    glow.addColorStop(0, 'rgba(11,61,41,.22)');
    glow.addColorStop(.6, 'rgba(20,44,30,.08)');
    glow.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = glow; ctx.fillRect(0, 0, width, height);
    const count = mobile ? 54 : 86;
    for (let wing = 0; wing < 3; wing++) {
      for (let line = 0; line < count; line++) {
        const v = line / (count - 1);
        ctx.beginPath();
        for (let step = 0; step <= 90; step++) {
          const u = step / 90;
          const envelope = Math.pow(Math.sin(u * Math.PI), .85);
          const angle = u * Math.PI * 1.65 + wing * 2.05 + v * .58 + time * .16 + progress * .6;
          const fold = Math.sin(u * 7.5 + time + wing + v * 2.5);
          const radius = scale * envelope * (.33 + v * .56);
          const x = cx + Math.cos(angle) * radius + fold * scale * .11 * envelope;
          const y = cy + Math.sin(angle) * radius * .86 + (u - .5) * scale * .38;
          if (!step) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        const gold = line % 11 === 0;
        ctx.strokeStyle = gold ? `rgba(196,163,94,${.15 + Math.sin(v * Math.PI) * .15})`
          : wing === 2 ? `rgba(91,29,62,${.13 + v * .14})` : `rgba(35,110,74,${.15 + v * .19})`;
        ctx.lineWidth = gold ? .8 : .6;
        ctx.stroke();
      }
    }
  }
  function tick(now) {
    frame = 0;
    if (document.hidden) return;
    const paused = motion.matches || window.blendstoryTheme?.paused;
    if (now - last > 32 || dirty) {
      if (!paused) phase += Math.min(now - (last || now), 50);
      if (!paused || dirty) draw();
      last = now; dirty = false;
    }
    if (!motion.matches) frame = requestAnimationFrame(tick);
  }
  function start() { if (!frame && !document.hidden) frame = requestAnimationFrame(tick); }
  addEventListener('resize', () => { resize(); start(); }, {passive:true});
  addEventListener('scroll', () => { scroll = scrollY; dirty = true; start(); }, {passive:true});
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) { cancelAnimationFrame(frame); frame = 0; last = 0; } else start();
  });
  motion.addEventListener('change', () => { dirty = true; start(); });
  resize(); start();
})();
