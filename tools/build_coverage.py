#!/usr/bin/env python3
"""Build coverage.html from the county coverage CSV.

Usage: python3 tools/build_coverage.py path/to/coverage_by_county.csv

Columns used: state, county, owner, PIN, deed, plat, roads, buildings,
state_control, ngs_control, state_control_source, ngs_source,
data source, parcel_source_name, data year, year_type, older_copy.

Check marks come only from the CSV (yes / partial / no). Parcel, state
control, and NGS sources are published as names. Hostnames and URLs are
not published.

States in AVAILABLE are badged Available. Any other state in the CSV is
badged Coming soon. Sections already on coverage.html for states that are
not in the CSV (Coming soon lists) are kept. Counties already listed there
but absent from the CSV stay on the page, except four Virginia town rows
that are not Census county-equivalents.

Where a county already has a source name on the page, that name is kept.
"""
import csv, html, sys, pathlib, re, collections

NAMES = {
    "AL": "Alabama", "AR": "Arkansas", "AZ": "Arizona", "CO": "Colorado",
    "CT": "Connecticut", "DC": "District of Columbia", "DE": "Delaware",
    "FL": "Florida", "GA": "Georgia", "HI": "Hawaii", "IA": "Iowa",
    "IL": "Illinois", "IN": "Indiana", "KS": "Kansas", "KY": "Kentucky",
    "LA": "Louisiana", "MA": "Massachusetts", "MD": "Maryland",
    "MI": "Michigan", "MN": "Minnesota", "MO": "Missouri", "MS": "Mississippi",
    "MT": "Montana", "NC": "North Carolina", "ND": "North Dakota",
    "NE": "Nebraska", "NJ": "New Jersey", "NM": "New Mexico", "NV": "Nevada",
    "NY": "New York", "OH": "Ohio", "OK": "Oklahoma", "OR": "Oregon",
    "PA": "Pennsylvania", "SC": "South Carolina", "SD": "South Dakota",
    "TN": "Tennessee", "TX": "Texas", "UT": "Utah", "VA": "Virginia",
    "VT": "Vermont", "WA": "Washington", "WI": "Wisconsin", "WV": "West Virginia",
}
# Census county or county-equivalent counts. CT is 9 planning regions.
CENSUS = {
    "AR": 75, "AZ": 15, "CO": 64, "CT": 9, "DC": 1, "DE": 3, "FL": 67,
    "HI": 5, "IL": 102, "MA": 14, "MD": 24, "MN": 87, "MO": 115, "MS": 82,
    "MT": 56, "NC": 100, "ND": 53, "NJ": 21, "NM": 33, "NV": 17, "NY": 62,
    "OH": 88, "OR": 36, "PA": 67, "SC": 46, "SD": 66, "TN": 95, "TX": 254,
    "UT": 29, "VA": 133, "VT": 14, "WA": 39, "WI": 72, "WV": 55,
}
AVAILABLE = {
    "AR", "AZ", "CO", "CT", "DC", "DE", "FL", "HI", "IL", "MA", "MD", "MN",
    "MO", "MS", "MT", "NC", "ND", "NJ", "NM", "NV", "NY", "OH", "OR", "PA",
    "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV",
}
PREFIX = ["NC", "SC", "GA", "VA", "TN"]
# Towns on the old Virginia table that are not Census county-equivalents.
VA_DROP = {"Bedford Town", "Colonial Beach Town", "Culpeper Town", "Farmville Town"}
AGENCY = {("NE", "statewide copy"): "University of Nebraska", ("OH", "gis.ohiodnr.gov"): "Ohio DNR"}
COLS = [("owner", "Owner"), ("PIN", "PIN"), ("deed", "Deed"), ("plat", "Plat"),
        ("roads", "Roads"), ("buildings", "Buildings"),
        ("state_control", "State Control"), ("ngs_control", "NGS Control")]
COUNT_LINE = re.compile(
    r"^(?:All \d+ counties are ready\.|\d+ county is ready\.|"
    r"\d+ of \d+ counties are ready\.|\d+ counties are ready\.)$"
)


def cell(v):
    v = (v or "").strip().lower()
    if v == "yes":
        return '<td class="y"></td>'
    if v == "partial":
        return '<td class="p">Partial</td>'
    if v == "no":
        return '<td class="n"></td>'
    return '<td class="u"></td>'


def agency(st, src):
    kind = src.split(" [")[0].strip()
    host = (re.findall(r"\[([^\]]+)\]", src) or [""])[0]
    return AGENCY.get((st, host)) or AGENCY.get((st, kind))


def norm(name):
    n = html.unescape(name or "").lower().replace("'", "'").replace("'", "'")
    n = re.sub(r"\s+county$", "", n.strip())
    return re.sub(r"[^a-z0-9]+", "", n)


