# Blendstory — OLED y posicionamiento AI & SI

## Dirección aprobada por K

- Marca B2B de servicios digitales y Agent as a Service, orientada a empresas lideradas por mujeres.
- AI & SI como lenguaje de marca; sin definiciones técnicas en la portada y sin afirmar que los modelos actuales sean superinteligencia demostrada.
- Branding digital, web, agentes para tareas definidas, campañas/eventos y seguimiento de tendencias tecnológicas.
- Fondo OLED #000000. Verde como inicio; ciclo lento hacia carmín/púrpura y rojo/naranja. Las fotos mantienen sus colores originales.
- Referencias locales de color leídas: jezabel.net/docs/index.html, storiesbyjez.com/html/index.html, jezabel.xyz/docs/index.html.

## Implementación

- `docs/assets/oled.css`: tema compartido por portada y equipo.
- `docs/assets/brand-theme.js`: ciclo de 84 segundos; no genera geometría de fondo. Usa variables CSS, respeta movimiento reducido y pausa de usuario.
- `docs/assets/bloom.js`: entidad de caracteres en canvas transparente, 820 glifos, límite aproximado de 30 fps y DPR 1.5.
- Portada con 4 líneas de servicio y Flower Party como primer ejemplo de experiencia publicada.
- Equipo mantiene la jerarquía CEO → DAEs → fundador → CDO.
- The Garden / Flower Party conserva su identidad independiente. No cambia login, studio, auth ni backend.

## Verificación

Chrome headless offline: negro calculado rgb(0,0,0); ciclo real probado con tiempo virtual hasta las fases carmín/púrpura y rojo/naranja; navegación y botones sin desborde en 390/320 px; movimiento reducido deja la paleta en pausa. Capturas revisadas. Portada con assets completos en 1440/390/320 px. Sin QA Safari en dispositivo real.

No se añaden afirmaciones ambientales verificables sin prácticas o mediciones que las respalden.
