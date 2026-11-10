// FakeR36S-OS web installer core. Runs entirely in the browser (also importable from Node for tests).
// Nothing is uploaded: the stock backup is read locally with File.slice().

export const STOCK_END_SECTOR = 172032;          // stock card supplies sectors [1, 172032)
export const SCRIPT_BIN_OFFSET = 20340736;        // baked-in script.bin on the stock card
export const SCRIPT_BIN_MAX = 131072;
export const BOOTRES_OFFSET = 37748736;           // stock FAT16 boot-resource partition (bootlogo.bmp)
export const BASE_URL =
  "https://github.com/Eeman1113/FakeR36S-OS/releases/download/latest/goodluck_base_a23_panel2.img.gz";

// script.bin SHA-256 -> board (same fingerprint as the goodluckOS Firmware Builder)
export const BOARDS = {
  ad0b836c8b3cc6dd2b3b0d8c1817e2fdfe9ed48998a3bed758a73603f05f96e1: { name: "GA36-MB A23 Esisla", soc: "A23", status: "tested" },
  "755aae75f7df87348a1427b94532e6a1ef758e3071fb5bf52f10a7f7032318e4": { name: "GA36-MB A23 Underscore", soc: "A23", status: "untested" },
  "39a74a42c3d4f9d0599bf5f0db136a7f53bb6a072aa117eaae14e0f27872c798": { name: "GA36-MB A23 Xeno", soc: "A23", status: "untested" },
  "7a48ce4c9f9d5bd724b18eda01efea9f28a994081ca423807dd08c0c09766e6e": { name: "GA36-MB A23 Elgom", soc: "A23", status: "untested" },
  "4bdfa6b7deacf59d821063accdd5bf7789c70d240dc695fffa3e16f2e83dba6c": { name: "GA36-MB A33 Rhododendron", soc: "A33", status: "a33" },
  f6b72e9705f528c42ca5bef7ee39fddfd9ddc5369d365c17324ca6d9f8770898: { name: "GA36-MB A33 Gecko", soc: "A33", status: "a33" },
};

const hex = (buf) => Array.from(new Uint8Array(buf), (b) => b.toString(16).padStart(2, "0")).join("");

// Exact length of a sunxi script.bin (walks the section and entry tables)
export function scriptBinLength(u8) {
  const v = new DataView(u8.buffer, u8.byteOffset, u8.byteLength);
  const sections = v.getUint32(0, true);
  if (sections === 0 || sections > 0x100) throw new Error("This doesn't look like a GA36 stock card backup.");
  let end = 16 + sections * 40;
  for (let i = 0; i < sections; i++) {
    const so = 16 + i * 40;
    const count = v.getInt32(so + 32, true), off = v.getInt32(so + 36, true) * 4;
    if (count < 0 || off < 0 || off + count * 40 > u8.length) throw new Error("Damaged hardware config in this backup.");
    end = Math.max(end, off + count * 40);
    for (let j = 0; j < count; j++) {
      const eo = off + j * 40;
      const dataEnd = v.getInt32(eo + 32, true) * 4 + (v.getUint32(eo + 36, true) & 0xffff) * 4;
      if (dataEnd > u8.length) throw new Error("Damaged hardware config in this backup.");
      end = Math.max(end, dataEnd);
    }
  }
  return end;
}

// Identify the board from a stock backup (File/Blob). Only reads 128 KB.
export async function identifyBoard(stock) {
  if (stock.size < STOCK_END_SECTOR * 512) {
    throw new Error("Backup is too small. It needs at least the first 128 MB of the stock card.");
  }
  const region = new Uint8Array(await stock.slice(SCRIPT_BIN_OFFSET, SCRIPT_BIN_OFFSET + SCRIPT_BIN_MAX).arrayBuffer());
  const len = scriptBinLength(region);
  const hash = hex(await crypto.subtle.digest("SHA-256", region.slice(0, len)));
  return { hash, board: BOARDS[hash] || null };
}

