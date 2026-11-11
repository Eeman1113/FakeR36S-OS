// FakeR36S-OS box art, in the browser. The user picks the card's HOME drive (File System
// Access API, Chrome/Edge); every game without art gets libretro-thumbnails box art and a
// gamelist.xml entry. Same matching as tools/fetch-art.py. Nothing is uploaded.

const RAW = "https://raw.githubusercontent.com/libretro-thumbnails";
const SKIP_EXT = new Set(["xml", "old", "png", "jpg", "jpeg", "txt", "srm", "sav", "state", "auto",
  "cfg", "nfo", "pdf", "mp4", "dat", "ips", "bps", "ups", "rtc", "bak"]);
const SKIP_DIRS = new Set(["images", "downloaded_images", "media", "videos", "manuals", "icons", "snaps"]);
const REGION_RANK = ["usa", "world", "europe", "japan"];
const ART_SIZE = 320;

export const supported = () => "showDirectoryPicker" in window;

function norm(t) {
  t = t.replace(/^\d{3,4}\s*-\s*/, "").replace(/\([^)]*\)|\[[^\]]*\]/g, "");
  t = t.toLowerCase().replace(/&/g, "and").replace(/^the\s+|,\s*the\b/g, "");
  return t.replace(/[^a-z0-9]/g, "");
}
const tagsOf = (n) => [...n.matchAll(/\(([^)]*)\)/g)].map((m) => m[1]).join(" ").toLowerCase();

function pick(cands, stem) {
  const rt = tagsOf(stem) + " " + [...stem.matchAll(/\(([A-Z])\)/g)].map((m) => m[1]).join(" ").toLowerCase();
  const want = /\bj\b|japan/.test(rt) ? "japan" : /\be\b|europe/.test(rt) ? "europe" : "usa";
  const rank = (n) => {
    const t = tagsOf(n);
    const i = REGION_RANK.findIndex((k) => t.includes(k));
    return [t.includes(want) ? 0 : 1 + (i < 0 ? 9 : i), /rev|beta|proto/.test(t) ? 1 : 0, n.length];
  };
  return [...cands].sort((a, b) => {
    const x = rank(a), y = rank(b);
    return x[0] - y[0] || x[1] - y[1] || x[2] - y[2];
  })[0];
}

// similarity like Python's difflib ratio is overkill here; bigram Dice is close enough
function dice(a, b) {
  if (a.length < 2 || b.length < 2) return a === b ? 1 : 0;
  const m = new Map();
  for (let i = 0; i < a.length - 1; i++) { const g = a.slice(i, i + 2); m.set(g, (m.get(g) || 0) + 1); }
  let hit = 0;
  for (let i = 0; i < b.length - 1; i++) {
    const g = b.slice(i, i + 2), c = m.get(g) || 0;
    if (c) { hit++; m.set(g, c - 1); }
  }
  return (2 * hit) / (a.length + b.length - 2);
}

function makeIndex(names) {
  const idx = new Map(), exact = new Set(names);
  for (const n of names) { const k = norm(n); if (!idx.has(k)) idx.set(k, []); idx.get(k).push(n); }
  return { idx, exact, keys: [...idx.keys()] };
}

