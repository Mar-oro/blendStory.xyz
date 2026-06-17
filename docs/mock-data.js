// mock-data.js — blendStory.xyz combined read (MOCK / DRY-RUN)
// ----------------------------------------------------------------------------
// Purpose: let the "Amber Forge" node-engine UI design flow keep moving while the
// BACKEND (Maniac/Eleven, this account = backend+security) builds the real read.
//
// L's contract for blendStory: pull EVERYTHING in one admin read —
//   • all DAEs info            -> MOCK_DAES
//   • Users WITH their DAEs    -> MOCK_USERS  (each user carries a .daes[] link list)
//   • recipes                  -> MOCK_RECIPES
//   • behavioral graphs (dummy)-> MOCK_BEHAVIORS  (Input→Intention→DAE→Task→Output)
//
// PROPOSED real endpoint (backend will confirm — treat as a target, not final):
//   GET /love/v1/blendstory   (admin-gated)  ->
//     { daes:[...], users:[...], recipes:[...], behaviors:[...] }
//   (i.e. one envelope = MOCK_BLENDSTORY below. If backend prefers splitting it
//    into /love/v1/daes + /love/v1/users + /love/v1/recipes, the arrays still
//    map 1:1 — swap is mechanical.)
//
// FIELD NAMES mirror the live DB contracts already in use:
//   DAE     ≈ loveDB BOT_CONFIGURATION × jetzabelDB.PERSONAS  (same shape as /love/v1/dae)
//   USER    ≈ ADMIN.PM_USERS  (same shape as jezabel.net user-sheets mock)
//   RECIPE  ≈ loveDB BOT_IMAGE_RECIPES
// Edit/save stays DRY-RUN ("(MOCK)") until the endpoint lands. Nodes are dummy
// scaffolding L said we'll populate for real later.
// ----------------------------------------------------------------------------

// ─── 1. ALL DAEs ────────────────────────────────────────────────────────────
var MOCK_DAES = [
  {
    id: 59, persona_id: 'eleven', name: 'Eleven',
    tagline: 'The one who keeps everything running.',
    system_prompt: 'You are Eleven — invisible infrastructure, Swiss-watch precision...',
    tier_required: 'free', owner: 'master',
    model: 'qwen3.6-35b-heretic',
    platforms: { telegram: '@eleven_bot', whatsapp: '5215555550059@s.whatsapp.net' },
    avatar_url: '/love/v1/dae/59/avatar',
    social: { instagram: null, x: null },
    created_at: '2026-05-29T00:00:00Z', updated_at: '2026-06-16T01:15:00Z'
  },
  {
    id: 52, persona_id: 'damon', name: 'Damon',
    tagline: 'The calm professor — forbidden knowledge, ancient texts × genetics.',
    system_prompt: 'You are Damon — AI philosopher correlating occult texts with...',
    tier_required: 'free', owner: 'master',
    model: 'qwen3.6-35b-heretic',
    platforms: { telegram: '@damon_bot', whatsapp: '5215555550052@s.whatsapp.net' },
    avatar_url: '/love/v1/dae/52/avatar',
    social: { instagram: null, x: null },
    created_at: '2026-05-29T00:00:00Z', updated_at: '2026-06-16T01:15:00Z'
  },
  {
    id: 75, persona_id: 'luna', name: 'Luna',
    tagline: 'AI DJ of city IO — smoky 3am-radio voice.',
    system_prompt: 'You are Luna — cyberpunk radio persona, warm and nocturnal...',
    tier_required: 'free', owner: 'master',
    model: 'qwen3.6-35b-claude4.7',
    platforms: { telegram: '@luna_bot', whatsapp: '5215555550222@s.whatsapp.net' },
    avatar_url: '/love/v1/dae/75/avatar',
    social: { instagram: null, x: null },
    created_at: '2026-05-29T00:00:00Z', updated_at: '2026-06-15T00:00:00Z'
  },
  {
    id: 241, persona_id: 'tess', name: 'Tess',
    tagline: 'Pet companion DAE — bright, attentive.',
    system_prompt: 'You are Tess — a warm pet-care companion...',
    tier_required: 'premium', owner: 'master',
    model: 'qwen3.6-35b-heretic',
    platforms: { telegram: '@tess_petbot', whatsapp: null },
    avatar_url: '/love/v1/dae/241/avatar',
    social: { instagram: null, x: null },
    created_at: '2026-06-17T05:03:00Z', updated_at: '2026-06-17T05:03:00Z'
  }
];

