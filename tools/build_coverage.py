#!/usr/bin/env python3
"""Build coverage.html from the county coverage CSV.
Usage: python3 tools/build_coverage.py path/to/coverage_by_county.csv
Optional CSV columns used when present: roads, control, year (or data_year), source_name.
Only public-safe fields are published (no internal status, gap notes or raw URLs)."""
import csv, html, sys, pathlib, datetime

# Keep labels consistent with the rest of the site (NC available, SC coming soon).
STATES = [("NC", "North Carolina", "Available"), ("SC", "South Carolina", "Coming soon"),
          ("GA", "Georgia", "Coming soon"), ("TX", "Texas", "Coming soon"),
          ("IN", "Indiana", "Coming soon"), ("MI", "Michigan", "Coming soon"),
          ("IL", "Illinois", "Coming soon"), ("NE", "Nebraska", "Coming soon")]
COLS = [("owner", "Owner"), ("parcel_id", "PIN"), ("deed_book_page", "Deed"),
        ("plat_ref", "Plat"), ("roads", "Roads"), ("control", "Control")]
THIS_YEAR = datetime.date.today().year

def cell(r, k):
    v = (r.get(k) or "").strip().upper()
    if v == "Y": return '<td class="y" title="Available">&#10003;</td>'
    if v == "N": return '<td class="n" title="Not available">&ndash;</td>'
    return '<td class="u" title="Not yet reported">?</td>'

def main(path):
    rows = list(csv.DictReader(open(path, newline="", encoding="utf-8-sig")))
    by = {}
    for r in rows: by.setdefault(r["state"].strip(), []).append(r)
    known = {s for s, _, _ in STATES}
    states = STATES + [(s, s, "Coming soon") for s in sorted(by) if s not in known]
    parts = []
    for code, name, label in states:
        rs = sorted(by.get(code, []), key=lambda r: r["county"])
        if not rs: continue
        body = []
        for r in rs:
            yr = (r.get("year") or r.get("data_year") or "").strip()
            note = ""
            if yr and yr.isdigit() and int(yr) < THIS_YEAR:
                src = (r.get("source_name") or "").strip()
                note = f' <span class="yr">{html.escape(yr)} copy{(" ("+html.escape(src)+")") if src else ""}</span>'
            body.append(f'<tr data-c="{html.escape(r["county"].lower())}"><th scope="row">{html.escape(r["county"])}{note}</th>'
                        + "".join(cell(r, k) for k, _ in COLS) + "</tr>")
        cls = label.lower().replace(" ", "-")
        parts.append(f'<details class="cov-state" {"open" if label=="Available" else ""}><summary><span>{name}</span> '
                     f'<span class="badge {cls}">{label}</span> <span class="cnt">{len(rs)} counties</span></summary>'
                     f'<div class="tbl"><table><thead><tr><th>County</th>' + "".join(f"<th>{h}</th>" for _, h in COLS)
                     + "</tr></thead><tbody>" + "".join(body) + "</tbody></table></div></details>")
    root = pathlib.Path(__file__).resolve().parent.parent
    tpl = (root / "tools" / "coverage_template.html").read_text()
    (root / "coverage.html").write_text(tpl.replace("<!--STATES-->", "\n".join(parts)))
    for code, *_ in states: print(code, len(by.get(code, [])))

if __name__ == "__main__": main(sys.argv[1])