function match(stem, { idx, exact, keys }) {
  const ex = stem.replace(/[&*/:`<>?\\|"]/g, "_");
  if (exact.has(ex)) return ex;
  const k = norm(stem);
  if (!k) return null;
  if (idx.has(k)) return pick(idx.get(k), stem);
  const pre = keys.filter((c) => c.startsWith(k) && k.length >= 0.6 * c.length);
  if (pre.length) return pick(idx.get(pre.reduce((a, b) => (b.length < a.length ? b : a))), stem);
  let best = null, score = 0.88;
  for (const c of keys) { const s = dice(k, c); if (s > score) { score = s; best = c; } }
  return best ? pick(idx.get(best), stem) : null;
}

async function* walk(dir, prefix = "") {
  for await (const [name, h] of dir.entries()) {
    if (name.startsWith(".")) continue;
    if (h.kind === "directory") {
      if (!SKIP_DIRS.has(name.toLowerCase())) yield* walk(h, prefix + name + "/");
    } else {
      const ext = name.includes(".") ? name.split(".").pop().toLowerCase() : "";
      if (!SKIP_EXT.has(ext)) yield prefix + name;
    }
  }
}

async function readText(dir, name) {
  try { return await (await (await dir.getFileHandle(name)).getFile()).text(); } catch { return null; }
}

async function exists(dir, rel) {
  try {
    const parts = rel.replace(/^\.\//, "").split("/");
    for (const p of parts.slice(0, -1)) dir = await dir.getDirectoryHandle(p);
    await dir.getFileHandle(parts.at(-1));
    return true;
  } catch { return false; }
}

async function writeFile(dir, name, data) {
  const w = await (await dir.getFileHandle(name, { create: true })).createWritable();
  await w.write(data); await w.close();
}

async function shrink(blob) {
  try {
    const bmp = await createImageBitmap(blob);
    const s = Math.min(1, ART_SIZE / Math.max(bmp.width, bmp.height));
    const c = new OffscreenCanvas(Math.round(bmp.width * s), Math.round(bmp.height * s));
    c.getContext("2d").drawImage(bmp, 0, 0, c.width, c.height);
    return await c.convertToBlob({ type: "image/png" });
  } catch { return blob; }
}

async function pool(items, n, fn) {
  let i = 0;
  await Promise.all(Array.from({ length: n }, async () => { while (i < items.length) await fn(items[i++]); }));
}

// home: FileSystemDirectoryHandle of the card's HOME drive. onProgress(text, done, total)
export async function fetchArt(home, onProgress = () => {}) {
  let roms;
  try { roms = await home.getDirectoryHandle("roms"); }
  catch { throw new Error("No roms folder here. Pick the card's HOME drive itself."); }
  const systems = await (await fetch("art/systems.json")).json();
  let added = 0, missing = 0, considered = 0;

  for await (const [folder, sysdir] of roms.entries()) {
    if (sysdir.kind !== "directory" || !systems[folder]) continue;
    const files = [];
    for await (const f of walk(sysdir)) files.push(f);
    if (!files.length) continue;

    const xmlText = await readText(sysdir, "gamelist.xml");
    let doc = xmlText && new DOMParser().parseFromString(xmlText, "application/xml");
    if (!doc || doc.querySelector("parsererror")) doc = new DOMParser().parseFromString("<gameList/>", "application/xml");
    const root = doc.documentElement;
    const games = new Map();
    for (const g of root.querySelectorAll(":scope > game")) {
      const p = (g.querySelector("path")?.textContent || "").trim().replace(/^\.\//, "");
      games.set(p, g);
    }
    const todo = [];
    for (const rel of files) {
      const img = games.get(rel)?.querySelector("image")?.textContent?.trim();
      if (img && (await exists(sysdir, img))) continue;
      todo.push(rel);
    }
    considered += files.length;
    if (!todo.length) { onProgress(`${folder}: all ${files.length} games already have art`); continue; }

    const index = { names: [], owner: new Map() };
    for (const repo of systems[folder]) {
      try {
        const names = await (await fetch(`art/${repo}.json`)).json();
        for (const n of names) { index.names.push(n); if (!index.owner.has(n)) index.owner.set(n, repo); }
      } catch {}
    }
    const ix = makeIndex(index.names);
    const jobs = [];
    for (const rel of todo) {
      const stem = rel.split("/").pop().replace(/\.[^.]+$/, "");
      const hit = match(stem, ix);
      if (hit) jobs.push({ rel, hit, img: rel.replace(/\.[^.]+$/, "").replaceAll("/", "_") + ".png" });
      else missing++;
    }
    if (!jobs.length) continue;
    const images = await sysdir.getDirectoryHandle("images", { create: true });
    let done = 0, ok = 0;
    await pool(jobs, 6, async (j) => {
      try {
        const url = `${RAW}/${index.owner.get(j.hit)}/master/Named_Boxarts/${encodeURIComponent(j.hit)}.png`;
        const r = await fetch(url);
        if (!r.ok) throw new Error(r.status);
        await writeFile(images, j.img, await shrink(await r.blob()));
        let g = games.get(j.rel);
        if (!g) {
          g = doc.createElement("game"); root.appendChild(g);
          const p = doc.createElement("path"); p.textContent = "./" + j.rel; g.appendChild(p);
          const n = doc.createElement("name"); n.textContent = j.hit.replace(/\s*\(.*$/, "").trim(); g.appendChild(n);
          games.set(j.rel, g);
        }
        let im = g.querySelector("image");
        if (!im) { im = doc.createElement("image"); g.appendChild(im); }
        im.textContent = "./images/" + j.img;
        ok++;
      } catch { missing++; }
      onProgress(`${folder}: ${++done} of ${jobs.length}`, done, jobs.length);
    });
    let out = new XMLSerializer().serializeToString(doc);
    if (!out.startsWith("<?xml")) out = '<?xml version="1.0"?>\n' + out;
    await writeFile(sysdir, "gamelist.xml", out);
    added += ok;
    onProgress(`${folder}: ${ok} box arts added`);
  }
  return { added, missing, considered };
}
export { match, makeIndex };
