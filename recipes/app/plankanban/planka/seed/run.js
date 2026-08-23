/*
 * Play the Northstar seed into Planka.
 *
 * The seed file holds one complete request per line, `METHOD PATH BIND BODY`
 * split on the first three spaces. `BIND` names the id the call returns so a
 * later line can refer to it as `@name@`; `-` means there is nothing to keep.
 *
 * Three things this runner does that the seed file cannot say for itself:
 *
 *  - It signs in. Planka's first sign-in for any account is a two-step
 *    handshake: the password is refused with a pending token and a demand that
 *    the terms be accepted, and the real token only comes back from
 *    /api/access-tokens/accept-terms with the signature the terms endpoint
 *    publishes. Every account has to go through it once.
 *
 *  - It acts as the right person. Planka takes the author of a card or a
 *    comment from the token, never from the body, so a line carrying `_as`
 *    is sent with that person's token instead of the administrator's.
 *
 *  - It moves the story to now. The world is anchored to one August week, and a
 *    version built then may be launched at any later date, so every instant in
 *    the seed is shifted by the same whole number of weeks before it is used.
 *    Whole weeks, so a Tuesday review still falls on a Tuesday. The API has no
 *    way to say when a card was written, so those two columns are set
 *    afterwards through the connection Planka itself is configured with.
 */
'use strict';

const fs = require('fs');
const crypto = require('crypto');

const BASE = process.env.DROPLIVE_PLANKA_BASE || 'http://127.0.0.1:1337';
const SEED = process.env.DROPLIVE_PLANKA_SEED || '/usr/local/lib/droplive-planka-seed.jsonl';
const ANCHOR = new Date('2026-08-21T09:00:00Z');

const WEEK = 7 * 24 * 3600 * 1000;
const SHIFT = Math.max(0, Math.floor((Date.now() - ANCHOR.getTime()) / WEEK)) * WEEK;

const ids = new Map();
const tokens = new Map();
const passwords = new Map();
const backdate = [];

function shifted(iso) {
  return new Date(new Date(iso).getTime() + SHIFT).toISOString();
}

function resolve(text) {
  return text.replace(/@([a-z]+:[^@]+)@/g, (whole, name) => {
    if (name === 'secret:random') return crypto.randomBytes(18).toString('base64url');
    const value = ids.get(name);
    if (value === undefined) throw new Error('nothing bound for ' + name);
    return value;
  });
}

async function json(method, path, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = 'Bearer ' + token;
  const response = await fetch(BASE + path, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let parsed = null;
  try { parsed = JSON.parse(text); } catch (error) { /* not every answer is json */ }
  return { status: response.status, body: parsed, text };
}

let termsSignature = null;

async function signIn(username, password) {
  if (tokens.has(username)) return tokens.get(username);

  if (termsSignature === null) {
    const terms = await json('GET', '/api/terms');
    termsSignature = terms.body && terms.body.item && terms.body.item.signature;
  }

  let attempt = await json('POST', '/api/access-tokens', {
    emailOrUsername: username,
    password,
  });

  // A first sign-in is refused until the terms are accepted, and hands back the
  // pending token that accepting them needs.
  if (attempt.status === 403 && attempt.body && attempt.body.pendingToken) {
    attempt = await json('POST', '/api/access-tokens/accept-terms', {
      pendingToken: attempt.body.pendingToken,
      signature: termsSignature,
      initialLanguage: 'en-GB',
    });
  }

  const token = attempt.body && attempt.body.item;
  if (!token) throw new Error('could not sign in as ' + username + ': ' + attempt.text.slice(0, 200));
  tokens.set(username, token);
  return token;
}

async function waitForPlanka() {
  for (let waited = 0; waited < 180; waited += 1) {
    try {
      // The terms are the only thing Planka will show without a token, and
      // they are read from disk during startup, so an answer here means the
      // app is up rather than merely listening.
      const answer = await fetch(BASE + '/api/terms');
      await answer.arrayBuffer();
      if (answer.ok) return true;
    } catch (error) { /* not up yet */ }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  return false;
}

async function main() {
  if (!fs.existsSync(SEED)) return;
  if (!await waitForPlanka()) {
    process.stderr.write('[droplive] planka did not become ready; skipping seed\n');
    return;
  }

  const admin = process.env.DEFAULT_ADMIN_USERNAME || 'maya';
  const adminToken = await signIn(admin, process.env.DEFAULT_ADMIN_PASSWORD);
  ids.set('user:maya', (await json('GET', '/api/users/me', undefined, adminToken)).body.item.id);

  // Nothing here can be written twice: a second run would make a second copy of
  // every board rather than recognising the first, so a restart leaves the
  // boards it already made alone.
  const existing = await json('GET', '/api/projects', undefined, adminToken);
  if (existing.body && Array.isArray(existing.body.items) && existing.body.items.length > 0) {
    process.stderr.write('[droplive] the boards are already here\n');
    return;
  }

  const lines = fs.readFileSync(SEED, 'utf8').split('\n').filter((line) => line.trim());
  let played = 0;

  for (const line of lines) {
    const first = line.indexOf(' ');
    const second = line.indexOf(' ', first + 1);
    const third = line.indexOf(' ', second + 1);
    const method = line.slice(0, first);
    const path = resolve(line.slice(first + 1, second));
    const bind = line.slice(second + 1, third);
    const body = JSON.parse(resolve(line.slice(third + 1)));

    const as = body._as;
    const created = body._created;
    delete body._as;
    delete body._created;
    if (body.dueDate) body.dueDate = shifted(body.dueDate);

    let token = adminToken;
    if (as && as !== 'maya') {
      // Everyone else is created by this seed, so their password is the one it
      // just minted for them.
      token = await signIn(as, passwords.get(as));
    }

    const answer = await json(method, path, body, token);
    if (answer.status >= 300) {
      process.stderr.write('[droplive] ' + method + ' ' + path + ' -> ' + answer.status
        + ' ' + answer.text.slice(0, 160) + '\n');
      continue;
    }
    played += 1;

    const item = answer.body && answer.body.item;
    if (bind !== '-' && item && item.id) ids.set(bind, item.id);
    if (bind.startsWith('user:') && body.password) passwords.set(body.username, body.password);

    if (created && item && item.id) {
      backdate.push({ table: bind.startsWith('card:') ? 'card' : 'comment', id: item.id, at: shifted(created) });
    }
  }

  process.stderr.write('[droplive] played ' + played + ' of ' + lines.length + ' calls\n');
  await applyDates();
}

async function applyDates() {
  if (backdate.length === 0) return;
  // Planka's API cannot say when a card or a comment was written, and a board
  // whose every comment is a few seconds old is the one thing a worked-in board
  // never looks like. The rows are corrected through Planka's own datasource.
  const { Client } = require('/app/node_modules/pg');
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  try {
    for (const row of backdate) {
      if (row.table === 'card') {
        await client.query(
          'UPDATE card SET created_at = $1, updated_at = $1, list_changed_at = $1 WHERE id = $2',
          [row.at, row.id]);
        await client.query('UPDATE action SET created_at = $1, updated_at = $1 WHERE card_id = $2',
          [row.at, row.id]);
      } else {
        await client.query('UPDATE comment SET created_at = $1, updated_at = $1 WHERE id = $2',
          [row.at, row.id]);
      }
    }
    process.stderr.write('[droplive] dated ' + backdate.length + ' rows, shifted '
      + (SHIFT / WEEK) + ' weeks\n');
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  process.stderr.write('[droplive] seed failed: ' + error.message + '\n');
});