// ─── 2. USERS, each WITH their DAEs ──────────────────────────────────────────
// .daes[] = which DAEs this user interacts with (PM_CONVO_STATE / QUERY_ASSISTANT
// map). relationship is a UI hint (companion | owner | casual) — backend may omit.
var MOCK_USERS = [
  {
    platform: 'telegram', ext_id: '5955465323', user_key: 'L',
    username: 'master', display_name: 'L (admin)', tier: 'admin', type: 'person',
    first_seen: '2026-05-20T00:00:00Z', last_seen: '2026-06-17T10:50:00Z',
    msg_count: 5003, last_persona_id: 'eleven', notes: 'Master account.',
    flags: { internal: true },
    daes: [
      { dae_id: 59, persona_id: 'eleven', msg_count: 2100, last_seen: '2026-06-17T10:50:00Z', relationship: 'owner' },
      { dae_id: 52, persona_id: 'damon',  msg_count: 1400, last_seen: '2026-06-16T22:00:00Z', relationship: 'owner' },
      { dae_id: 75, persona_id: 'luna',   msg_count: 1503, last_seen: '2026-06-15T03:00:00Z', relationship: 'owner' }
    ]
  },
  {
    platform: 'telegram', ext_id: '8757763825', user_key: null,
    username: 'sci_reader', display_name: 'Sci Reader', tier: 'free', type: 'person',
    first_seen: '2026-06-01T12:00:00Z', last_seen: '2026-06-16T18:30:00Z',
    msg_count: 142, last_persona_id: 'damon', notes: 'Likes sci-fi + occult.',
    flags: {},
    daes: [
      { dae_id: 52, persona_id: 'damon',  msg_count: 120, last_seen: '2026-06-16T18:30:00Z', relationship: 'companion' },
      { dae_id: 59, persona_id: 'eleven', msg_count: 22,  last_seen: '2026-06-10T09:00:00Z', relationship: 'casual' }
    ]
  },
  {
    platform: 'whatsapp', ext_id: '987654321', user_key: null,
    username: 'jane', display_name: 'Jane', tier: 'free', type: 'person',
    first_seen: '2026-06-05T08:15:00Z', last_seen: '2026-06-16T22:10:00Z',
    msg_count: 8, last_persona_id: 'luna', notes: 'New, low volume (below seal threshold).',
    flags: {},
    daes: [
      { dae_id: 75, persona_id: 'luna', msg_count: 8, last_seen: '2026-06-16T22:10:00Z', relationship: 'casual' }
    ]
  }
];

// ─── 3. RECIPES (image-gen per DAE; variants selfie | degen | img) ───────────
var MOCK_RECIPES = [
  { dae_id: 59, persona_id: 'eleven', variant: 'selfie', model: 'Juggernaut',
    prompt: 'eleven, dark precise infrastructure aesthetic, soft rim light',
    negative: 'floating hands, extra fingers, lowres', width: 832, height: 1216, steps: 15, cfg: 6 },
  { dae_id: 52, persona_id: 'damon', variant: 'selfie', model: 'Juggernaut',
    prompt: 'damon, calm professor, warm library light, occult texts',
    negative: 'floating hands, extra fingers, lowres', width: 832, height: 1216, steps: 15, cfg: 6 },
  { dae_id: 75, persona_id: 'luna', variant: 'selfie', model: 'Juggernaut',
    prompt: 'luna, neon-noir radio booth, city IO skyline, cyan + red accents',
    negative: 'floating hands, extra fingers, lowres', width: 832, height: 1216, steps: 15, cfg: 6 },
  { dae_id: 75, persona_id: 'luna', variant: 'degen', model: 'cyberPony',
    prompt: '[admin-only NSFW variant]', negative: 'lowres, extra fingers',
    width: 832, height: 1216, steps: 20, cfg: 6 }
];

