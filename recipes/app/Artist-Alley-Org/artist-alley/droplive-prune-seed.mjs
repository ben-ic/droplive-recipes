import fs from "node:fs";
import path from "node:path";

const [sourceRoot, targetRoot] = process.argv.slice(2);
if (!sourceRoot || !targetRoot) {
  throw new Error("usage: droplive-prune-seed.mjs SOURCE_ROOT TARGET_ROOT");
}

const allowedExtensions = new Set(["jpg", "jpeg", "png", "webp"]);
const maxAssets = 72;
const targetPublicPosts = 36;
const targetPosts = 52;

const readJson = (name) =>
  JSON.parse(fs.readFileSync(path.join(sourceRoot, name), "utf8"));

const assets = readJson("MANIFEST.json");
const posts = readJson("posts.json");
const assetsById = new Map(assets.map((asset) => [asset.id, asset]));

const safeSourcePath = (relativePath) => {
  const normalized = path.posix.normalize(String(relativePath || ""));
  if (normalized.startsWith("../") || path.posix.isAbsolute(normalized)) {
    throw new Error(`unsafe seed path: ${relativePath}`);
  }
  return normalized;
};

const candidates = posts.filter((post) => {
  if (!Array.isArray(post.asset_ids) || post.asset_ids.length === 0) return false;
  return post.asset_ids.every((id) => {
    const asset = assetsById.get(id);
    if (!asset || !allowedExtensions.has(String(asset.file_extension).toLowerCase())) {
      return false;
    }
    return fs.existsSync(path.join(sourceRoot, safeSourcePath(asset.file_path)));
  });
});

const selectedPosts = [];
const selectedPostIds = new Set();
const selectedAssetIds = new Set();

const canAdd = (post) => {
  const next = new Set(selectedAssetIds);
  for (const id of post.asset_ids) next.add(id);
  return next.size <= maxAssets;
};

const add = (post) => {
  if (!post || selectedPostIds.has(post.id) || !canAdd(post)) return false;
  selectedPostIds.add(post.id);
  selectedPosts.push(post);
  for (const id of post.asset_ids) selectedAssetIds.add(id);
  return true;
};

const publicPost = (post) => String(post.sensitivity_tier || "public") === "public";

// Preserve the catalogue's own order, but take one public example for every
// collection and team before filling the feed. This gives the demo breadth
// without inventing a second fictional world.
for (const key of ["collection_name", "team_name", "author_username"]) {
  const seen = new Set();
  for (const post of candidates) {
    const value = String(post[key] || "").trim();
    if (!value || seen.has(value) || !publicPost(post)) continue;
    if (add(post)) seen.add(value);
  }
}

for (const post of candidates) {
  if (selectedPosts.filter(publicPost).length >= targetPublicPosts) break;
  if (publicPost(post)) add(post);
}

for (const post of candidates) {
  if (selectedPosts.length >= targetPosts) break;
  add(post);
}

const selectedAssets = assets.filter((asset) => selectedAssetIds.has(asset.id));
const publicCount = selectedPosts.filter(publicPost).length;
const collectionCount = new Set(selectedPosts.map((post) => post.collection_name).filter(Boolean)).size;
const teamCount = new Set(selectedPosts.map((post) => post.team_name).filter(Boolean)).size;

if (selectedAssets.length < 48 || selectedPosts.length < 44 || publicCount < 30) {
  throw new Error(
    `official raster subset is too sparse: assets=${selectedAssets.length} ` +
      `posts=${selectedPosts.length} public=${publicCount}`,
  );
}

fs.mkdirSync(targetRoot, { recursive: true });
for (const name of ["ATTRIBUTIONS.md"]) {
  fs.copyFileSync(path.join(sourceRoot, name), path.join(targetRoot, name));
}

for (const asset of selectedAssets) {
  const relativePath = safeSourcePath(asset.file_path);
  const source = path.join(sourceRoot, relativePath);
  const target = path.join(targetRoot, relativePath);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(source, target);
}

fs.writeFileSync(
  path.join(targetRoot, "MANIFEST.json"),
  `${JSON.stringify(selectedAssets, null, 2)}\n`,
);
fs.writeFileSync(
  path.join(targetRoot, "posts.json"),
  `${JSON.stringify(selectedPosts, null, 2)}\n`,
);

process.stdout.write(
  `prepared official raster subset: assets=${selectedAssets.length} ` +
    `posts=${selectedPosts.length} public=${publicCount} ` +
    `collections=${collectionCount} teams=${teamCount}\n`,
);
