// blendstory-client.js — text + image generation client for blendStory.xyz.
//
// Headless transport. No DOM, no CSS. Drop into any blendStory page that
// already has the auth-guard, instantiate, call methods. Storage keys
// (sessionStorage + IndexedDB) are pinned to the `blendstory_` namespace.
//
//   const client = new BlendStoryClient();    // defaults to sar1a.lempyra.com
//
//   // streaming chat for story writing
//   await client.chat({
//     model: 'llama-3.1-8b',
//     messages: [{ role: 'system', content: '...' }, { role: 'user', content: '...' }],
//     onDelta: (chunk) => append(chunk),
//   });
//
//   // submit + poll + fetch an image in one call
//   const { jobId, job, blobs } = await client.generateAndFetch({
//     model:  'sdxl-base',
//     prompt: 'amber street, rain-slicked asphalt, neon noir',
//     steps:  30, seed: -1,
//   });
//
//   // persist to IndexedDB (prefix-scoped: blendstory_imgStore)
//   await client.stores().imgStore.put({
//     id: jobId, ts: Date.now(), prompt: '...', blob: blobs[0].blob,
//   });
//
// AUTH:
//   Reads sessionStorage.blendstory_token for every sar1a request. On 401,
//   attempts a single refresh via /auth/refresh using blendstory_refresh,
//   retries the call once. Never navigates — the page's auth-guard owns
//   redirect logic.
//
// NO AUTO-POLL:
//   Hosts/models are queried only when the caller invokes models() or
//   chat()/imageModels() explicitly. The only poll loop is poll(jobId) for
//   a single active image job (job-state, not model-list). See
//   feedback_no_auto_probe.md for the rationale.
(function (global) {
  'use strict';

  const PREFIX     = 'blendstory';
  const TOKEN_KEY  = `${PREFIX}_token`;
  const REFRESH_KEY = `${PREFIX}_refresh`;
  const USER_KEY   = `${PREFIX}_user`;

  // ─── IndexedDB store factory ──────────────────────────────────────────────
  function createStore({ dbName, storeName = 'records', capBytes, maxRecords }) {
    const listeners = { change: new Set() };
    let _dbPromise = null;
    const SCHEMA_VERSION = 3;

    function openDB() {
      if (_dbPromise) return _dbPromise;
      _dbPromise = new Promise((resolve, reject) => {
        const req = indexedDB.open(dbName, SCHEMA_VERSION);
        req.onupgradeneeded = (e) => {
          const db = e.target.result;
          for (const name of Array.from(db.objectStoreNames)) db.deleteObjectStore(name);
          const os = db.createObjectStore(storeName, { keyPath: 'id' });
          os.createIndex('ts', 'ts', { unique: false });
        };
        req.onsuccess = () => {
          const db = req.result;
          if (!db.objectStoreNames.contains(storeName)) {
            db.close();
            const del = indexedDB.deleteDatabase(dbName);
            del.onsuccess = () => { _dbPromise = null; openDB().then(resolve, reject); };
            del.onerror   = () => reject(del.error);
            return;
          }
          db.onversionchange = () => { db.close(); _dbPromise = null; };
          resolve(db);
        };
        req.onerror = () => reject(req.error);
      });
      return _dbPromise;
    }
    function tx(mode) {
      return openDB().then(db => db.transaction(storeName, mode).objectStore(storeName));
    }
    function promisify(req) {
      return new Promise((resolve, reject) => {
        req.onsuccess = () => resolve(req.result);
        req.onerror   = () => reject(req.error);
      });
    }
    function emit(event) {
      for (const fn of listeners[event] || []) { try { fn(); } catch (_) {} }
    }
    async function indexAll() {
      const store = await tx('readonly');
      const out = [];
      return new Promise((resolve, reject) => {
        const req = store.openCursor();
        req.onsuccess = (e) => {
          const c = e.target.result;
          if (!c) return resolve(out);
          const r = c.value;
          out.push({ id: r.id, ts: r.ts || 0, bytes: r._bytes || 0 });
          c.continue();
        };
        req.onerror = () => reject(req.error);
      });
    }
    function recordBytes(record) {
      if (record._bytes) return record._bytes;
      let n = 0;
      if (Array.isArray(record.images)) for (const im of record.images) n += im.blob?.size || 0;
      if (record.blob) n += record.blob.size;
      const meta = { ...record };
      delete meta.blob; delete meta.images; delete meta._bytes;
      n += JSON.stringify(meta).length * 2;
      return n;
    }
    async function evictIfNeeded(incoming = 0) {
      const all = (await indexAll()).sort((a, b) => a.ts - b.ts);
      let totalBytes = all.reduce((s, r) => s + r.bytes, 0) + incoming;
      let count = all.length + 1;
      while (all.length && (count > maxRecords || totalBytes > capBytes)) {
        const v = all.shift();
        try { await deleteOne(v.id, true); } catch (_) {}
        totalBytes -= v.bytes; count--;
      }
    }
    async function put(record) {
      if (!record || !record.id) throw new Error('put: record.id required');
      if (typeof record.ts !== 'number') record.ts = Date.now();
      record._bytes = recordBytes(record);
      await evictIfNeeded(record._bytes);
      try {
        const store = await tx('readwrite');
        await promisify(store.put(record));
      } catch (err) {
        if (err && err.name === 'QuotaExceededError') {
          const all = (await indexAll()).sort((a, b) => a.ts - b.ts);
          const drop = Math.max(1, Math.floor(all.length / 4));
          for (let i = 0; i < drop; i++) await deleteOne(all[i].id, true);
          const store = await tx('readwrite');
          await promisify(store.put(record));
        } else throw err;
      }
      emit('change');
      return record.id;
    }
    async function get(id) {
      const store = await tx('readonly');
      const rec = await promisify(store.get(id));
      if (!rec) return null;
      if (Array.isArray(rec.images)) {
        rec.images = rec.images.map(im => ({
          ...im,
          objectUrl: im.blob ? URL.createObjectURL(im.blob) : null,
        }));
      } else if (rec.blob) {
        rec.objectUrl = URL.createObjectURL(rec.blob);
      }
      return rec;
    }
    async function list({ limit = 200 } = {}) {
      const store = await tx('readonly');
      const out = [];
      return new Promise((resolve, reject) => {
        const idx = store.index('ts');
        const req = idx.openCursor(null, 'prev');
        req.onsuccess = (e) => {
          const c = e.target.result;
          if (!c || out.length >= limit) return resolve(out);
          const r = c.value;
          const { blob: _b, images: _i, ...meta } = r;
          out.push({ ...meta, image_count: (r.images || []).length });
          c.continue();
        };
        req.onerror = () => reject(req.error);
      });
    }
    async function deleteOne(id, silent = false) {
      const store = await tx('readwrite');
      await promisify(store.delete(id));
      if (!silent) emit('change');
    }
    async function clear() {
      const store = await tx('readwrite');
      await promisify(store.clear());
      emit('change');
    }
    async function usage() {
      const all = await indexAll();
      const bytes = all.reduce((s, r) => s + r.bytes, 0);
      return {
        bytes,
        count: all.length,
        cap_bytes:   capBytes,
        cap_records: maxRecords,
        cap_percent: Math.min(1, Math.max(bytes / capBytes, all.length / maxRecords)),
      };
    }
    function on(event, fn) {
      if (!listeners[event]) listeners[event] = new Set();
      listeners[event].add(fn);
      return () => listeners[event].delete(fn);
    }
    return { put, get, list, delete: deleteOne, clear, usage, on };
  }

  // ─── BlendStoryClient ─────────────────────────────────────────────────────
  class BlendStoryClient {
    constructor({
      sar1a    = 'https://sar1a.lempyra.com',
      clientId = 'portal',
    } = {}) {
      this.sar1a       = sar1a.replace(/\/$/, '');
      this.clientId    = clientId;
      this._stores     = null;
      this._refreshing = null;
    }

    // ── Auth helpers ──────────────────────────────────────────────────────
    token() { return sessionStorage.getItem(TOKEN_KEY); }
    user()  { return sessionStorage.getItem(USER_KEY); }
    _authHeader() {
      const t = this.token();
      return t ? { 'Authorization': `Bearer ${t}` } : {};
    }
    async refresh() {
      if (this._refreshing) return this._refreshing;
      this._refreshing = (async () => {
        const rt = sessionStorage.getItem(REFRESH_KEY);
        if (!rt) return false;
        try {
          const r = await fetch(this.sar1a + '/auth/refresh', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              grant_type:    'refresh_token',
              refresh_token: rt,
              client_id:     this.clientId,
            }),
          });
          if (!r.ok) return false;
          const data = await r.json();
          if (!data.access_token) return false;
          sessionStorage.setItem(TOKEN_KEY, data.access_token);
          if (data.refresh_token) sessionStorage.setItem(REFRESH_KEY, data.refresh_token);
          return true;
        } catch (_) {
          return false;
        } finally {
          setTimeout(() => { this._refreshing = null; }, 0);
        }
      })();
      return this._refreshing;
    }

    async _fetch(url, init = {}) {
      const merge = () => ({
        ...init,
        headers: { ...(init.headers || {}), ...this._authHeader() },
      });
      let r = await fetch(url, merge());
      if (r.status === 401) {
        const ok = await this.refresh();
        if (ok) r = await fetch(url, merge());
      }
      return r;
    }

    // ── Model probes ──────────────────────────────────────────────────────
    async chatModels({ signal, timeoutMs = 2500 } = {}) {
      const r = await this._fetch(this.sar1a + '/orch/v1/models',
        { signal: signal || AbortSignal.timeout(timeoutMs) });
      if (!r.ok) throw new Error(`chatModels: HTTP ${r.status}`);
      const data = await r.json();
      return (data.data || []).map(m => m.id);
    }
    async imageModels({ signal, timeoutMs = 2500 } = {}) {
      const r = await this._fetch(this.sar1a + '/img/v1/models',
        { signal: signal || AbortSignal.timeout(timeoutMs) });
      if (!r.ok) throw new Error(`imageModels: HTTP ${r.status}`);
      const data = await r.json();
      return data.all || data.checkpoints || [];
    }
    async models(opts = {}) {
      const [c, i] = await Promise.allSettled([
        this.chatModels(opts), this.imageModels(opts),
      ]);
      return {
        chat:  c.status === 'fulfilled' ? c.value : [],
        image: i.status === 'fulfilled' ? i.value : [],
        errors: {
          chat:  c.status === 'rejected' ? String(c.reason) : null,
          image: i.status === 'rejected' ? String(i.reason) : null,
        },
      };
    }

    // ── Chat (streaming SSE) ──────────────────────────────────────────────
    async chat({ model, messages, onDelta, temperature = 0.7, signal, extra = {} }) {
      if (!model)    throw new Error('chat: model required');
      if (!messages) throw new Error('chat: messages required');
      const r = await this._fetch(this.sar1a + '/orch/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, messages, stream: true, temperature, ...extra }),
        signal,
      });
      if (!r.ok) throw new Error(`chat: HTTP ${r.status}: ${(await r.text()).slice(0, 200)}`);
      const reader = r.body.getReader();
      const dec = new TextDecoder();
      let buffer = '', acc = '';
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += dec.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop();
        for (const line of lines) {
          const t = line.trim();
          if (!t.startsWith('data:')) continue;
          const payload = t.slice(5).trim();
          if (payload === '[DONE]') continue;
          try {
            const chunk = JSON.parse(payload);
            const delta = chunk.choices?.[0]?.delta?.content;
            if (delta) {
              acc += delta;
              if (onDelta) try { onDelta(delta, acc); } catch (_) {}
            }
          } catch (_) {}
        }
      }
      return acc;
    }

    // ── Image gen (submit → poll → fetch) ─────────────────────────────────
    async generate({ model, prompt, negative, steps, seed, width, height, recipe, extra = {} }) {
      if (!model) throw new Error('generate: model required');
      const body = {
        model,
        prompt:   prompt || undefined,
        negative: negative || undefined,
        steps:    typeof steps === 'number' ? steps : undefined,
        seed:     (typeof seed === 'number' && seed >= 0) ? seed : null,
        width:    typeof width  === 'number' ? width  : undefined,
        height:   typeof height === 'number' ? height : undefined,
        recipe:   recipe || undefined,
        ...extra,
      };
      const r = await this._fetch(this.sar1a + '/img/v1/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      if (!r.ok) throw new Error(`generate: HTTP ${r.status}: ${(await r.text()).slice(0, 200)}`);
      const j = await r.json();
      if (!j.job_id) throw new Error('generate: no job_id in response');
      return j.job_id;
    }

    async jobStatus(jobId) {
      const r = await this._fetch(this.sar1a + `/img/v1/jobs/${encodeURIComponent(jobId)}`);
      if (!r.ok) {
        const err = new Error(`jobStatus: HTTP ${r.status}`);
        err.status = r.status;
        throw err;
      }
      return r.json();
    }

    async poll(jobId, { onUpdate, intervalMs = 5000, signal } = {}) {
      let backoff = intervalMs;
      while (true) {
        if (signal?.aborted) throw new Error('poll: aborted');
        try {
          const job = await this.jobStatus(jobId);
          if (onUpdate) try { onUpdate(job); } catch (_) {}
          if (job.status === 'done' || job.status === 'failed') return job;
          backoff = intervalMs;
        } catch (e) {
          if (e.status === 404) {
            backoff = Math.min(backoff * 1.5, 60000);
            if (backoff >= 60000) return null;
          }
        }
        await new Promise(r => setTimeout(r, backoff));
      }
    }

    // Retries on 5xx (sar1a upstream timeouts) with exponential backoff. 4xx
    // is not retried (404 = file gone, 401 already handled via _fetch).
    async image(filename, { retries = 3, retryDelayMs = 2000 } = {}) {
      const url = this.sar1a + `/img/outputs/${encodeURIComponent(filename)}`;
      let lastErr;
      for (let attempt = 0; attempt <= retries; attempt++) {
        if (attempt > 0) {
          await new Promise(r => setTimeout(r, retryDelayMs * Math.pow(1.5, attempt - 1)));
        }
        try {
          const r = await this._fetch(url);
          if (r.ok) return r.blob();
          lastErr = new Error(`image: HTTP ${r.status}`);
          lastErr.status = r.status;
          if (r.status >= 400 && r.status < 500) throw lastErr;
        } catch (e) {
          lastErr = e;
          if (e.status >= 400 && e.status < 500) throw e;
        }
      }
      throw lastErr;
    }

    // ── Stores (lazy, blendstory_ prefix) ─────────────────────────────────
    stores() {
      if (this._stores) return this._stores;
      const CAP_200_MB = 200 * 1024 * 1024;
      this._stores = {
        imgStore:      createStore({ dbName: `${PREFIX}_imgStore`,      capBytes: CAP_200_MB, maxRecords: 100 }),
        chatUserStore: createStore({ dbName: `${PREFIX}_chatUserStore`, capBytes: CAP_200_MB, maxRecords: 50000 }),
        chatLLMStore:  createStore({ dbName: `${PREFIX}_chatLLMStore`,  capBytes: CAP_200_MB, maxRecords: 50000 }),
        recipeStore:   createStore({ dbName: `${PREFIX}_recipeStore`,   capBytes: CAP_200_MB, maxRecords: 1000 }),
        settingsStore: createStore({ dbName: `${PREFIX}_settingsStore`, capBytes: CAP_200_MB, maxRecords: 1000 }),
        nuke: async () => {
          const dbs = [`${PREFIX}_imgStore`, `${PREFIX}_chatUserStore`, `${PREFIX}_chatLLMStore`, `${PREFIX}_recipeStore`, `${PREFIX}_settingsStore`];
          for (const name of dbs) {
            await new Promise((res) => {
              const r = indexedDB.deleteDatabase(name);
              r.onsuccess = res; r.onerror = res; r.onblocked = res;
            });
          }
        },
      };
      return this._stores;
    }

    // ── High-level: submit → poll → fetch all blobs ──────────────────────
    async generateAndFetch(opts, { onUpdate } = {}) {
      const jobId = await this.generate(opts);
      const job   = await this.poll(jobId, { onUpdate });
      if (!job || job.status !== 'done' || !Array.isArray(job.images)) {
        return { jobId, job, blobs: [] };
      }
      const blobs = [];
      for (const f of job.images) {
        try {
          const blob = await this.image(f);
          blobs.push({ filename: f, blob });
        } catch (e) {
          blobs.push({ filename: f, blob: null, error: e.message });
        }
      }
      return { jobId, job, blobs };
    }
  }

  global.BlendStoryClient = BlendStoryClient;
})(typeof window !== 'undefined' ? window : globalThis);