def strip_urls(text):
    s = text or ""
    s = re.sub(r"https?://\S+", "", s)
    s = re.sub(r"\bwww\.\S+", "", s)
    s = re.sub(r"\[[^\]]*\]", "", s)
    s = re.sub(r"\(\s*\)", "", s)
    return re.sub(r"\s+", " ", s).strip(" ;,-")


def public_parcel_source(raw):
    s = re.sub(r"(?i)^county gis:\s*", "", (raw or "").strip())
    s = strip_urls(s)
    if re.search(r"pending lookup", s, re.I):
        m = re.search(r"(?i)data via\s+(.+)", s)
        s = strip_urls(m.group(1) if m else "")
        s = re.sub(r"(?i)\s+statewide parcels\b.*", "", s).strip()
    if "|" in s:
        s = s.split("|")[0]
    s = re.sub(r"\s+", " ", s).strip(" ;,-.")
    if not s or re.search(r"pending lookup|https?://|\bwww\.", s, re.I):
        return "None found"
    return s


def source_names(rs, col):
    vals = []
    for r in rs:
        v = strip_urls(r.get(col) or "")
        if v and v not in vals and not re.search(r"https?://|\bwww\.", v, re.I):
            vals.append(v)
    return vals


def control_line(rs):
    sc = source_names(rs, "state_control_source")
    ng = source_names(rs, "ngs_source")
    sc_txt = "; ".join(html.escape(v) for v in sc) if sc else "None"
    ng_txt = "; ".join(html.escape(v) for v in ng) if ng else "None"
    return f"State control: {sc_txt}. NGS: {ng_txt}."


def count_sentence(ready, total):
    if ready == total:
        if total == 1:
            return "1 county is ready."
        return f"All {total} counties are ready."
    return f"{ready} of {total} counties are ready."


def badge_count(ready, total):
    if ready == total:
        return "1 county" if total == 1 else f"{total} counties"
    noun = "county" if ready == 1 else "counties"
    return f"{ready} {noun} ready"


def load_previous(path):
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    out = {}
    for m in re.finditer(r'(<details class="cov-state" id="st-([a-z]+)">.*?</details>)', text, re.S):
        out[m.group(2).upper()] = m.group(1)
    return out


def parse_section(block):
    head = re.search(r"<summary>.*?</summary>(.*)<div class=\"tbl\">", block, re.S)
    body = head.group(1) if head else ""
    ctls = re.findall(r"<p class=\"ctl\">(.*?)</p>", body, re.S)
    rows = []
    for raw in re.findall(r"<tr data-c=\"[^\"]*\">.*?</tr>", block, re.S):
        th = re.search(r"<th scope=\"row\">(.*?)</th>", raw, re.S)
        inner = th.group(1) if th else ""
        not_ready = "Not ready yet" in inner
        note = "".join(re.findall(r'<span class="yr">.*?</span>', inner, re.S))
        name_html = re.sub(r"<span class=\"(?:old|yr)\">.*?</span>", "", inner, flags=re.S)
        name = html.unescape(re.sub(r"<[^>]+>", "", name_html)).strip()
        src_m = re.search(r"<td class=\"src\">(.*?)</td>", raw, re.S)
        source = html.unescape(re.sub(r"<[^>]+>", "", src_m.group(1))).strip() if src_m else ""
        rows.append({"name": name, "not_ready": not_ready, "source": source, "note": note, "raw": raw})
    return {"ctls": ctls, "rows": rows}


def keep_control_line(existing, rs):
    if not existing:
        return control_line(rs)
    plain = html.unescape(re.sub(r"<[^>]+>", "", existing))
    needed = source_names(rs, "state_control_source") + source_names(rs, "ngs_source")
    if all(name in plain for name in needed):
        return existing
    return control_line(rs)


def row_html(code, display, r, source, note=""):
    m = re.search(r"\((\d{4})\)", r.get("older_copy") or "")
    old = m.group(1) if m else ""
    tag = ""
    if old:
        a = agency(code, r.get("data source") or "")
        tag = f'<span class="old">Older copy ({old}){", " + html.escape(a) if a else ""}</span>'
    src = source or "None found"
    return (f'<tr data-c="{html.escape(display.lower())}"><th scope="row">{html.escape(display)}{note}{tag}</th>'
            + "".join(cell(r.get(k)) for k, _ in COLS)
            + f'<td class="src">{html.escape(src)}</td></tr>')


