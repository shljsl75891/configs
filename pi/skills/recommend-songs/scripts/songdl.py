#!/usr/bin/env python3
"""Find and download songs in 320kbps: JioSaavn (.m4a, tagged) first, pagalnew / mr-jatt (.mp3) as fallback.

Usage:
  songdl.py artist NAME [-n 50]        top songs of an artist  -> TSV: title, singers, album, year, language
  songdl.py resolve LIST > songs.tsv   LIST lines: "Title|Artist" or "Title" (# comments ignored)
  songdl.py download songs.tsv OUTDIR  downloads ok/weak rows; skips songs already in OUTDIR
  songdl.py check songs.tsv OUTDIR     flags downloaded files: missing, corrupt, short -> TSV: id, file, title, artists, flags

songs.tsv columns: status  query  source  id  title  artists  album  year  image  media
  status: ok | weak | miss      source: saavn | pagalnew | mrjatt
Needs: python3, curl, ffmpeg, openssl.
"""
import difflib
import html
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

UA = "Mozilla/5.0 (X11; Linux x86_64) Chrome/124 Safari/537.36"
SAAVN_API = "https://www.jiosaavn.com/api.php?_format=json&_marker=0&api_version=4&ctx=web6dot0&"
DES_KEY_HEX = "3338333436353931"  # ASCII "38346591": JioSaavn media URL key
SKIP = re.compile(r"remix|lofi|lo-fi|unplugged|reprise|mashup|cover|slowed|reverb|instrumental|karaoke|female|acoustic|live|"
                  r"stripped|8d|jhankar|mix\b|re-?imagined|recreated|version|tribute|\sx\s", re.I)
COMPILATION = re.compile(r"songs|hits|vibes|repeat|playlist|best of|collection|top \d+|lofi", re.I)
CACHE = os.path.expanduser("~/.cache/recommend-songs")
MRJATT_SITEMAPS = [f"https://www.mr-jatt.im/songs-sitemap{i}.xml" for i in (1, 2, 3)]
IDS_FILE = ".ids"
MIN_SECONDS = 60


# ---------- http ----------

def get_text(url, referer=None):
    headers = {"User-Agent": UA, **({"Referer": referer} if referer else {})}
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def saavn(params):
    return json.loads(get_text(SAAVN_API + urllib.parse.urlencode(params)))


# ---------- text helpers ----------

def words(text):
    return set(re.findall(r"[a-z0-9]+", text.lower()))


def loose(text):
    """Loose spelling for site slugs: drop digits, collapse repeated letters, unify vowels (raataan ~ ratan, mereya2 ~ mereya)."""
    out = set()
    for w in re.findall(r"[a-z0-9]+", text.lower()):
        w = re.sub(r"(.)\1+", r"\1", re.sub(r"\d+", "", w)).replace("y", "i")
        if w:
            out.add(w)
    return out


def clean(text):
    return re.sub(r"\s*[\[(]From .*$", "", html.unescape(text)).strip()


def safe(name):
    return re.sub(r'[\\/:*?"<>|]', "", name).strip()


def split_query(line):
    title, artist = (line.split("|") + [""])[:2]
    return title.strip(), artist.strip()


# ---------- JioSaavn ----------

def singers_only(info):
    """JioSaavn credits are noisy: composers have the role 'singer' too, and many songs have no 'singer' role.
    Use the 'singer' role. If it is empty, use primary artists. Always remove composers and lyricists."""
    amap = info.get("artistMap", {})
    credits = amap.get("artists", [])
    writers = {a["name"] for a in credits if a.get("role") in ("music", "lyricist")}
    singers = [a["name"] for a in credits if a.get("role") == "singer"] or [a["name"] for a in amap.get("primary_artists", [])]
    return list(dict.fromkeys(n for n in singers if n not in writers)) or list(dict.fromkeys(singers))


def score(s, title, artist):
    """Rank one search result. Some JioSaavn songs have no singer credit, so 'no singer' is not a reject."""
    info = s.get("more_info", {})
    if SKIP.search(s["title"]) or info.get("320kbps") != "true":
        return None
    name = clean(s["title"])
    want, got = words(title), words(name)
    if not artist:
        if not got <= want:
            return None
        rest = want - got  # extra query words, e.g. a movie name
        hint = words(clean(info.get("album", ""))) | words(" ".join(singers_only(info)))
        return 4 if (rest & hint or not rest) else 2
    if want == got:
        pts = 3
    elif want <= got:
        pts = 2
    elif difflib.SequenceMatcher(None, title.lower(), name.lower()).ratio() >= 0.85:
        pts = 1
    else:
        return None
    amap = info.get("artistMap", {})
    credits = " ".join(a["name"] for a in amap.get("artists", []) + amap.get("primary_artists", [])) + " " + s.get("subtitle", "")
    singers = singers_only(info)
    if artist.lower() in credits.lower():
        pts += 3
    elif singers:
        pts -= 2  # another singer: likely a cover
    elif words(clean(info.get("album", ""))) != got:
        pts += 1  # no credits and a real album: likely the original with credits removed
    if COMPILATION.search(info.get("album", "")):
        pts -= 1
    return pts


