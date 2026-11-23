# BIGCS 28 → 34 states inventory (read-only)

**As of:** Monday, November 23, 2026, about 1:40 AM ET (America/New_York).  
**Clone:** `/workspace/chatpreview` on `master`, up to date with `origin/master` at `00d73bb`. Untracked `preview/` only; nothing was committed or pushed.  
**Cloudflare / Workers / Stripe:** inspected read-only. No settings, scripts, or prices were changed.  
**Note copied from OfficePC:** `C:\Users\bclar\OneDrive\Grok Files\Obsidian\BIGCS\BIGCS Rollout Status and Research 2026-11-22.md` → `/workspace/marketing/states34/BIGCS Rollout Status and Research 2026-11-22.md` (same content as `/workspace/gis-tool-v1/review/BIGCS Rollout Status and Research 2026-11-22.md`, dated Sunday, November 22, 2026, 11:45 PM ET).

Copy rules for the later PR (not applied here): never call states “new”; use “Currently available states” / Available / Coming soon; never write “free”. Keep GA and AL as Coming soon.

---

## 1. The 34 Available states (Brian’s 60% live-verified rule)

From the November 22 note. Ready = November 12 live re-test plus documented post-12 live parcel-and-owner tests only. Denominators are official Census county (or county-equivalent) counts. CT is 9 Census planning regions. ME / NH / RI are town-based and stay Coming soon.

| ST | Ready / Census | % | Site today |
|---|---:|---:|---|
| AR | 75/75 | 100.0% | Available |
| AZ | **12/15** | 80.0% | Available, but site still shows **9/15** |
| CO | **40/64** | 62.5% | Not listed (add as Available) |
| CT | 9/9 | 100.0% | Available |
| DC | 1/1 | 100.0% | Available |
| DE | 3/3 | 100.0% | Available |
| FL | 67/67 | 100.0% | Available |
| HI | **4/5** | 80.0% | Not listed (add as Available) |
| IL | 70/102 | 68.6% | Available |
| MA | 14/14 | 100.0% | Available |
| MD | 19/24 | 79.2% | Available |
| MN | 71/87 | 81.6% | Available |
| MO | 76/115 | 66.1% | Available |
| MS | 82/82 | 100.0% | Available |
| MT | 53/56 | 94.6% | Available |
| NC | 99/100 | 99.0% | Available |
| ND | 52/53 | 98.1% | Available |
| NJ | 19/21 | 90.5% | Available |
| NM | **23/33** | 69.7% | Not listed (add as Available) |
| NV | **12/17** | 70.6% | Available, but site still shows **11/17** |
| NY | 56/62 | 90.3% | Available |
| OH | 88/88 | 100.0% | Available |
| OR | **22/36** | 61.1% | Not listed (add as Available) |
| PA | 54/67 | 80.6% | Available |
| SC | 43/46 | 93.5% | Available, but site still shows **41/46** (see conflicts) |
| SD | 46/66 | 69.7% | Available |
| TN | 94/95 | 98.9% | Available |
| TX | 217/254 | 85.4% | Available |
| UT | **18/29** | 62.1% | Not listed (add as Available) |
| VA | **122/133** | 91.7% | Available, but site still shows **96/133** (see conflicts) |
| VT | 14/14 | 100.0% | Available |
| WA | **26/39** | 66.7% | Not listed (add as Available) |
| WI | 70/72 | 97.2% | Available |
| WV | 55/55 | 100.0% | Available |

**Headline totals in the note:** 34 Available states; **1,726** ready counties in those states (aggregate method); **2,188** ready units nationwide. If the public November 12 **1,561** launch list is the starting point instead of the 1,588 aggregate, the comparable Available-state total today is **1,699**. The 27-county gap is still South Carolina (Barnwell, Calhoun) plus 25 Virginia localities that were in the aggregate file but not the launch CSV. The note does not pick a winner between those two lists.

**Adds that cross 60% (the +6):** CO (crossed Nov 18, Batch 5), HI (Nov 17, Honolulu; Kalawao later), NM (Nov 17, Batch 1), OR (Nov 17, Curry), UT (Nov 17, Batch 1), WA (Nov 17, Batch 2).

