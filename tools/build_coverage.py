#!/usr/bin/env python3
"""Build coverage.html from the county coverage CSV.
Usage: python3 tools/build_coverage.py path/to/coverage_by_county.csv
Columns: state, county, owner, PIN, deed, plat, roads, control (yes/partial/no),
data source, data year, older_copy. Only public-safe fields are published
(no hostnames or internal review statuses).
state_control and ngs_control are yes/no.
Older-copy label comes only from the older_copy flag. Tax years show as "YYYY tax year"."""
import csv, html, sys, pathlib, datetime, re

NAMES = {"AL":"Alabama","AR":"Arkansas","DE":"Delaware","FL":"Florida","GA":"Georgia","IA":"Iowa","IL":"Illinois",
 "IN":"Indiana","KS":"Kansas","KY":"Kentucky","LA":"Louisiana","MD":"Maryland","MI":"Michigan","MN":"Minnesota",
 "MO":"Missouri","MS":"Mississippi","NC":"North Carolina","NE":"Nebraska","NJ":"New Jersey","NY":"New York",
 "OH":"Ohio","OK":"Oklahoma","PA":"Pennsylvania","SC":"South Carolina","TN":"Tennessee","TX":"Texas",
 "VA":"Virginia","WI":"Wisconsin","WV":"West Virginia"}
AVAILABLE = {"NC"}          # everything else: Coming soon (matches site copy)
ORDER = ["NC", "SC"]        # then alphabetical by state name
# Public names for known statewide sources (hostname -> agency).
AGENCY = {("NE", "statewide copy"): "University of Nebraska", ("OH", "gis.ohiodnr.gov"): "Ohio DNR"}
COLS = [("owner","Owner"),("PIN","PIN"),("deed","Deed"),("plat","Plat"),("roads","Roads"),("state_control","State Control"),("ngs_control","NGS Control")]
NOW = datetime.date.today().year

def cell(v):
    v = (v or "").strip().lower()
    if v == "yes": return '<td class="y" title="Yes">&#10003;</td>'
    if v == "partial": return '<td class="p" title="Partial: some parcels or part of the county">Partial</td>'
    if v == "no": return '<td class="n" title="No">&ndash;</td>'
    return '<td class="u" title="Not reported">?</td>'

def agency(st, src):
    kind = src.split(" [")[0].strip()
    host = (re.findall(r"\[([^\]]+)\]", src) or [""])[0]
    return AGENCY.get((st, host)) or AGENCY.get((st, kind))

def main(path):
    rows = list(csv.DictReader(open(path, newline="", encoding="utf-8-sig")))
    by = {}
    for r in rows: by.setdefault(r["state"].strip(), []).append(r)
    codes = [c for c in ORDER if c in by] + sorted((c for c in by if c not in ORDER), key=lambda c: NAMES.get(c, c))
    parts = []
    for code in codes:
        rs = sorted(by[code], key=lambda r: r["county"])
        label = "Available" if code in AVAILABLE else "Coming soon"
        body = []
        for r in rs:
            yr = (r.get("data year") or "").strip()
            if not yr.isdigit(): yr = ""
            if yr and (r.get("year_type") or "").strip().lower() == "tax year": yr += " tax year"
            m = re.search(r"\((\d{4})\)", r.get("older_copy") or "")
            old = m.group(1) if m else ""
            tag = ""
            if old:
                a = agency(code, r.get("data source") or "")
                tag = f'<span class="old">Older copy ({old}){", " + html.escape(a) if a else ""}</span>'
            body.append(f'<tr data-c="{html.escape(r["county"].lower())}"><th scope="row">{html.escape(r["county"])}{tag}</th>'
                        + "".join(cell(r.get(k)) for k, _ in COLS) + "</tr>")
        cls = label.lower().replace(" ", "-")
        parts.append(f'<details class="cov-state" id="st-{code.lower()}"><summary>'
                     f'<span>{NAMES.get(code, code)}</span> <span class="badge {cls}">{label}</span> <span class="cnt">{len(rs)} counties</span></summary>'
                     '<div class="tbl"><table><thead><tr><th>County</th>' + "".join(f"<th>{h}</th>" for _, h in COLS)
                     + "</tr></thead><tbody>" + "".join(body) + "</tbody></table></div></details>")
        print(code, len(rs), "older:", sum('class="old"' in b for b in body))
    root = pathlib.Path(__file__).resolve().parent.parent
    tpl = (root / "tools" / "coverage_template.html").read_text()
    (root / "coverage.html").write_text(tpl.replace("<!--STATES-->", "\n".join(parts)))

if __name__ == "__main__": main(sys.argv[1])