def main_artist(singers, hint):
    """Name files after the singer the user asked for, else the first credited singer."""
    for s in singers:
        if hint and hint.lower() in s.lower():
            return s
    return singers[0] if singers else hint


def saavn_resolve(title, artist):
    results = saavn({"__call": "search.getResults", "q": f"{title} {artist}".strip(), "p": 1, "n": 20}).get("results", [])
    scored = [(score(s, title, artist), i, s) for i, s in enumerate(results)]
    scored = [t for t in scored if t[0] is not None and t[0] >= 2]
    if not scored:
        return None
    pts, _, s = max(scored, key=lambda t: (t[0], -t[1]))
    info = s["more_info"]
    singers = singers_only(info)
    artists = ", ".join([main_artist(singers, artist)] + [x for x in singers if x != main_artist(singers, artist)]) or artist
    return ["ok" if pts >= 4 else "weak", "saavn", s["id"], clean(s["title"]), artists, clean(info.get("album", "")),
            s.get("year", ""), s.get("image", "").replace("150x150", "500x500"), info["encrypted_media_url"]]


def saavn_media_url(enc):
    plain = subprocess.run(["openssl", "enc", "-d", "-des-ecb", "-K", DES_KEY_HEX, "-a", "-A", "-provider", "legacy", "-provider", "default"],
                           input=enc.encode(), capture_output=True, check=True).stdout.decode()
    return re.sub(r"_\d+\.mp4", "_320.mp4", plain.strip())


def artist_top(name, n):
    hit = saavn({"__call": "search.getArtistResults", "q": name, "p": 1, "n": 1}).get("results", [])
    if not hit:
        sys.exit(f"artist not found: {name}")
    token = hit[0]["perma_url"].rstrip("/").rsplit("/", 1)[-1]
    page = saavn({"__call": "webapi.get", "token": token, "type": "artist", "n_song": n, "n_album": 0, "p": 0,
                  "sort_order": "desc", "category": "popularity"})
    for s in page.get("topSongs") or []:
        info = s.get("more_info", {})
        if SKIP.search(s["title"]):
            continue
        print("\t".join([clean(s["title"]), ", ".join(singers_only(info)), clean(info.get("album", "")), s.get("year", ""), s.get("language", "")]))


# ---------- mp3 fallback sites ----------

def pagalnew_resolve(title, artist):
    page = get_text("https://pagalnew.com/search.php?find=" + urllib.parse.quote_plus(title))
    want = loose(title)
    for slug in list(dict.fromkeys(re.findall(r'href="(/songs/[^"]+\.html)"', page)))[:30]:
        if SKIP.search(slug) or not want <= loose(slug):
            continue
        url = "https://pagalnew.com" + slug
        singers = re.search(r"Singer\(s\):\s*</b>([^<]*)", get_text(url))
        if singers and (not artist or artist.lower() in singers.group(1).lower()):
            names = [n.strip() for n in singers.group(1).split(",") if n.strip()]
            return ["ok", "pagalnew", url, title, main_artist(names, artist), "", "", "", url]
    return None


def mrjatt_pages():
    path = os.path.join(CACHE, "mrjatt-songs.txt")
    if not os.path.exists(path) or time.time() - os.path.getmtime(path) > 7 * 86400:
        os.makedirs(CACHE, exist_ok=True)
        urls = [u for sm in MRJATT_SITEMAPS for u in re.findall(r"<loc>([^<]+)</loc>", get_text(sm))]
        with open(path, "w") as f:
            f.write("\n".join(urls))
    return open(path).read().split()


def mrjatt_resolve(title, artist, pages):
    want = loose(title) | loose(artist)
    hits = [p for p in pages if want <= loose(p.rsplit("/", 1)[-1]) and not SKIP.search(p)]
    if not hits:
        return None
    url = hits[-1]  # sitemap lists newest first; the oldest id is usually the original upload
    return ["ok", "mrjatt", url, title, artist, "", "", "", url]


