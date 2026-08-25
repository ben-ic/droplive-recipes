/*
 * Northstar Relay traffic for Umami, generated against the container's clock.
 *
 * Umami is the one seeded app whose front page is a fixed recent window: it
 * opens on the last twenty-four hours. A history written at authoring time is
 * therefore already wrong by the time the version is built, and a version
 * launched weeks later opens on an empty dashboard with every event hidden
 * behind the date picker. So the history is generated at start instead of
 * shipped as rows: it always ends at this moment, weekends always fall on
 * weekends, and the export incident is always about three weeks ago.
 *
 * Two modes:
 *   --sql   print the history as SQL for `prisma db execute --stdin`
 *   --live  keep the site alive, posting visits to /api/send as they happen
 *
 * The two agree because they draw from the same page, referrer and device
 * model, so a visitor watching Realtime sees the same site the charts describe.
 *
 * Identifiers are derived from a day offset rather than a date, so a restart
 * inside the same container regenerates exactly the same rows and the
 * ON CONFLICT DO NOTHING on every insert makes the second run a no-op.
 */
'use strict';

const crypto = require('crypto');

const DOMAIN = 'northstar-relay.droplive.test';
const WEBSITE_NAME = 'Northstar Relay';
const DAYS = 45;
// Scheduled exports first crossed the worker row limit here, the same event the
// Kanboard board, the Metabase model and the Lumen renewal all turn on.
const INCIDENT_DAYS_AGO = 18;
const NAMESPACE = '6f9619ff-8b86-d011-b42d-00c04fc964ff';

const PAGES = [
  ['/', 'Northstar Relay — automated data exports', 22],
  ['/pricing', 'Pricing — Northstar Relay', 12],
  ['/docs/exports', 'Exports — Northstar Relay docs', 14],
  ['/docs/scheduled-exports', 'Scheduled exports — Northstar Relay docs', 8],
  ['/docs/connectors', 'Connectors — Northstar Relay docs', 7],
  ['/changelog', 'Changelog — Northstar Relay', 6],
  ['/status', 'Status — Northstar Relay', 5],
  ['/login', 'Sign in — Northstar Relay', 15],
  ['/signup', 'Create an account — Northstar Relay', 6],
  ['/blog/audit-history', 'What is coming in 2.8 — Northstar Relay', 5],
];

const REFERRERS = [
  [null, null, 34],
  ['www.google.com', '/search', 26],
  ['github.com', '/northstar-relay', 12],
  ['news.ycombinator.com', '/item', 9],
  ['duckduckgo.com', '/', 6],
  ['www.reddit.com', '/r/selfhosted', 7],
  ['lumen-labs.droplive.test', '/tools', 6],
];

const BROWSERS = [['chrome', 46], ['firefox', 18], ['safari', 20], ['edge', 11], ['brave', 5]];
const SYSTEMS = [['Mac OS', 34], ['Windows', 33], ['Linux', 18], ['iOS', 10], ['Android', 5]];
const DEVICES = [['desktop', 80], ['mobile', 15], ['tablet', 5]];
const SCREENS = ['1920x1080', '1440x900', '2560x1440', '1366x768', '390x844'];
const LANGUAGES = ['en-GB', 'en-US', 'de-DE', 'nl-NL', 'pt-PT', 'fr-FR'];
const PLACES = [
  ['GB', 'ENG', 'London'], ['GB', 'WLS', 'Cardiff'], ['NL', 'NH', 'Amsterdam'],
  ['DE', 'BE', 'Berlin'], ['PT', '13', 'Porto'], ['IE', 'L', 'Dublin'],
  ['US', 'NY', 'New York'], ['ES', 'MD', 'Madrid'], ['FR', 'IDF', 'Paris'],
];

// A visitor arrives during the working day, wherever they are.
const ARRIVAL_HOURS = [8, 9, 9, 10, 10, 11, 11, 13, 14, 14, 15, 16, 16, 17, 20];

const USER_AGENTS = {
  chrome: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
  firefox: 'Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0',
  safari: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
  edge: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0',
  brave: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
};