def section_html(code, csv_rows, prev):
    ready = len(csv_rows)
    total = CENSUS.get(code, ready)
    label = "Available" if code in AVAILABLE else "Coming soon"
    parsed = parse_section(prev) if prev else {"ctls": [], "rows": []}
    by_norm = {}
    for row in parsed["rows"]:
        key = norm(row["name"])
        if key in by_norm:
            raise SystemExit(f"{code}: two existing rows normalize to {row['name']!r}")
        by_norm[key] = row
    used = set()
    body = []
    for r in csv_rows:
        key = norm(r["county"])
        prev_row = by_norm.get(key)
        if prev_row:
            used.add(key)
            display = prev_row["name"]
            note = "" if prev_row["not_ready"] else prev_row.get("note") or ""
            src = prev_row["source"]
            if prev_row["not_ready"] or not src or src.lower() == "not ready yet" or re.search(r"https?://|\bwww\.", src, re.I):
                src = public_parcel_source(r.get("parcel_source_name") or "")
        else:
            display = r["county"].strip()
            note = ""
            src = public_parcel_source(r.get("parcel_source_name") or "")
        body.append((display, row_html(code, display, r, src, note)))
    kept = 0
    for row in parsed["rows"]:
        if norm(row["name"]) in used:
            continue
        if code == "VA" and row["name"] in VA_DROP:
            continue
        if not row["not_ready"]:
            raise SystemExit(f"{code}: existing ready county {row['name']!r} is not in the CSV")
        body.append((row["name"], row["raw"]))
        kept += 1
    missing = [r["county"] for r in csv_rows if norm(r["county"]) not in by_norm and prev]
    body.sort(key=lambda item: item[0].lower())
    ctl1 = keep_control_line(parsed["ctls"][0] if parsed["ctls"] else "", csv_rows)
    if len(parsed["ctls"]) > 1 and not COUNT_LINE.match(html.unescape(re.sub(r"<[^>]+>", "", parsed["ctls"][1])).strip()):
        ctl2 = parsed["ctls"][1]
    else:
        ctl2 = html.escape(count_sentence(ready, total))
    cls = label.lower().replace(" ", "-")
    cnt = badge_count(ready, total)
    table = ('<div class="tbl"><table><thead><tr><th>County</th>'
             + "".join(f"<th>{h}</th>" for _, h in COLS)
             + "<th>Source</th></tr></thead><tbody>"
             + "".join(html_row for _, html_row in body)
             + "</tbody></table></div>")
    block = (f'<details class="cov-state" id="st-{code.lower()}"><summary>'
             f'<span>{html.escape(NAMES.get(code, code))}</span> '
             f'<span class="badge {cls}">{label}</span> '
             f'<span class="cnt">{html.escape(cnt)}</span></summary>'
             f'<p class="ctl">{ctl1}</p><p class="ctl">{ctl2}</p>{table}</details>')
    return block, ready, len(body), kept, missing


def main(path):
    rows = list(csv.DictReader(open(path, newline="", encoding="utf-8-sig")))
    by = collections.OrderedDict()
    for r in rows:
        b = (r.get("buildings") or "").strip().lower()
        if not b:
            raise SystemExit(f'{r.get("state")}/{r.get("county")}: missing buildings field; will not invent a value')
        r["buildings"] = b
        code = r["state"].strip()
        by.setdefault(code, []).append(r)
    root = pathlib.Path(__file__).resolve().parent.parent
    prev = load_previous(root / "coverage.html")
    coming = [c for c in prev if c not in by]
    ordered = [c for c in PREFIX if c in by or c in coming]
    rest = [c for c in list(by) + coming if c not in ordered]
    rest = sorted(set(rest), key=lambda c: NAMES.get(c, c))
    parts = []
    available_n = 0
    for code in ordered + rest:
        if code not in by:
            parts.append(prev[code])
            print(f"{code} kept (not in CSV)")
            continue
        rs = sorted(by[code], key=lambda r: r["county"].lower())
        block, ready, nrows, kept, missing = section_html(code, rs, prev.get(code))
        parts.append(block)
        if code in AVAILABLE:
            available_n += 1
        print(f"{code} ready {ready} rows {nrows} kept_not_ready {kept} census {CENSUS.get(code, '-')} added {len(missing)}")
        if code == "VA" and nrows != 133:
            raise SystemExit(f"VA has {nrows} rows, expected 133")
    if available_n != 34:
        raise SystemExit(f"expected 34 Available states, built {available_n}")
    tpl = (root / "tools" / "coverage_template.html").read_text(encoding="utf-8")
    if "<!--STATES-->" not in tpl:
        raise SystemExit("coverage template is missing <!--STATES-->")
    (root / "coverage.html").write_text(tpl.replace("<!--STATES-->", "\n".join(parts)), encoding="utf-8")
    print("wrote coverage.html", "available", available_n, "sections", len(parts))


if __name__ == "__main__":
    main(sys.argv[1])