**Adds inside states already Available:** La Paz, Yavapai, and Pima AZ (9→12/15); Carson City NV (11→12/17); Buena Vista City VA (121→122/133 on the aggregate count).

**Stay Coming soon (explicit):** GA 82/159 (51.6%), AL 34/67 (50.7%). The coverage page also already lists IN, IA, KS, KY, LA, MI, NE, and OK as Coming soon; the note does not ask to add or remove those sections.

**Per-state leftover notes (do not invent ready counties from these):** WA leftovers include King and Pierce (no owner names), Jefferson (“INDIVIDUAL OWNER”), Whitman often surname-only, and Clark / Thurston / Spokane lacking owner names. OR leftovers include Polk HTTP 500, Tillamook no owners, Lincoln GeoMoose, Clackamas / Washington County taxlots geometry- or id-only. UT leftovers include Washington County CONNECT_Parcels (no owner) and several TLS failures. AL leftovers are Flagship / CaptureCAMA, not scraped.

---

## 2. Site files and lines to change

Public 28-state abbreviation list used almost everywhere:

`AR, AZ, CT, DC, DE, FL, IL, MA, MD, MN, MO, MS, MT, NC, ND, NJ, NV, NY, OH, PA, SC, SD, TN, TX, VA, VT, WI and WV`

Chip / “Currently available states” order is `NC, SC, VA, TN`, then the rest A–Z. The six additions belong in that A–Z run: CO, HI, NM, OR, UT, WA.

### Home — `index.html`

| Line | Current text (abridged) |
|---:|---|
| 27 | `og:description`: “Counties in 28 states today:” + abbrev list |
| 32 | `twitter:description`: same as 27 |
| 86 | Heading: “Currently available states” (keep wording; update the chips) |
| 87–88 | `<ul class="state-chips">` — 28 abbreviation chips (NC, SC, VA, TN, then A–Z) |
| 90 | “Counties in 28 states today.” |
| 108 | Building footprints: “Available in all 28 states.” |
| 119 | “Building footprints … in all 28 states” |
| 124 | Coverage blurb: “Counties in 28 states today:” + full state names (Arkansas … West Virginia) |
| 125–126 | Second identical 28-chip list |

Index `meta name="description"` (line ~19) and both JSON-LD blocks (lines 39 and 50) do **not** mention 28 or the state list. No change required there unless we choose to add coverage language.

### Coverage — `coverage.html` (static; 143 lines, long state blocks)

| Line | Current text |
|---:|---|
| 18 | Title: “County GIS Parcel Coverage in 28 States for CAD \| BIGCS” |
| 19 | `meta name="description"` — no count (optional) |
| 27 | `og:description`: 28-state abbrev list |
| 32 | `twitter:description`: same |
| 53 | `<p id="current-states"><strong>Currently available states (28):</strong> NC, SC, VA, TN, AR, AZ, CT, DC, DE, FL, IL, MA, MD, MN, MO, MS, MT, ND, NJ, NV, NY, OH, PA, SD, TX, VT, WI, WV.</p>` |
| 60 | Key: “building footprints can be drawn in all 28 states BIGCS covers today.” |
| 65–102 | 38 `<details class="cov-state">` sections (see table below). Need new sections for CO, HI, NM, OR, UT, WA as Available, and refreshed AZ / NV / VA (and, if Brian uses the aggregate SC count, SC). |

Current coverage badges and ready counts:

| id | Badge | Badge / of-line | Table rows | Notes |
|---|---|---|---:|---|
| st-nc | Available | 99 ready; 99/100 | 100 | Matches the note |
| st-sc | Available | 41 ready; 41/46 | 46 | Note says **43/46**; Barnwell and Calhoun are not in the ready set |
| st-ga | Coming soon | 159 counties | 159 | Keep Coming soon |
| st-va | Available | 96 ready; 96/133 | **137** | Note says **122/133**. Buena Vista City is on the page as “Not ready yet”. Row count 137 ≠ Census 133 (see conflicts) |
| st-tn | Available | 94 ready; 94/95 | 95 | Matches |
| st-al | Coming soon | 67 counties | 67 | Keep Coming soon |
| st-az | Available | 9 ready; 9/15 | 9 | Note says **12/15**. La Paz, Yavapai, Pima are absent |
| st-ar | Available | 75 counties | 75 | Matches (100%) |
| st-ct | Available | 9 counties | 9 | Matches |
| st-de | Available | 3 counties | 3 | Matches |
| st-dc | Available | 1 county | 1 | Matches |
| st-fl | Available | 67 counties | 67 | Matches |
| st-il | Available | 70 ready; 70/102 | 102 | Matches |
| st-in | Coming soon | 92 counties | 92 | Already listed |
| st-ia | Coming soon | 99 counties | 99 | Already listed |
| st-ks | Coming soon | 105 counties | 105 | Already listed |
| st-ky | Coming soon | 120 counties | 120 | Already listed |
| st-la | Coming soon | 64 counties | 64 | Already listed |
| st-md | Available | 19 ready; 19/24 | 24 | Matches |
| st-ma | Available | 14 counties | 14 | Matches |
| st-mi | Coming soon | 83 counties | 83 | Already listed |
| st-mn | Available | 71 ready; 71/87 | 87 | Matches |
| st-ms | Available | 82 counties | 82 | Matches |
| st-mo | Available | 76 ready; 76/115 | 115 | Matches |
| st-mt | Available | 53 ready; 53/56 | 53 | Matches ready count (table has 53 rows, not 56) |
| st-ne | Coming soon | 93 counties | 93 | Already listed |
| st-nv | Available | 11 ready; 11/17 | 11 | Note says **12/17**. Carson City is absent from the NV section |
| st-nj | Available | 19 ready; 19/21 | 21 | Matches |
| st-ny | Available | 56 ready; 56/62 | 62 | Matches |
| st-nd | Available | 52 ready; 52/53 | 52 | Matches ready count |
| st-oh | Available | 88 counties | 88 | Matches |
| st-ok | Coming soon | 77 counties | 77 | Already listed |
| st-pa | Available | 54 ready; 54/67 | 67 | Matches |
| st-sd | Available | 46 ready; 46/66 | 46 | Matches ready count |
| st-tx | Available | 217 ready; 217/254 | 254 | Matches |
| st-vt | Available | 14 counties | 14 | Matches |
| st-wv | Available | 55 counties | 55 | Matches |
| st-wi | Available | 70 ready; 70/72 | 72 | Matches |

No `st-co`, `st-hi`, `st-nm`, `st-or`, `st-ut`, or `st-wa` sections. Hits for “Colorado” / “Oregon” / “Washington” / “Buena Vista” in the file are **other states’ county names** (e.g. Colorado County, TX; Oregon County, MO; Buena Vista County, IA), not those states.

### Coverage builder (must be updated or the next rebuild will be wrong)

| File | Lines | Issue |
|---|---:|---|
| `tools/coverage_template.html` | 18, 27, 32, 53, 58 | Same 28-state title, social tags, “Currently available states (28):” list, and buildings key as `coverage.html` |
| `tools/build_coverage.py` | 11–16, 27, 44, 57, 73–76 | `AVAILABLE` is still only `{"NC","SC","GA","VA","TN"}` (and would badge GA Available). `NAMES` is missing AZ, CO, DC, HI, MA, MT, ND, NM, NV, OR, SD, UT, VT, WA, and others already on the live page. The script prints `<span class="cnt">{len(rs)} counties</span>` only — it does **not** emit “N counties ready” or “N of M counties are ready,” which the live page has. Comment at line 44 refers to “all 28 Available states.” |

### Pricing — `pricing.html`

| Line | Current text |
|---:|---|
| 65 | Checkout note: “Counties in 28 states today:” + abbrev list |
| 97 | FAQ-style: “Counties in 28 states today:” + abbrev list (CAD programs) |
| 101 | “Yes, in all 28 states BIGCS covers today.” (building footprints) |