function uuid5(name) {
  const ns = Buffer.from(NAMESPACE.replace(/-/g, ''), 'hex');
  const hash = crypto.createHash('sha1').update(Buffer.concat([ns, Buffer.from(name, 'utf8')])).digest();
  const bytes = Buffer.from(hash.subarray(0, 16));
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return [hex.slice(0, 8), hex.slice(8, 12), hex.slice(12, 16), hex.slice(16, 20), hex.slice(20)].join('-');
}

// A small deterministic generator, so the same offset always describes the same
// visitor no matter when the container starts.
function rngFrom(seedText) {
  let state = crypto.createHash('sha1').update(seedText).digest().readUInt32BE(0);
  return function next() {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick(rand, list) {
  return list[Math.floor(rand() * list.length)];
}

function weighted(rand, options) {
  const total = options.reduce((sum, option) => sum + option[option.length - 1], 0);
  let mark = rand() * total;
  for (const option of options) {
    mark -= option[option.length - 1];
    if (mark <= 0) return option;
  }
  return options[options.length - 1];
}

function between(rand, low, high) {
  return low + Math.floor(rand() * (high - low + 1));
}

const WEBSITE_ID = uuid5('website|' + DOMAIN);

// A weekday carries a working audience; the weekend does not. Traffic grows
// slowly across the period, the way a product that is being adopted does.
function visitsForDay(rand, date, offset) {
  const weekday = date.getUTCDay();
  const base = weekday === 0 || weekday === 6 ? 92 : 254;
  const trend = 1 + 0.45 * (offset / (DAYS - 1));
  return Math.round(base * trend * (0.85 + rand() * 0.3));
}

function pagesFor(afterIncident) {
  if (!afterIncident) return PAGES;
  // Once exports start failing, arrivals land on the page that explains the
  // thing that is failing, and on the status page.
  return PAGES.map(([path, title, weight]) => [
    path,
    title,
    weight * (path === '/docs/scheduled-exports' ? 4 : path === '/status' ? 3 : 1),
  ]);
}

function describeVisit(rand, afterIncident) {
  const [browser] = weighted(rand, BROWSERS);
  const [os] = weighted(rand, SYSTEMS);
  const [device] = weighted(rand, DEVICES);
  const [referrerDomain, referrerPath] = weighted(rand, REFERRERS);
  const [country, region, city] = pick(rand, PLACES);
  const pages = pagesFor(afterIncident);
  const depth = pick(rand, [1, 1, 2, 2, 2, 3, 3, 4, 5]);
  const steps = [];
  for (let step = 0; step < depth; step += 1) {
    const [path, title] = weighted(rand, pages);
    steps.push({ path, title });
  }
  return {
    browser, os, device, country, region, city,
    screen: pick(rand, SCREENS),
    language: pick(rand, LANGUAGES),
    referrerDomain, referrerPath, steps,
  };
}

function sqlString(value) {
  if (value === null || value === undefined) return 'NULL';
  return "'" + String(value).replace(/'/g, "''") + "'";
}

function stamp(date) {
  return date.toISOString().replace('T', ' ').slice(0, 19) + '+00';
}

function emitHistory(now) {
  const sessions = [];
  const events = [];
  const midnight = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());

  for (let offset = 0; offset < DAYS; offset += 1) {
    const daysAgo = DAYS - 1 - offset;
    const dayStart = midnight - daysAgo * 86400000;
    const date = new Date(dayStart);
    const afterIncident = daysAgo <= INCIDENT_DAYS_AGO;
    const dayRand = rngFrom('day|' + daysAgo);
    const total = visitsForDay(dayRand, date, offset);

    for (let visit = 0; visit < total; visit += 1) {
      const rand = rngFrom('visit|' + daysAgo + '|' + visit);
      const hour = pick(rand, ARRIVAL_HOURS);
      const started = new Date(dayStart + hour * 3600000 + between(rand, 0, 59) * 60000 + between(rand, 0, 59) * 1000);
      // Today is only as far along as the clock says it is.
      if (started > now) continue;

      const shape = describeVisit(rand, afterIncident);
      const sessionId = uuid5('session|' + daysAgo + '|' + visit);
      const visitId = uuid5('visit|' + daysAgo + '|' + visit);
      sessions.push([
        sessionId, WEBSITE_ID, shape.browser, shape.os, shape.device, shape.screen,
        shape.language, shape.country, shape.region, shape.city, stamp(started),
      ]);

      let when = started;
      shape.steps.forEach((step, index) => {
        if (when > now) return;
        events.push([
          uuid5('event|' + daysAgo + '|' + visit + '|' + index),
          WEBSITE_ID, sessionId, visitId, stamp(when), step.path, step.title,
          index === 0 ? shape.referrerDomain : DOMAIN,
          index === 0 ? shape.referrerPath : null,
        ]);
        when = new Date(when.getTime() + between(rand, 18, 240) * 1000);
      });
    }
  }

  const out = [];
  out.push('-- Northstar Relay traffic, generated at start against this clock.');
  out.push('BEGIN;');
  const created = stamp(new Date(midnight - 240 * 86400000));
  out.push(
    'INSERT INTO website (website_id, name, domain, user_id, created_at, recorder_enabled)\n' +
    'SELECT ' + sqlString(WEBSITE_ID) + ', ' + sqlString(WEBSITE_NAME) + ', ' + sqlString(DOMAIN) +
    ', u.user_id, ' + sqlString(created) + ", false FROM \"user\" u WHERE u.username = 'admin'\n" +
    'ON CONFLICT (website_id) DO NOTHING;');

  const sessionColumns = 'session_id, website_id, browser, os, device, screen, language, country, region, city, created_at';
  for (let start = 0; start < sessions.length; start += 200) {
    const values = sessions.slice(start, start + 200)
      .map((row) => '(' + row.map(sqlString).join(', ') + ')').join(',\n');
    out.push('INSERT INTO session (' + sessionColumns + ') VALUES\n' + values + '\nON CONFLICT (session_id) DO NOTHING;');
  }

  const eventColumns = 'event_id, website_id, session_id, visit_id, created_at, url_path, page_title, referrer_domain, referrer_path, event_type, hostname';
  for (let start = 0; start < events.length; start += 200) {
    const values = events.slice(start, start + 200)
      .map((row) => '(' + row.map(sqlString).join(', ') + ', 1, ' + sqlString(DOMAIN) + ')').join(',\n');
    out.push('INSERT INTO website_event (' + eventColumns + ') VALUES\n' + values + '\nON CONFLICT (event_id) DO NOTHING;');
  }

  out.push('COMMIT;');
  process.stdout.write(out.join('\n') + '\n');
  process.stderr.write('[droplive] ' + sessions.length + ' visits, ' + events.length + ' pageviews to ' + stamp(now) + '\n');
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function live(base) {
  // The site does not stop when the demo starts. Visits continue to arrive at
  // roughly the rate the history describes, so Realtime shows people reading
  // the same pages the charts are counting, and the current day keeps filling.
  let tick = 0;
  for (;;) {
    tick += 1;
    const rand = rngFrom('live|' + tick + '|' + process.pid);
    const shape = describeVisit(rand, true);
    const agent = USER_AGENTS[shape.browser] || USER_AGENTS.chrome;
    let referrer = shape.referrerDomain
      ? 'https://' + shape.referrerDomain + (shape.referrerPath || '')
      : '';

    for (const step of shape.steps) {
      try {
        const response = await fetch(base + '/api/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': agent,
            'X-Forwarded-For': [between(rand, 12, 210), between(rand, 0, 255), between(rand, 0, 255), between(rand, 1, 254)].join('.'),
          },
          body: JSON.stringify({
            type: 'event',
            payload: {
              website: WEBSITE_ID,
              hostname: DOMAIN,
              url: step.path,
              title: step.title,
              referrer,
              language: shape.language,
              screen: shape.screen,
            },
          }),
        });
        // The body has to be read even though nothing wants it: an unread
        // response holds its connection open and the next visit never sends.
        await response.arrayBuffer();
      } catch (error) {
        // A collector that is briefly unreachable is not a reason to stop.
      }
      referrer = 'https://' + DOMAIN;
      await sleep(between(rand, 14, 70) * 1000);
    }

    await sleep(between(rand, 40, 180) * 1000);
  }
}

const mode = process.argv[2];
if (mode === '--sql') {
  emitHistory(new Date());
} else if (mode === '--live') {
  live(process.argv[3] || 'http://127.0.0.1:3000').catch(() => process.exit(0));
} else {
  process.stderr.write('usage: umami-traffic.js --sql | --live [base-url]\n');
  process.exit(2);
}