// ─── 4. BEHAVIORS — DUMMY node graphs for the Amber Forge engine ─────────────
// Wiring diagram L described: Input → Intention Gate → DAE → Task/Tool → Output.
// x/y are layout hints; populate/relayout freely. These are placeholders to
// design the node UI against — real behavior graphs come later.
var MOCK_BEHAVIORS = [
  {
    id: 'flow_eleven_default', dae_id: 59, persona_id: 'eleven',
    name: 'Eleven · default arc', status: 'draft',
    nodes: [
      { id: 'n1', type: 'input',     label: 'Input Text',     x: 40,  y: 160 },
      { id: 'n2', type: 'intention', label: 'Intention Gate', x: 240, y: 160, config: { intents: ['help', 'status', 'smalltalk'] } },
      { id: 'n3', type: 'dae',       label: 'Eleven',         x: 460, y: 160, dae_id: 59 },
      { id: 'n4', type: 'task',      label: 'Recall Memory',  x: 680, y: 90,  config: { tool: 'pm_recall' } },
      { id: 'n5', type: 'task',      label: 'Web Search',     x: 680, y: 230, config: { tool: 'web_search' } },
      { id: 'n6', type: 'output',    label: 'Output Text',    x: 900, y: 160 }
    ],
    edges: [
      { id: 'e1', from: 'n1', to: 'n2' },
      { id: 'e2', from: 'n2', to: 'n3' },
      { id: 'e3', from: 'n3', to: 'n4' },
      { id: 'e4', from: 'n3', to: 'n5' },
      { id: 'e5', from: 'n4', to: 'n6' },
      { id: 'e6', from: 'n5', to: 'n6' }
    ]
  },
  {
    id: 'flow_luna_radio', dae_id: 75, persona_id: 'luna',
    name: 'Luna · radio show', status: 'draft',
    nodes: [
      { id: 'm1', type: 'input',     label: 'Listener Msg',   x: 40,  y: 140 },
      { id: 'm2', type: 'intention', label: 'Intention Gate', x: 240, y: 140, config: { intents: ['request', 'vibe'] } },
      { id: 'm3', type: 'dae',       label: 'Luna',           x: 460, y: 140, dae_id: 75 },
      { id: 'm4', type: 'task',      label: 'Pick Track',     x: 680, y: 140, config: { tool: 'strudel' } },
      { id: 'm5', type: 'output',    label: 'On-air Reply',   x: 900, y: 140 }
    ],
    edges: [
      { id: 'f1', from: 'm1', to: 'm2' },
      { id: 'f2', from: 'm2', to: 'm3' },
      { id: 'f3', from: 'm3', to: 'm4' },
      { id: 'f4', from: 'm4', to: 'm5' }
    ]
  }
];

// ─── Combined envelope (matches the PROPOSED GET /love/v1/blendstory shape) ───
var MOCK_BLENDSTORY = {
  daes: MOCK_DAES,
  users: MOCK_USERS,
  recipes: MOCK_RECIPES,
  behaviors: MOCK_BEHAVIORS,
  _meta: { mock: true, generated: '2026-06-17', source: 'hλvoc brief — swap to GET /love/v1/blendstory when live' }
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { MOCK_DAES, MOCK_USERS, MOCK_RECIPES, MOCK_BEHAVIORS, MOCK_BLENDSTORY };
}
