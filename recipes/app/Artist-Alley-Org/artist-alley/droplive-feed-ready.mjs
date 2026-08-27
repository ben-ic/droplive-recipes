import { readFileSync } from 'node:fs';

const minimumPosts = 24;

try {
  const response = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  const items = Array.isArray(response.items) ? response.items : [];
  if (items.length < minimumPosts) process.exit(1);

  const readyCovers = items.filter((post) => {
    const members = Array.isArray(post.members) ? post.members : [];
    const cover = members.find((member) => member.asset_id === post.cover_asset_id)
      ?? members[0];
    return cover?.asset?.preview_available === true;
  }).length;

  if (readyCovers < minimumPosts) process.exit(1);
  process.stdout.write(
    `artist-alley first feed ready: ${readyCovers}/${items.length} cover previews\n`,
  );
} catch {
  process.exit(1);
}
