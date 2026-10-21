#!/usr/bin/env python3
"""Build assets/coverage-data.js from the county coverage CSV.
Usage: python3 tools/build_coverage.py path/to/coverage_by_county.csv
Only public-safe fields are emitted (no statuses, gap notes or raw sources)."""
import csv, json, re, sys, pathlib

STATES = {"NC": ("North Carolina", "beta"), "SC": ("South Carolina", "soon"), "GA": ("Georgia", "soon"),
          "TX": ("Texas", "soon"), "IN": ("Indiana", "soon"), "MI": ("Michigan", "soon"), "IL": ("Illinois", "soon")}
FIELDS = [("owner", "o"), ("deed_book_page", "d"), ("plat_ref", "p"), ("parcel_id", "i"), ("zoning", "z")]
STATEWIDE = {"txgio": "Texas Geographic Information Office (TxGIO)", "nconemap": "NC OneMap"}

def squash(s): return re.sub(r"[^a-z]", "", s.lower())

def agency(county, src):
    if not src: return None
    low = src.lower()
    for k, v in STATEWIDE.items():
        if k in low: return v
    m = re.match(r"^((?:[A-Z][\w.']*\s)+?(?:County\s)?Appraisal District)\b", src)
    if m and squash(county) in squash(m.group(1)): return m.group(1).strip()
    m = re.match(r"^([A-Z][\w.' ]*?County)\b", src)
    if m and squash(m.group(1)) == squash(county) + "county": return f"{county} County"
    host = re.findall(r"\[([^\]]+)\]", src)
    host = (host[-1] if host else src).lower()
    if " " in host: return None
    c = squash(county)
    if re.search(rf"(^|\.){c}(county|co)", host.replace("-", "")) or re.search(rf"\bco\.{c}\.", host):
        return f"{county} County"
    return None

def main(path):
    out = {s: {"name": n, "status": st, "counties": []} for s, (n, st) in STATES.items()}
    for r in csv.DictReader(open(path, newline="")):
        s = out.get(r["state"])
        if not s: continue
        if s["status"] != "beta" and not (r["owner"] == "Y" and r["parcel_id"] == "Y"): continue
        row = {"n": r["county"]}
        row.update({k: r[f] == "Y" for f, k in FIELDS})
        a = agency(r["county"], r["source"].strip())
        if a: row["a"] = a
        s["counties"].append(row)
    for s in out.values(): s["counties"].sort(key=lambda x: x["n"])
    dest = pathlib.Path(__file__).resolve().parent.parent / "assets" / "coverage-data.js"
    dest.write_text("window.BIGCS_COVERAGE=" + json.dumps(out, separators=(",", ":")) + ";\n")
    for k, s in out.items(): print(k, len(s["counties"]), sum("a" in c for c in s["counties"]))

if __name__ == "__main__": main(sys.argv[1])
