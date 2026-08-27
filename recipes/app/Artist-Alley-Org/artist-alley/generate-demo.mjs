#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const root = process.argv[2];
if (!root) throw new Error('seed root is required');
const catalogue = path.join(root, 'catalogue');
const site = path.join(root, 'site');
const media = path.join(site, 'media');
fs.mkdirSync(catalogue, { recursive: true });
fs.mkdirSync(media, { recursive: true });

const teams = [
  ['10000000-0000-4000-8000-000000000001', 'Characters'],
  ['10000000-0000-4000-8000-000000000002', 'Environment'],
  ['10000000-0000-4000-8000-000000000003', 'UI/UX'],
  ['10000000-0000-4000-8000-000000000004', 'Marketing Art'],
].map(([id, name]) => ({ id, name }));

const users = [
  ['maya.chen', 'Maya Chen', 'maya@emberlight.droplive.test', 'Characters'],
  ['jon.bell', 'Jon Bell', 'jon@emberlight.droplive.test', 'Characters'],
  ['noor.alvarez', 'Noor Alvarez', 'noor@emberlight.droplive.test', 'Environment'],
  ['elena.petrov', 'Elena Petrov', 'elena@emberlight.droplive.test', 'Environment'],
  ['hana.ito', 'Hana Ito', 'hana@emberlight.droplive.test', 'UI/UX'],
  ['theo.martin', 'Theo Martin', 'theo@emberlight.droplive.test', 'UI/UX'],
  ['samira.okafor', 'Samira Okafor', 'samira@emberlight.droplive.test', 'Marketing Art'],
  ['lucas.meyer', 'Lucas Meyer', 'lucas@emberlight.droplive.test', 'Marketing Art'],
].map(([username, full_name, email, primary_team]) => ({ username, full_name, email, primary_team }));

const collectionDefs = [
  ['20000000-0000-4000-8000-000000000001', 'Lumenfall Heroes', true, 'public'],
  ['20000000-0000-4000-8000-000000000002', 'Moonlit Harbor', true, 'public'],
  ['20000000-0000-4000-8000-000000000003', 'Emberglass UI System', true, 'public'],
  ['20000000-0000-4000-8000-000000000004', 'Launch Key Art', true, 'public'],
  ['20000000-0000-4000-8000-000000000005', 'Release Candidate Review', false, 'org-only'],
];
const collections = collectionDefs.map(([id, name, featured, visibility]) => ({ id, name, featured, visibility }));

const fields = [
  { name: 'pipeline_stage', label: 'Pipeline stage', type: 'select', options: ['Concept', 'Blockout', 'Polish', 'Final'] },
  { name: 'version', label: 'Version', type: 'text' },
  { name: 'revision_count', label: 'Revisions', type: 'number' },
  { name: 'rating', label: 'Art review rating', type: 'number' },
  { name: 'target_platforms', label: 'Target platforms', type: 'multi_select', options: ['PC', 'Console', 'Mobile'] },
  { name: 'naming_compliant', label: 'Naming compliant', type: 'boolean' },
];

const families = [
  {
    team: 'Characters', collection: 'Lumenfall Heroes', owners: ['maya.chen', 'jon.bell'],
    titles: ['Astra Dawnwarden', 'Kael Ember Scout', 'Mira Tidecaller', 'Orin Mosskeeper', 'Nyra Glassblade', 'Sol Archive Mage', 'Vela Moon Ranger', 'Tarin Forge Adept', 'Iris Wisp Binder', 'Bram Harbor Guard', 'Edda Star Cartographer', 'Rook Lantern Smith'],
    palettes: [['#ff8a5c','#50205e'],['#f6c85f','#2f4858'],['#62c4c3','#183446'],['#82b440','#24331c']],
  },
  {
    team: 'Environment', collection: 'Moonlit Harbor', owners: ['noor.alvarez', 'elena.petrov'],
    titles: ['Beacon Pier at Dusk', 'Tide Market Rooftops', 'Glassworks Canal', 'Lantern Ferry Landing', 'Stormwall Gate', 'Old Observatory Walk', 'Netmakers Court', 'Sunken Archive Steps', 'Moon Pool Shrine', 'Copper Crane Yard', 'Rain Garden Alley', 'Harbormaster Balcony'],
    palettes: [['#49a6a6','#102a43'],['#8d6bb8','#241b4b'],['#e3a857','#27384a'],['#4e8098','#14213d']],
  },
  {
    team: 'UI/UX', collection: 'Emberglass UI System', owners: ['hana.ito', 'theo.martin'],
    titles: ['Quest Log Panel', 'Inventory Grid', 'Party Status HUD', 'Map Marker Family', 'Crafting Recipe Card', 'Dialogue Choice Stack', 'Controller Prompt Set', 'Accessibility Menu', 'Fast Travel Overlay', 'Codex Entry Layout', 'Merchant Compare View', 'Photo Mode Controls'],
    palettes: [['#ffb703','#023047'],['#8ecae6','#1d3557'],['#fb8500','#3a0ca3'],['#90be6d','#264653']],
  },
  {
    team: 'Marketing Art', collection: 'Launch Key Art', owners: ['samira.okafor', 'lucas.meyer'],
    titles: ['Across the Ember Sea', 'Heroes of Lumenfall', 'Moonlit Harbor Panorama', 'Wildwood Awakening', 'The Glass Crown', 'Launch Edition Sleeve', 'Festival Announcement', 'Collector Map Insert', 'Store Capsule Set', 'Press Kit Portraits', 'Release Countdown', 'Day One Social Banner'],
    palettes: [['#ef476f','#073b4c'],['#ffd166','#3d348b'],['#06d6a0','#1b4332'],['#f77f00','#003049']],
  },
];

