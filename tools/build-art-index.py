#!/usr/bin/env python3
"""Build docs/art/: the list of box art names per system, so the web installer can match
games to libretro-thumbnails art without a server (raw.githubusercontent.com allows
browser downloads, the listing APIs do not). Run by .github/workflows/art-index.yml.
Set GITHUB_TOKEN to avoid the 60 requests/hour anonymous limit."""
import importlib.util, json, os, sys, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("fetch_art", os.path.join(HERE, "fetch-art.py"))
fa = importlib.util.module_from_spec(spec); spec.loader.exec_module(fa)
OUT = os.path.join(HERE, "..", "docs", "art")
TOKEN = os.environ.get("GITHUB_TOKEN")


def api(path):
    req = urllib.request.Request("https://api.github.com/" + path, headers={"Accept": "application/vnd.github+json"})
    if TOKEN:
        req.add_header("Authorization", "Bearer " + TOKEN)
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.load(r)


def repo_of(system):
    return system.replace(" ", "_")


os.makedirs(OUT, exist_ok=True)
for system in sorted({s for v in fa.SYSTEMS.values() for s in v}):
    repo = repo_of(system)
    try:
        root = api(f"repos/libretro-thumbnails/{repo}/git/trees/HEAD")
        sha = next(t["sha"] for t in root["tree"] if t["path"] == "Named_Boxarts")
        tree = api(f"repos/libretro-thumbnails/{repo}/git/trees/{sha}")
    except Exception as e:
        print(f"{system}: {e}", file=sys.stderr)
        continue
    names = sorted(t["path"][:-4] for t in tree["tree"] if t["path"].endswith(".png"))
    if tree.get("truncated"):
        print(f"{system}: listing truncated", file=sys.stderr)
    with open(os.path.join(OUT, repo + ".json"), "w") as f:
        json.dump(names, f, separators=(",", ":"), ensure_ascii=False)
    print(f"{system:48} {len(names):6} box arts")

systems = {k: [repo_of(s) for s in v] for k, v in fa.SYSTEMS.items()}
with open(os.path.join(OUT, "systems.json"), "w") as f:
    json.dump(systems, f, indent=1)
