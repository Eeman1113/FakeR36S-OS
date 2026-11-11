#!/usr/bin/env python3
"""Fetch box art for every game on a FakeR36S-OS card and add it to EmulationStation's
gamelists. Runs on your computer with the card plugged in (the handheld has no WiFi).

Art comes from the libretro thumbnail library (thumbnails.libretro.com). Games that
already have art in their gamelist.xml are left alone, and nothing else in the
gamelists is changed.

Usage:  python3 tools/fetch-art.py [/Volumes/HOME]     (default: /Volumes/HOME)
        python3 tools/fetch-art.py /media/$USER/HOME --system gba --dry-run
"""
import argparse, difflib, html, os, re, shutil, subprocess, sys, urllib.parse, urllib.request
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor

SERVER = "https://thumbnails.libretro.com"
# roms/<folder> -> libretro system name(s)
SYSTEMS = {
    "nes": ["Nintendo - Nintendo Entertainment System"],
    "famicom": ["Nintendo - Nintendo Entertainment System", "Nintendo - Family Computer Disk System"],
    "snes": ["Nintendo - Super Nintendo Entertainment System"],
    "sfc": ["Nintendo - Super Nintendo Entertainment System"],
    "n64": ["Nintendo - Nintendo 64"],
    "gb": ["Nintendo - Game Boy"],
    "gbc": ["Nintendo - Game Boy Color"],
    "gba": ["Nintendo - Game Boy Advance"],
    "virtualboy": ["Nintendo - Virtual Boy"],
    "pokemini": ["Nintendo - Pokemon Mini"],
    "megadrive": ["Sega - Mega Drive - Genesis"],
    "mastersystem": ["Sega - Master System - Mark III"],
    "gamegear": ["Sega - Game Gear"],
    "sg-1000": ["Sega - SG-1000"],
    "segacd": ["Sega - Mega-CD - Sega CD"],
    "pcengine": ["NEC - PC Engine - TurboGrafx 16"],
    "pcenginecd": ["NEC - PC Engine CD - TurboGrafx-CD"],
    "supergrafx": ["NEC - PC Engine SuperGrafx"],
    "psx": ["Sony - PlayStation"],
    "psp": ["Sony - PlayStation Portable"],
    "ngp": ["SNK - Neo Geo Pocket"],
    "ngpc": ["SNK - Neo Geo Pocket Color"],
    "wonderswan": ["Bandai - WonderSwan"],
    "wonderswancolor": ["Bandai - WonderSwan Color"],
    "atari2600": ["Atari - 2600"],
    "atari7800": ["Atari - 7800"],
    "atarilynx": ["Atari - Lynx"],
    "odyssey2": ["Magnavox - Odyssey2"],
    "intellivision": ["Mattel - Intellivision"],
    "coleco": ["Coleco - ColecoVision"],
    "msx": ["Microsoft - MSX"],
    "msx2": ["Microsoft - MSX2"],
    "zxspectrum": ["Sinclair - ZX Spectrum"],
    "amstradcpc": ["Amstrad - CPC"],
}
SKIP_EXT = {".xml", ".old", ".png", ".jpg", ".jpeg", ".txt", ".srm", ".sav", ".state", ".auto",
            ".cfg", ".nfo", ".pdf", ".mp4", ".dat", ".ips", ".bps", ".ups", ".rtc", ".bak"}
SKIP_DIRS = {"images", "downloaded_images", "media", "videos", "manuals", "icons", "snaps"}
REGION_RANK = ["usa", "world", "europe", "japan"]
ART_SIZE = 320          # px; plenty for a 640x480 screen and kind to the Mali-400's VRAM


def norm(title):
    t = re.sub(r"^\d{3,4}\s*-\s*", "", title)          # "1636 - Pokemon ..." release numbers
    t = re.sub(r"\([^)]*\)|\[[^\]]*\]", "", t)          # (USA) [!] tags
    t = t.lower().replace("&", "and")
    t = re.sub(r"^the\s+|,\s*the\b", "", t)
    return re.sub(r"[^a-z0-9]", "", t)


def regions(name):
    tags = " ".join(re.findall(r"\(([^)]*)\)", name)).lower()
    return tags


def listing(system):
    url = f"{SERVER}/{urllib.parse.quote(system)}/Named_Boxarts/"
    try:
        with urllib.request.urlopen(url, timeout=60) as r:
            page = r.read().decode("utf-8", "replace")
    except Exception as e:
        print(f"  could not list {system}: {e}", file=sys.stderr)
        return []
    names = re.findall(r'href="([^"?/][^"]*\.png)"', page)
    return [html.unescape(urllib.parse.unquote(n))[:-4] for n in names]


def build_index(names):
    idx = {}
    for n in names:
        idx.setdefault(norm(n), []).append(n)
    return idx


def pick(cands, rom_stem):
    rom_tags = regions(rom_stem) + " " + " ".join(re.findall(r"\(([A-Z])\)", rom_stem)).lower()
    want = "japan" if re.search(r"\bj\b|japan", rom_tags) else "europe" if re.search(r"\be\b|europe", rom_tags) else "usa"

    def rank(n):
        tags = regions(n)
        r = 0 if want in tags else 1 + next((i for i, k in enumerate(REGION_RANK) if k in tags), 9)
        return (r, "rev" in tags or "beta" in tags or "proto" in tags, len(n))
    return sorted(cands, key=rank)[0]