def mp3_link(page):
    body = get_text(page)
    if "pagalnew.com" in page:
        m = re.search(r"https://pagalnew\.com/320-download/\d+", body)
        return m and m.group(0)
    m = re.search(r"""https?://cdnsongs\.com/(?:dren/)?music/[^"'<>]*/320/[^"'<>/]+\.mp3""", body)
    return m and m.group(0).replace("/dren/", "/")  # the /dren/ form returns 404


# ---------- commands ----------

def resolve_line(line, pages):
    title, artist = split_query(line)
    best = None
    try:
        best = saavn_resolve(title, artist)
        if not best or best[0] != "ok":
            best = pagalnew_resolve(title, artist) or mrjatt_resolve(title, artist, pages) or best
    except Exception as e:
        print(f"warn {line}: {e}", file=sys.stderr)
        best = best or mrjatt_resolve(title, artist, pages)
    return "\t".join([best[0], line] + best[1:]) if best else f"miss\t{line}"


def resolve(paths):
    lines = [l.strip() for p in paths for l in open(p) if l.strip() and not l.lstrip().startswith("#")]
    lines = list({l.lower(): l for l in lines}.values())
    pages = mrjatt_pages()
    with ThreadPoolExecutor(4) as pool:
        for row in pool.map(lambda l: resolve_line(l, pages), lines):
            print(row, flush=True)


def fetch(url, out, referer=None):
    cmd = ["curl", "-fsSL", "--retry", "3", "--connect-timeout", "15", "-A", UA, "-o", out, url]
    subprocess.run(cmd + (["-e", referer] if referer else []), check=True)


def out_path(row, outdir):
    _, _, source, _, title, artists = row[:6]
    ext = ".m4a" if source == "saavn" else ".mp3"
    return os.path.join(outdir, safe(f"{title} - {artists.split(',')[0].strip()}") + ext)


def download_row(row, outdir):
    _, query, source, sid, title, artists, album, year, image, media = row
    out = out_path(row, outdir)
    if os.path.exists(out):
        return "skip"
    part = out + ".part" + ext
    if source == "saavn":
        with tempfile.TemporaryDirectory() as tmp:
            audio, cover = os.path.join(tmp, "a.mp4"), os.path.join(tmp, "c.jpg")
            fetch(saavn_media_url(media), audio)
            fetch(image, cover)
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", audio, "-i", cover, "-map", "0:a", "-map", "1", "-c", "copy",
                            "-disposition:v", "attached_pic", "-metadata", f"title={title}", "-metadata", f"artist={artists}",
                            "-metadata", f"album={album}", "-metadata", f"date={year}", part], check=True)
    else:
        link = mp3_link(media)
        if not link:
            raise RuntimeError(f"no 320kbps link on {media}")
        fetch(link, part, referer=media)
    os.rename(part, out)
    return "ok"


def download(tsv, outdir):
    os.makedirs(outdir, exist_ok=True)
    ids_path = os.path.join(outdir, IDS_FILE)
    have = set(open(ids_path).read().split()) if os.path.exists(ids_path) else set()
    ok = skip = fail = 0
    with open(ids_path, "a") as ids:
        for line in open(tsv):
            row = line.rstrip("\n").split("\t")
            if len(row) < 10 or row[0] not in ("ok", "weak"):
                continue
            if row[3] in have:
                skip += 1
                continue
            try:
                status = download_row(row, outdir)
                print(f"{status}\t{row[4]} - {row[5]}", flush=True)
                ok += status == "ok"
                skip += status == "skip"
                have.add(row[3])
                ids.write(row[3] + "\n")
                ids.flush()
            except Exception as e:
                print(f"!! {row[1]}: {e}", file=sys.stderr, flush=True)
                fail += 1
            time.sleep(0.5)
    print(f"done: {ok} ok, {skip} skipped, {fail} failed", flush=True)


def duration(path):
    probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                           capture_output=True, text=True)
    try:
        return float(probe.stdout)
    except ValueError:
        return None


def check(tsv, outdir):
    for line in open(tsv):
        row = line.rstrip("\n").split("\t")
        if len(row) < 10 or row[0] not in ("ok", "weak"):
            continue
        out = out_path(row, outdir)
        length = duration(out) if os.path.exists(out) else None
        flags = ["missing"] if not os.path.exists(out) else ["corrupt"] if length is None else ["short"] if length < MIN_SECONDS else []
        if flags:
            print("\t".join([row[3], out, row[4], row[5], ",".join(flags)]))


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "artist":
        n = int(args[args.index("-n") + 1]) if "-n" in args else 50
        artist_top(args[0], n)
    elif cmd == "resolve":
        resolve(args)
    elif cmd == "download" and len(args) == 2:
        download(*args)
    elif cmd == "check" and len(args) == 2:
        check(*args)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