const states = ['draft', 'in_review', 'approved', 'published'];
const stages = ['Concept', 'Blockout', 'Polish', 'Final'];
const assets = [];
const posts = [];
let assetNo = 0;
let postNo = 0;

function uuid(prefix, n) {
  return `${prefix}000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
}

function svgFor(title, team, colors, index) {
  const [accent, dark] = colors;
  const motif = team === 'Characters'
    ? `<circle cx="480" cy="220" r="96" fill="${accent}" opacity=".92"/><path d="M300 630 Q480 300 660 630Z" fill="${accent}" opacity=".72"/><path d="M410 210 Q480 95 550 210" fill="none" stroke="#fff" stroke-width="18"/>`
    : team === 'Environment'
      ? `<path d="M0 590 L170 330 300 470 470 210 620 420 770 280 960 520V720H0Z" fill="${accent}" opacity=".78"/><circle cx="755" cy="150" r="62" fill="#fff" opacity=".8"/>`
      : team === 'UI/UX'
        ? `<rect x="170" y="130" width="620" height="430" rx="34" fill="#f8f5ec" opacity=".96"/><rect x="215" y="185" width="250" height="30" rx="15" fill="${accent}"/><rect x="215" y="250" width="530" height="90" rx="18" fill="${dark}" opacity=".12"/><rect x="215" y="375" width="160" height="120" rx="18" fill="${accent}" opacity=".8"/><rect x="400" y="375" width="345" height="24" rx="12" fill="${dark}" opacity=".22"/>`
        : `<circle cx="480" cy="340" r="235" fill="${accent}" opacity=".68"/><path d="M250 560 Q480 90 710 560" fill="none" stroke="#fff" stroke-width="24" opacity=".78"/><path d="M160 610H800" stroke="${accent}" stroke-width="32"/>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="720" viewBox="0 0 960 720"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="${dark}"/><stop offset="1" stop-color="#0b132b"/></linearGradient><pattern id="p" width="44" height="44" patternUnits="userSpaceOnUse" patternTransform="rotate(${index * 7})"><path d="M0 22H44" stroke="#fff" opacity=".05" stroke-width="2"/></pattern></defs><rect width="960" height="720" fill="url(#g)"/><rect width="960" height="720" fill="url(#p)"/>${motif}<text x="54" y="632" fill="#fff" font-family="sans-serif" font-size="32" font-weight="700">${title}</text><text x="56" y="674" fill="#fff" opacity=".7" font-family="sans-serif" font-size="19">EMBERLIGHT GAMES · LUMENFALL · ${team.toUpperCase()}</text></svg>`;
}

for (const [familyIndex, family] of families.entries()) {
  for (let i = 0; i < family.titles.length; i++) {
    assetNo++;
    const id = uuid('30', assetNo);
    const title = family.titles[i];
    const filename = `asset-${String(assetNo).padStart(2, '0')}.svg`;
    fs.writeFileSync(path.join(media, filename), svgFor(title, family.team, family.palettes[i % family.palettes.length], i));
    const inReview = i % 4 === 1 || i % 4 === 2;
    assets.push({
      id,
      asset_type: 'image',
      title,
      description: `${family.team} artwork for Lumenfall's release-candidate review. Prepared as part of the coordinated Emberlight Games launch library.`,
      file_path: `media/${filename}`,
      file_extension: 'svg',
      file_size_bytes: fs.statSync(path.join(media, filename)).size,
      sensitivity_tier: i % 6 === 5 ? 'team' : 'public',
      archive_state: states[i % states.length],
      owner_username: family.owners[i % family.owners.length],
      collection_name: family.collection,
      team_name: family.team,
      tags: ['lumenfall', family.team.toLowerCase().replaceAll('/', '-').replaceAll(' ', '-'), stages[i % stages.length].toLowerCase(), `release-${i < 8 ? 'candidate' : 'launch'}`],
      workflow_state: states[i % states.length],
      metadata: { studio: 'Emberlight Games', project: 'Lumenfall', season: 'Launch', source: 'DropLive original demo artwork', license: 'CC0-1.0' },
      field_values: { pipeline_stage: stages[i % stages.length], version: `v${1 + (i % 4)}.${i % 3}`, revision_count: 2 + (i % 7), rating: 3 + (i % 3), target_platforms: i % 3 === 0 ? ['PC', 'Console'] : ['PC'], naming_compliant: true },
      review_notes: inReview ? (i % 2 ? 'Review the silhouette at card size and preserve the warm focal contrast.' : 'Approved direction. Tighten the edge hierarchy before the final export.') : '',
      reviewer_username: family.owners[(i + 1) % family.owners.length],
      created_at: `2026-07-${String(4 + familyIndex * 5 + Math.floor(i / 3)).padStart(2, '0')}T${String(9 + (i % 7)).padStart(2, '0')}:00:00Z`,
      updated_at: `2026-08-${String(8 + Math.floor(i / 2)).padStart(2, '0')}T${String(10 + (i % 6)).padStart(2, '0')}:30:00Z`,
    });
  }

  const familyAssets = assets.slice(familyIndex * 12, familyIndex * 12 + 12);
  for (let i = 0; i < 6; i++) {
    postNo++;
    const pair = familyAssets.slice(i * 2, i * 2 + 2);
    posts.push({
      id: uuid('40', postNo),
      title: `${family.collection} · ${stages[i % stages.length]} review ${i + 1}`,
      description: `${pair[0].title} and ${pair[1].title} are ready for the ${stages[i % stages.length].toLowerCase()} review. The team is checking visual hierarchy, production fit and launch consistency.`,
      asset_ids: pair.map(a => a.id),
      author_username: family.owners[i % family.owners.length],
      collection_name: family.collection,
      team_name: family.team,
      workflow_state: 'published',
      tags: ['lumenfall', 'review', stages[i % stages.length].toLowerCase(), family.team.toLowerCase().replaceAll('/', '-')],
      post_kind: 'multi_asset',
      sensitivity_tier: i === 5 ? 'team' : 'public',
      is_mixed_type: false,
      created_at: `2026-08-${String(10 + familyIndex * 3 + Math.floor(i / 2)).padStart(2, '0')}T${String(9 + i).padStart(2, '0')}:15:00Z`,
      updated_at: `2026-08-${String(16 + familyIndex * 2 + Math.floor(i / 3)).padStart(2, '0')}T${String(11 + i).padStart(2, '0')}:45:00Z`,
    });
  }
}