def match(rom_stem, idx, keys):
    # libretro names replace these characters with "_"
    exact = re.sub(r'[&*/:`<>?\\|"]', "_", rom_stem)
    for cands in idx.values():
        if exact in cands:
            return exact
    k = norm(rom_stem)
    if not k:
        return None
    if k in idx:
        return pick(idx[k], rom_stem)
    # "Pokemon Fire Red" vs "Pokemon - FireRed Version": prefix of a longer official title
    pre = [c for c in keys if c.startswith(k) and len(k) >= 0.6 * len(c)]
    if pre:
        best = min(pre, key=len)
        return pick(idx[best], rom_stem)
    close = difflib.get_close_matches(k, keys, n=1, cutoff=0.88)
    return pick(idx[close[0]], rom_stem) if close else None


def download(url, dest):
    tmp = dest + ".part"
    try:
        with urllib.request.urlopen(url, timeout=60) as r, open(tmp, "wb") as f:
            shutil.copyfileobj(r, f)
        if shutil.which("sips"):
            subprocess.run(["sips", "-Z", str(ART_SIZE), tmp], capture_output=True)
        else:
            try:
                from PIL import Image
                im = Image.open(tmp); im.thumbnail((ART_SIZE, ART_SIZE)); im.save(tmp, "PNG")
            except Exception:
                pass
        os.replace(tmp, dest)
        return True
    except Exception:
        if os.path.exists(tmp):
            os.remove(tmp)
        return False


def roms_in(sysdir):
    for root, dirs, files in os.walk(sysdir):
        dirs[:] = [d for d in dirs if d.lower() not in SKIP_DIRS and not d.startswith(".")]
        for f in files:
            if f.startswith(".") or os.path.splitext(f)[1].lower() in SKIP_EXT:
                continue
            yield os.path.relpath(os.path.join(root, f), sysdir)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("home", nargs="?", default="/Volumes/HOME")
    ap.add_argument("--system", action="append", help="only this roms folder (repeatable)")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    roms = os.path.join(a.home, "roms")
    if not os.path.isdir(roms):
        sys.exit(f"{roms} not found. Plug in the card (HOME partition) or pass its path.")

    total = 0
    for folder in sorted(os.listdir(roms)):
        if folder not in SYSTEMS or (a.system and folder not in a.system):
            continue
        sysdir = os.path.join(roms, folder)
        files = sorted(roms_in(sysdir))
        if not files:
            continue
        gl_path = os.path.join(sysdir, "gamelist.xml")
        try:
            tree = ET.parse(gl_path); root = tree.getroot()
        except Exception:
            root = ET.Element("gameList"); tree = ET.ElementTree(root)
        games = {}
        for g in root.findall("game"):
            p = (g.findtext("path") or "").strip()
            games[os.path.normpath(p[2:] if p.startswith("./") else p)] = g

        todo = []
        for rel in files:
            g = games.get(os.path.normpath(rel))
            img = g.findtext("image") if g is not None else None
            if img and os.path.exists(os.path.join(sysdir, img[2:] if img.startswith("./") else img)):
                continue
            todo.append(rel)
        if not todo:
            print(f"{folder:16} all {len(files)} games already have art")
            continue

        names = []
        for s in SYSTEMS[folder]:
            names += [(s, n) for n in listing(s)]
        idx = build_index([n for _, n in names])
        owner = {n: s for s, n in names}
        keys = list(idx)

        jobs, found = [], 0
        os.makedirs(os.path.join(sysdir, "images"), exist_ok=True) if not a.dry_run else None
        for rel in todo:
            stem = os.path.splitext(os.path.basename(rel))[0]
            hit = match(stem, idx, keys)
            if not hit:
                continue
            found += 1
            img_rel = os.path.join("images", os.path.splitext(rel)[0].replace(os.sep, "_") + ".png")
            if a.dry_run:
                print(f"  {rel}  ->  {hit}")
                continue
            url = f"{SERVER}/{urllib.parse.quote(owner[hit])}/Named_Boxarts/{urllib.parse.quote(hit)}.png"
            jobs.append((rel, img_rel, url, hit))

        ok = 0
        if jobs:
            with ThreadPoolExecutor(8) as ex:
                results = list(ex.map(lambda j: download(j[2], os.path.join(sysdir, j[1])), jobs))
            for (rel, img_rel, _, hit), good in zip(jobs, results):
                if not good:
                    continue
                ok += 1
                g = games.get(os.path.normpath(rel))
                if g is None:
                    g = ET.SubElement(root, "game")
                    ET.SubElement(g, "path").text = "./" + rel.replace(os.sep, "/")
                    ET.SubElement(g, "name").text = re.sub(r"\s*\(.*$", "", hit).strip()
                im = g.find("image")
                if im is None:
                    im = ET.SubElement(g, "image")
                im.text = "./" + img_rel.replace(os.sep, "/")
            ET.indent(tree, "\t")
            tree.write(gl_path, encoding="utf-8", xml_declaration=True)
        total += ok
        print(f"{folder:16} {len(todo):5} without art, {found} matched, {ok if not a.dry_run else 0} downloaded")
    print(f"done: {total} box art images added. Eject the card safely before unplugging it.")


if __name__ == "__main__":
    main()