See §7 for Stripe / Whole State links (no per-state payment links).

### Trial

| File | Line | Current text |
|---|---:|---|
| `trial.html` | 66 | “Counties in 28 states today.” |
| `trial.html` | 97 | “Counties in 28 states today:” + abbrev list |
| `assets/trial-counties.js` | 1–2 | Comment: “verified-ready list, Nov 12 2026.” `window.BIGCS_TRIAL_COUNTIES` has **28 keys** and the **launch** county counts (AZ 9, NV 11, VA 96, SC 41). **CO, HI, NM, OR, UT, WA are absent.** The trial form dropdown is filled from this object (`assets/trial-form.js` lines 10–12). |
| `assets/trial-form.js` | 3 | Endpoint `https://bigcs-license.bigcs.workers.dev/v1/trial/request` (no state list in this file) |

### FAQ — `faq.html`

| Line | Current text |
|---:|---|
| 88 | JSON-LD answer for “Which CAD programs does BIGCS work with?” — 28-state abbrev list |
| 96 | JSON-LD answer for “Can BIGCS draw building footprints?” — “in all 28 states BIGCS covers today” |
| 153–154 | Visible “Which CAD programs…” answer, same 28-state list |
| 157–158 | Visible “Can BIGCS draw building footprints?” answer, “all 28 states” |

### Other public pages

| File | Line | Current text |
|---:|---|---|
| `commands.html` | 63 | “Building footprints (all 28 states): …” |
| `commands.html` | 67 | “Counties in 28 states today:” + abbrev list |
| `howto-label-adjoiners.html` | 78 | “Counties in 28 states today:” + abbrev list |
| `interest.html` | 64 | State `<select>` is the 28 abbreviations plus **Other** (does **not** say “28 states”, but will be wrong until CO, HI, NM, OR, UT, WA are added) |

### No 28-state / available-list copy found

`sitemap.xml` (no count; lastmod dates are 2026-11-11 / trial 2026-11-02 — bump when publishing), `robots.txt`, `demo.html`, `install-help.html`, `tutorial.html`, `thank-you.html`, `beta.html`, `privacy.html`, `terms.html`, `refund.html`, `disclaimer.html` (“AS AVAILABLE” is legal language only).

`chatpreview/preview/pricing.html` and `preview/trial.html` are untracked local previews with the same 28-state wording; update or ignore so they do not drift.

---

## 3. How `coverage.html` gets per-county data

There is **no runtime JSON or API**. The published page is static HTML. The intended pipeline is:

1. A per-county CSV is passed to `python3 tools/build_coverage.py path/to/coverage_by_county.csv`.
2. The script groups rows by `state`, badges each state Available vs Coming soon from the `AVAILABLE` set, and injects `<details class="cov-state">` blocks into `tools/coverage_template.html` at the `<!--STATES-->` placeholder, writing `coverage.html`.

**CSV schema expected by the checked-in builder** (from the docstring and field use):

`state, county, owner, PIN, deed, plat, roads, buildings, state_control, ngs_control, data source, data year, year_type, older_copy, state_control_source, ngs_source, parcel_source_name`

Cell values for the yes/partial/no columns: `yes` / `partial` / `no`. `buildings` is required (the script exits if missing). `older_copy` may contain a year in parentheses to print an “Older copy (YYYY)” tag.

**Best existing builder-shaped file on the box:** `/workspace/gis-tool-v1/review/coverage_corrected_20261112_templatefmt.csv` (1,561 rows, 28 states only, same columns plus a few extras). It is the November 12 **launch** list (AZ 9, NV 11, VA 96, SC 41) and has **zero** rows for CO, HI, NM, OR, UT, WA.

The live `coverage.html` was **not** produced by the current checked-in `build_coverage.py` as it stands (stale `AVAILABLE` / `NAMES`, and the live page has “N counties ready” / “N of M counties are ready” lines the script does not write). A later one-off builder or a hand pass was committed. Rerunning the repo script on an old CSV would regress badges and counts.

No map SVG and no separate coverage JSON ship with the site.

---

## 4. License worker `STATES` and the trial allowlist