// A release review collection cuts across departments without duplicating
// assets. The seeder links collection membership from each asset's primary
// project and links these multi-team posts to the release review queue.
for (let i = 0; i < 4; i++) {
  postNo++;
  const members = families.map((_, familyIndex) => assets[familyIndex * 12 + i * 2]);
  posts.push({
    id: uuid('40', postNo),
    title: `Release candidate ${i + 1} · cross-team checkpoint`,
    description: `A production checkpoint that brings ${members.map(a => a.title).join(', ')} into one release decision. Owners have recorded the remaining polish notes.`,
    asset_ids: members.map(a => a.id),
    author_username: i % 2 ? 'samira.okafor' : 'maya.chen',
    collection_name: 'Release Candidate Review',
    team_name: i % 2 ? 'Marketing Art' : 'Characters',
    workflow_state: 'published',
    tags: ['lumenfall', 'release-candidate', 'cross-team', `checkpoint-${i + 1}`],
    post_kind: 'multi_asset',
    sensitivity_tier: 'org-only',
    is_mixed_type: false,
    created_at: `2026-08-${20 + i}T14:00:00Z`,
    updated_at: `2026-08-${22 + i}T16:30:00Z`,
  });
}

fs.writeFileSync(path.join(catalogue, 'dataset.users.json'), JSON.stringify(users, null, 2));
fs.writeFileSync(path.join(catalogue, 'dataset.teams.json'), JSON.stringify(teams, null, 2));
fs.writeFileSync(path.join(catalogue, 'dataset.collections.json'), JSON.stringify(collections, null, 2));
fs.writeFileSync(path.join(catalogue, 'dataset.field_definitions.json'), JSON.stringify(fields, null, 2));
fs.writeFileSync(path.join(site, 'MANIFEST.json'), JSON.stringify(assets, null, 2));
fs.writeFileSync(path.join(site, 'posts.json'), JSON.stringify(posts, null, 2));
fs.writeFileSync(path.join(site, 'ATTRIBUTIONS.md'), '# Emberlight Games demo artwork\n\nAll artwork in this DropLive recipe is original procedural SVG artwork released as CC0-1.0 for this disposable demo.\n');

console.log(`generated Emberlight Games seed: ${users.length} people, ${teams.length} teams, ${collections.length} collections, ${assets.length} assets, ${posts.length} posts`);
