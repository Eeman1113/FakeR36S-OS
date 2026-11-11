// FakeR36S-OS update, in the browser: puts the update package on the card's HOME drive
// (File System Access API, Chrome/Edge). The console installs it on its next boot
// (/usr/local/bin/fr-update) and keeps every save, setting and game. Nothing is uploaded.

const PKG_NAME = "fakers36s-update-a23_panel2.tar";
const PKG_URL = "https://github.com/Eeman1113/FakeR36S-OS/releases/download/latest/" + PKG_NAME;

export const supported = () => "showDirectoryPicker" in window;

// Try the release directly; GitHub's release downloads usually refuse cross-site requests, so
// the page falls back to a file the user downloads themselves.
export async function fetchPackage(onProgress = () => {}) {
  const r = await fetch(PKG_URL);
  if (!r.ok) throw new Error("HTTP " + r.status);
  const total = +r.headers.get("content-length") || 0;
  const reader = r.body.getReader();
  const chunks = [];
  let got = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value); got += value.length; onProgress(got, total);
  }
  return new File(chunks, PKG_NAME);
}

// Reads the package's manifest.txt (a plain tar: 512-byte headers, octal sizes)
export async function readManifest(file) {
  let off = 0;
  for (let i = 0; i < 16 && off + 512 <= file.size; i++) {
    const h = new Uint8Array(await file.slice(off, off + 512).arrayBuffer());
    const name = new TextDecoder().decode(h.slice(0, 100)).replace(/\0.*$/s, "");
    if (!name) break;
    const size = parseInt(new TextDecoder().decode(h.slice(124, 136)).replace(/\0.*$/s, "").trim() || "0", 8);
    if (name === "manifest.txt") {
      const text = await file.slice(off + 512, off + 512 + size).text();
      const m = {};
      for (const line of text.split("\n")) { const k = line.indexOf("="); if (k > 0) m[line.slice(0, k)] = line.slice(k + 1); }
      return m;
    }
    off += 512 + Math.ceil(size / 512) * 512;
  }
  throw new Error("This is not a FakeR36S-OS update package (no manifest.txt).");
}

export async function checkHome(home) {
  for (const name of [".romdirs", ".emulationstation"]) {
    try {
      if (name.startsWith(".e")) await home.getDirectoryHandle(name); else await home.getFileHandle(name);
    } catch {
      throw new Error("That drive doesn't look like a FakeR36S-OS HOME. Pick the card's HOME drive itself.");
    }
  }
}

// Writes the package to HOME/update/ (the browser commits the file only when it is complete)
export async function writePackage(home, file, onProgress = () => {}) {
  const dir = await home.getDirectoryHandle("update", { create: true });
  for await (const [name] of dir.entries()) {           // one package at a time
    if (name.startsWith("fakers36s-update") && name.endsWith(".tar") && name !== PKG_NAME) await dir.removeEntry(name);
  }
  const w = await (await dir.getFileHandle(PKG_NAME, { create: true })).createWritable();
  let done = 0;
  const step = 4 << 20;
  for (let off = 0; off < file.size; off += step) {
    await w.write(await file.slice(off, off + step).arrayBuffer());
    done = Math.min(file.size, off + step);
    onProgress(done, file.size);
  }
  await w.close();
  const written = await (await dir.getFileHandle(PKG_NAME)).getFile();
  if (written.size !== file.size) throw new Error("The copy on the card is incomplete. Try again.");
}