// Overwrite bootlogo.bmp in place inside a FAT12/16 image region (same size file only).
export function writeBootLogo(fat, logo) {
  const v = new DataView(fat.buffer, fat.byteOffset, fat.byteLength);
  const bps = v.getUint16(11, true), spc = v.getUint8(13), reserved = v.getUint16(14, true);
  const nfats = v.getUint8(16), rootEntries = v.getUint16(17, true), spf = v.getUint16(22, true);
  const totalSectors = v.getUint16(19, true) || v.getUint32(32, true);
  if (!bps || !spc || !spf) throw new Error("boot partition is not FAT12/16");
  const rootStart = (reserved + nfats * spf) * bps;
  const dataStart = rootStart + Math.ceil((rootEntries * 32) / bps) * bps;
  const clusters = Math.floor((totalSectors * bps - dataStart) / (spc * bps));
  const fat16 = clusters >= 4085;
  for (let i = 0; i < rootEntries; i++) {
    const e = rootStart + i * 32;
    if (fat[e] === 0) break;
    if (fat[e] === 0xe5 || fat[e + 11] === 0x0f) continue;            // deleted / long-name entry
    const name = String.fromCharCode(...fat.subarray(e, e + 11));
    if (name !== "BOOTLOGOBMP") continue;
    const size = v.getUint32(e + 28, true);
    if (size !== logo.length) throw new Error(`logo must be ${size} bytes`);
    let cluster = v.getUint16(e + 26, true), written = 0;
    const csize = spc * bps;
    const next = (c) => {
      if (fat16) return v.getUint16(reserved * bps + c * 2, true);
      const o = reserved * bps + Math.floor(c * 1.5), w = v.getUint16(o, true);
      return c & 1 ? w >> 4 : w & 0xfff;
    };
    while (written < size) {
      if (cluster < 2) throw new Error("broken cluster chain");
      const n = Math.min(csize, size - written);
      fat.set(logo.subarray(written, written + n), dataStart + (cluster - 2) * csize);
      written += n;
      cluster = next(cluster);
    }
    return true;
  }
  throw new Error("bootlogo.bmp not found");
}

// Download the base image (gzip) with progress. Returns a Blob of the decompressed .img.
export async function fetchBase(url = BASE_URL, onProgress = () => {}) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Download failed (${res.status})`);
  const total = Number(res.headers.get("content-length")) || 0;
  let got = 0;
  const counted = res.body.pipeThrough(new TransformStream({
    transform(chunk, ctl) { got += chunk.length; onProgress(got, total); ctl.enqueue(chunk); },
  }));
  return new Response(counted.pipeThrough(new DecompressionStream("gzip"))).blob();
}

// Accept a user-picked base image: .img or .img.gz
export async function baseFromFile(file) {
  if (/\.gz$/i.test(file.name)) return new Response(file.stream().pipeThrough(new DecompressionStream("gzip"))).blob();
  return file;
}

// Build the flashable image as a Blob: MBR from base + stock sectors 1..172031 (with logo) + base rest.
export async function buildImage(base, stock, logo) {
  if (base.size < STOCK_END_SECTOR * 512 * 2) throw new Error("That doesn't look like a FakeR36S-OS base image.");
  const head = base.slice(0, 512);
  const stockRegion = new Uint8Array(await stock.slice(512, STOCK_END_SECTOR * 512).arrayBuffer());
  let logoOk = false;
  if (logo) {
    try {
      const off = BOOTRES_OFFSET - 512;                                   // region starts at sector 1
      writeBootLogo(stockRegion.subarray(off, off + 64 * 1024 * 1024), logo);
      logoOk = true;
    } catch (e) { console.warn("boot logo kept as stock:", e.message); }
  }
  const tail = base.slice(STOCK_END_SECTOR * 512);
  return { image: new Blob([head, stockRegion, tail], { type: "application/octet-stream" }), logoOk };
}