**Repo:** `bclarknc-tech/bigcs-app` (private), `license_service/`.  
**Worker name:** `bigcs-license` (Cloudflare account “Bclarknc@gmail.com's Account”). Last modified 2026-11-20 11:34 AM ET.  
**Local trees that match the live worker source (read-only):** `/workspace/trial-rc22-worker/service` (README calls this the current deploy tree) and `/workspace/bigcs-app-repo/license_service`. `wrangler.toml` `name = "bigcs-license"`.

`STATES` is a **Worker plain-text binding**, not a const in `index.js`. The script reads `env.STATES` (plus optional `env.ONDEMAND_STATES`) in `src/index.js` (`stateList` / `stateOk`). A purchase in any other state is held (status ok, activation refused) until the state is added.

**Live binding values (GET settings only):**

- `STATES` = `NC,SC,GA,VA,TN,TX,WV,MS,AR,MO,NY,OH,AL,WI,MN,AZ,CT,DC,DE,FL,IL,MA,MD,MT,ND,NJ,NV,PA,SD,VT`  
  That is the **28 Available states + AL + GA** (30). **CO, HI, NM, OR, UT, WA are not present.**
- `STATE` (default) = `NC`
- `ONDEMAND_STATES` = `""`

The same `STATES` string is in local `license_service/wrangler.toml` line 31 (comment: “append-only 28-state launch; AL/GA kept”).

**Trial allowlist** is `export const TRIAL_COUNTIES` in `license_service/src/trial_counties.js`, bundled into the live `index.js` (confirmed against the live script). Live and local copies match: **30 state keys**, same as `STATES` (28 + AL + GA). **CO, HI, NM, OR, UT, WA are not present.**

Live / local `TRIAL_COUNTIES` county counts:

`NC 99, SC 45, GA 73, VA 102, TN 94, WV 55, TX 253, MS 82, AR 75, MO 77, NY 56, OH 88, AL 31, WI 72, MN 79, AZ 9, CT 9, DC 1, DE 3, FL 67, IL 70, MA 14, MD 19, MT 53, ND 52, NJ 19, NV 11, PA 54, SD 46, VT 14`

This list is a **union** (comment in the file): it keeps AL, GA, and some counties that were not in the 28-state re-test, so several counts are **higher** than the public launch list / site form (site `trial-counties.js`: SC 41, VA 96, TX 217, MO 76, MN 71, WI 70, AZ 9, NV 11; no AL/GA).

`src/trial_request.js` `validate()` (line 35–38): a trial request is accepted if the state is in `STATES` **or** in `TRIAL_COUNTIES`, but the **county must match `TRIAL_COUNTIES`**. So even after `STATES` is expanded, trial requests in the six states will fail until those states’ ready counties are added to `TRIAL_COUNTIES` **and** to the site `assets/trial-counties.js` dropdown.

**Related worker files (no “28 states” string, but they will break or look wrong if only `STATES` is updated):**

- `src/counties.js` `COUNTIES` — same 30 state keys, no six new states. Used to validate paid county names and welcome-email coverage (`welcome.js` `checkCounties`: “state X has no county list”).
- `src/welcome.js` line 6: `STATE_NAME` still has only `NC, SC, GA, VA, TN`. Any other state falls back to the two-letter code in welcome emails. No “28 states” sentence in `welcome.js` or `src/emails.js`.
- Stale copies only (not the live client): `license_service/client/new/license.py` and `client/orig/license.py` still have `STATES = ["NC", "SC", "GA", "VA", "TN"]`.

Nothing in this section was edited.

---

## 5. County Builder coverage file on the box

**No recent County Builder coverage export** (csv/json) from the last three days contains CO/HI/NM/OR/UT/WA county tables for the website. The only November 22 artifacts found are the rollout markdown itself (`/workspace/gis-tool-v1/review/BIGCS Rollout Status and Research 2026-11-22.md` and the copy in `states34/`).

Older files that are **not** sufficient to rebuild the page for 34 states:

- `/workspace/gis-tool-v1/review/coverage_corrected_20261112.csv` and `_templatefmt.csv` / `_detail.csv` — 1,561 launch-list counties, 28 states, no six new states.
- `/workspace/gis-tool-v1/review/website_coverage_20261112.csv` — 51-state summary as of November 12 (CO was 23/64, etc.), not a per-county coverage table.
- Live config bundle `2026.11.20-3` under `/workspace/rc35/addr_sweep/bundle-2026.11.20-3` has engine county configs (including hi/nm/etc.) but is not a public coverage CSV (and must not be published as-is).

**Gap:** the site PR needs County Builder’s current per-county coverage file (builder schema above) for the six new states and for the AZ 12/15, NV 12/17, and VA (and possibly SC) refreshes. Ask County Builder for that file before generating `coverage.html`.

---

## 6. Off-site “28 states” / state-count mentions

### Trial and sales/support email templates

`license_service/src/welcome.js` and `src/emails.js` (live worker source) have **no** “28 states” / “28-state” / “twenty-eight” string. Welcome mail names the buyer’s state and counties (or “every county in {state}” for Whole State). Update `STATE_NAME` and `COUNTIES` when the six states go on sale, but there is no nationwide count line to edit in those templates.

### Quick Reference Manual and user manual

Searched with `pdftotext` (no “28 states” phrase in any of these):

- `/workspace/manual/BIGCS_Quick_Reference_Manual.pdf`
- `/workspace/rc32-test1/deliver/BIGCS Quick Reference Manual (updated 2026-11-17).pdf` — same text; byte-identical to the Desktop copy below
- `/workspace/BIGCS_Instruction_Manual.pdf` and `/workspace/manual/BIGCS_Instruction_Manual.md`

**Stale coverage claim (different wording):** QRM section 5.5 still says **“Beta, North Carolina only today.”** for building footprints. The website says footprints are available in all 28 (soon 34) states. Instruction manuals point readers to the coverage page and do not state a 28-state count.

### Email signatures

`/workspace/sgg/signature.txt` and `signature.html` are a Segeomatics / Brian personal signature (no BIGCS state count). No BIGCS sales signature file with a 28-state line was found in the OfficePC folders searched.

### Price lists

No standalone price-list PDF/CSV with a 28-state line was found under the OfficePC Desktop or Marketing folders, or under `/workspace/marketing` / `/workspace/manual`. The public price list is `pricing.html` (see §2 and §7). Review notes such as `/workspace/gis-tool-v1/review/pricemap_new_ids_20261030.md` are Stripe ID maps, not customer copy.

### OfficePC (read-only Select-String / listings)

`C:\Users\bclar\OneDrive\Desktop\BIGCS Software\`

- Manuals: `BIGCS Instruction Manual.pdf` (2026-11-11, 2,488,603 bytes) and `BIGCS Quick Reference Manual (updated 2026-11-17).pdf` (2026-11-17, 1,777,909 bytes) — same files already searched on the box. QRM still has the NC-only buildings line. Command List PDF and Letters samples have no 28-state phrase in this pass (PDFs other than the two manuals were not all run through `pdftotext`; filenames are samples/templates).
- No 28-state hit in the Desktop `.txt` files (`Call List 2026-11-17.txt`, `PRINT NOTES.txt`).

`C:\Users\bclar\OneDrive\Grok Files\GIS Tool\Marketing\`

- **Hit:** `Video & Social\TikTok Queue\TikTok Captions.txt` lines 71–72: “17 - 28 States, 1,561 Counties” and “Surveying in one of these 28 states? BIGCS covers 1,561 counties: NC, SC, VA, TN, AR, AZ, CT, DC, DE, FL, IL, MA, MD, MN, MO, MS, MT, ND, NJ, NV, NY, OH, PA, SD, TX, VT, WI, and WV. …” Same caption is on the box at `/workspace/marketing/tiktok_queue/TikTok Captions.txt` (and the v2 copies).
- `BIGCS_Short_Demo_Scripts_Nov11.docx`: no 28-state phrase (the “28” hits are video timestamps).
- Outreach / sales / YouTube / website-preview markdown and HTML from October: no “28 states” phrase (many predate the 28-state launch). Stale previews such as `Website\BIGCS_Coverage_Preview.html` (Oct 21) are not the live site.

### Other box copies (internal or ads; not the live site)

- `/workspace/ads_search/plan.md` — ad drafts: “1,561 Counties in 28 States” / “1,561 counties across 28 states.”
- `/workspace/ads_search/check_2026-11-23/landing_findings.md` and saved `trial.html` snapshots — quote the live trial line.
- `/workspace/marketing/BIGCS Website Watch.md` and weekly analytics reports — internal; they record the 28-state site copy and a past Facebook ad titled “BIGCS now covers 28 states” (those FB ads are already off).
- TikTok builder scripts under `/workspace/marketing/tiktok_queue/work/` (including vo “Surveying in one of these twenty-eight states?”).

---

## 7. Pricing-page Stripe / Whole State links

**No state has a Whole State Stripe checkout link on the live pricing page.**

`pricing.html` line 62 (Whole State row): “Interested in Whole State? Reach out to BIGCS Sales.” + `mailto:sales@bigcsoftware.com?subject=BIGCS%20Whole%20State`. There are no per-state payment links and no state picker on that row.

County-tier Stripe Payment Links on the same table (lines 56–61) and the Letters add-on links (line 75) are **plan-wide**, not per state. Expanding to 34 Available states does not, by itself, require new Stripe links — but a Whole State purchase in CO/HI/NM/OR/UT/WA will not activate until the worker `STATES` (and `COUNTIES`) lists include those states. Stripe itself was not changed.

`assets/checkout.js` still contains **test-mode** `state-monthly` / `state-yearly` Payment Links and old 2-/6-county prices. **No current site page references `checkout.js`.** It is leftover and should not be treated as live checkout.

---

## 8. Conflicts and open questions

1. **Launch list vs aggregate ready counts.** Site, `trial-counties.js`, and `coverage_corrected_20261112*.csv` follow the **1,561** launch list (SC 41, VA 96). The November 22 note’s headline 1,726 / VA 122 / SC 43 uses the **aggregate** method. Chief asked to refresh AZ 12/15, NV 12/17, and VA from County Builder. Confirm whether VA (and SC) should move to the aggregate numbers or stay on the launch list plus only the documented adds (Pima / Carson City / Buena Vista City).
2. **Buena Vista City, VA** is already a row on `coverage.html` but tagged **“Not ready yet.”** The note counts it as a post-12 ready add. Needs County Builder confirmation before flipping the badge/count.
3. **VA table has 137 unique county rows vs Census 133.** Worth cleaning when the section is rebuilt (possible extra name forms or non-Census rows). Ready badge is 96, not 137.
4. **AZ / NV site tables omit the new ready counties** (no La Paz, Yavapai, Pima; no Carson City). Counts cannot be refreshed honestly without those rows and their field checkmarks from County Builder.
5. **`tools/build_coverage.py` is stale** and would mis-badge GA as Available and drop current 28-state badges if rerun as-is. Update `AVAILABLE`, `NAMES`, ready-count wording, and the template before any rebuild.
6. **Worker `STATES` / `TRIAL_COUNTIES` / `COUNTIES` already include AL and GA** (Coming soon on the site) but **not** the six new Available states. Adding the six should be append-only; do not drop AL/GA from the worker unless Brian says so. Site trial dropdown should stay limited to **Available** states (plus the form’s ready counties), not AL/GA.
7. **Site trial list ≠ worker trial allowlist** for several already-Available states (worker is a looser union). Decide whether new-state counties on the form should be the live-verified ready set only.
8. **QRM still says building footprints are “Beta, North Carolina only today,”** which already disagrees with the 28-state (and future 34-state) site copy. Manual update is separate from the site PR.
9. **TikTok video 17 / caption** still says 28 states and 1,561 counties. Not part of the site PR; do not post a new version without Brian’s OK.
10. **No County Builder coverage file yet** for the six states’ county-level checkmarks. That is the main blocker for an accurate `coverage.html` rebuild.

