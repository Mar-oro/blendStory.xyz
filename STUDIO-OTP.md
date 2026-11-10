# Blendstory Studio — OTP and editorial theme

9 November 2026. Frontend implementation; existing GitHub Pages deployment under `docs/`.

## Changes

- Home service 04 is **Studio**, linked to the existing relative `login/` route.
- Login and dashboard share an OLED black / dark green / gold / muted purple editorial theme.
- Username/password → one-time code → server session check. Resend cooldown, error feedback, keyboard forms, paste/autofill, logout and session-expiry handling.
- Removes browser bearer-token login, refresh and unsigned JWT role decoding. Clears the three obsolete `blendstory_*` authentication storage keys. Never falls back to `/auth/authorize`, `/auth/token` or `/auth/refresh`.
- Existing story board becomes a writing desk, outline and movable story map. Create/edit/delete ideas and connections, save locally, export JSON. Existing `forge_nodes`, `forge_edges`, `forge_nid` are read when no new workspace exists and are not overwritten. New workspace key: `blendstory_studio_v1`.
- Model discovery is an explicit user action. Suggestions stream separately; users explicitly add them to their draft. Stop cancels generation. Authentication/payment/permission errors block access.
- Notes are rendered as text, not injected HTML. No seeded companions or fabricated admin badge. Draft storage is still browser-local and shared by users of that browser; not an account-scoped cloud library.

## Gateway contract and launch dependency

Frontend targets **https://sar1a.blendstory.xyz**, only from `blendstory.xyz` / `www.blendstory.xyz`. No cross-site fallback. On 9 November, a direct external DNS/HTTPS check could not resolve that hostname.

Expected existing ecosystem contract, based on the adjacent domain integrations:

- `POST /auth/login` `{username,password}` → `{otp_sent:true}`
- `POST /auth/otp/verify` `{username,otp}` → JSON and host-only `ecosystem_session`, HttpOnly / Secure / SameSite=Lax
- `POST /auth/otp/resend` `{username}`
- `POST /auth/logout` → JSON or 204; server must invalidate the session
- `GET /entitlements` → authenticated JSON; 401 logged out, 403 denied
- `/orch/v1/models`, `/orch/v1/chat/completions`, existing `/img/` routes must accept the same cookie and enforce permissions/usage limits server-side.

All requests use `credentials: include`, no-store and no redirected API requests. Exact-origin credentialed CORS and CSRF/origin protection must be configured by the gateway owner. DNS, TLS, CORS, cookie forwarding, OTP delivery and real account requests have **not** been changed or verified here.

**Session authentication is not a purchase.** No payment schema is invented: a successful `/entitlements` response opens the authenticated local editor, not a paid badge. Actual generation access must be enforced by the backend, with 402/403 handled by the UI. A product-specific paid entitlement contract, checkout, billing and account-isolated cloud storage remain out of scope and are not implemented. Do not announce a paid launch until those checks exist.

Relative links/assets work under subpaths (including the personal nginx preview). Secure sign-in deliberately remains disabled from `havoc` or file previews; those origins do not share the production cookie site.

## Verification

- `node tests/studio-session.cjs`: domain/path allowlists; credentialed cookies; removal of identity headers; cancellation after response headers; invalid responses, 204 logout and legacy cleanup.
- Offline Chrome browser fixtures: OTP success and invalid code; duplicate submit; HttpOnly cookie; forged legacy token rejected; 401 redirect; 403/503 closed; generation 402 blocked; logout failure/success; old drafts retained; edit/save/reload; connect ideas/map; model discovery and explicit acceptance of streamed suggestions; 320/390px responsive layouts.
- Browser review harness and screenshots: `/Users/shell0/Public/Sophie/blendstory-studio-20261109/`. Fixture success does not verify production API readiness.

No real credentials, payments, live generation or gateway configuration were used. Rollback is a revert of the Studio frontend commit; browser legacy keys remain intact.
