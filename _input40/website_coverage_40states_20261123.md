# Website coverage file — 40 Available states

**As of:** Monday, November 23, 2026, 3:50 AM ET (America/New_York).
**Rule:** A state is Available at ≥60% of official Census units, and only counties that were re-tested live and pulled a real parcel with owner info are listed.
**Config bundle `2026.11.23-1` is active** (rollback target `2026.11.20-3`). The license worker allowlist change (STATES +AK/LA/MI/NE/WY, plus expanded TRIAL_COUNTIES/COUNTIES) is prepared but **not deployed**.
**Do not publish the website coverage page until Brian's website OK is applied.** This write is local only, under `review/`.

## Files

- Ready list (simple): `/workspace/gis-tool-v1/review/website_coverage_40states_20261123.csv` — columns `state, county, fips, ready=yes`.
- Site format (plus extra flags): `/workspace/gis-tool-v1/review/website_coverage_40states_20261123_sitefmt.csv`
  - Exact columns the live coverage page is built from (`tools/build_coverage.py` / live https://bigcsoftware.com/coverage.html):
    `state, county, owner, PIN, deed, plat, roads, buildings, buildings_source, buildings_attribution, control, state_control, state_control_source, ngs_control, ngs_source, control_scope, data source, parcel_source_name, data year, year_type, older_copy`
  - Extra columns (builder ignores them): `fips, ready, parcels, address, zoning, fema, pin_dash_nodash, source_credit, in_nov12_public_list, added_after_nov12`.

## 40-state counts (live-verified)

| State | Ready | Census | % | Notes |
|---|---:|---:|---:|---|
| Alabama (AL) | 58 | 67 | 86.6% | new Available; includes 24 PowerSouth/Regrid counties, credited; +24 since Nov 12 (34→58) |
| Alaska (AK) | 19 | 30 | 63.3% | new Available; +8 since Nov 12 (11→19) |
| Arizona (AZ) | 12 | 15 | 80.0% |  |
| Arkansas (AR) | 75 | 75 | 100.0% |  |
| Colorado (CO) | 40 | 64 | 62.5% | near 60% line |
| Connecticut (CT) | 9 | 9 | 100.0% |  |
| Delaware (DE) | 3 | 3 | 100.0% |  |
| District of Columbia (DC) | 1 | 1 | 100.0% |  |
| Florida (FL) | 67 | 67 | 100.0% |  |
| Hawaii (HI) | 4 | 5 | 80.0% |  |
| Illinois (IL) | 70 | 102 | 68.6% |  |
| Louisiana (LA) | 43 | 64 | 67.2% | new Available; Livingston failed live re-test and is omitted; +16 since Nov 12 (27→43) |
| Maryland (MD) | 19 | 24 | 79.2% |  |
| Massachusetts (MA) | 14 | 14 | 100.0% |  |
| Michigan (MI) | 52 | 83 | 62.7% | new Available; Kent 404 and is omitted; +14 since Nov 12 (38→52) |
| Minnesota (MN) | 71 | 87 | 81.6% |  |
| Mississippi (MS) | 82 | 82 | 100.0% |  |
| Missouri (MO) | 76 | 115 | 66.1% |  |
| Montana (MT) | 53 | 56 | 94.6% |  |
| Nebraska (NE) | 92 | 93 | 98.9% | new Available; UNL statewide copies credited; Blaine has 0 rows and is omitted; +79 since Nov 12 (13→92) |
| Nevada (NV) | 12 | 17 | 70.6% |  |
| New Jersey (NJ) | 19 | 21 | 90.5% |  |
| New Mexico (NM) | 22 | 33 | 66.7% | in prior 34; Quay failed today's live re-test and was dropped (23→22); still over 60% |
| New York (NY) | 56 | 62 | 90.3% |  |
| North Carolina (NC) | 99 | 100 | 99.0% |  |
| North Dakota (ND) | 52 | 53 | 98.1% |  |
| Ohio (OH) | 88 | 88 | 100.0% |  |
| Oregon (OR) | 23 | 36 | 63.9% | in prior 34; +Klamath today (22→23) |
| Pennsylvania (PA) | 54 | 67 | 80.6% |  |
| South Carolina (SC) | 43 | 46 | 93.5% |  |
| South Dakota (SD) | 46 | 66 | 69.7% |  |
| Tennessee (TN) | 94 | 95 | 98.9% |  |
| Texas (TX) | 217 | 254 | 85.4% |  |
| Utah (UT) | 18 | 29 | 62.1% | near 60% line |
| Vermont (VT) | 14 | 14 | 100.0% |  |
| Virginia (VA) | 122 | 133 | 91.7% |  |
| Washington (WA) | 26 | 39 | 66.7% |  |
| West Virginia (WV) | 55 | 55 | 100.0% |  |
| Wisconsin (WI) | 70 | 72 | 97.2% |  |
| Wyoming (WY) | 15 | 23 | 65.2% | new Available; Fremont, Washakie, Big Horn added and credited; Laramie timed out and is omitted; +7 since Nov 12 (8→15) |
| **Total** | **2005** | **2359** | | |

**40 state codes:** AK, AL, AR, AZ, CO, CT, DC, DE, FL, HI, IL, LA, MA, MD, MI, MN, MO, MS, MT, NC, ND, NE, NJ, NM, NV, NY, OH, OR, PA, SC, SD, TN, TX, UT, VA, VT, WA, WI, WV, WY.

Headline: 40 Available states, **2,005** ready counties. The six new states are AK, AL, LA, MI, NE, WY (Brian approved publishing all 6, including the 24 credited PowerSouth/Regrid Alabama counties).

## Changes from the 34-state file

- Added AK 19, AL 58, LA 43, MI 52, NE 92, WY 15.
- Oregon: added Klamath (22→23/36, 63.9%).
- New Mexico: dropped Quay after a failed live re-test (23→22/33, 66.7%). Still Available.
- Existing 34-state rows were otherwise kept (site columns for previously published counties were not rewritten).

## Counties omitted today (live fail inside these 40 states)

- **NM Quay** — FeatureServer query failed (same as the earlier `nm_all.jsonl` fail).
- **LA Livingston**, **MI Kent**, **WY Laramie**, **NE Blaine** (0 rows) are not in the ready list.

## Sources

- Prior 34-state coverage files in `review/website_coverage_34states_20261123_*`
- Today's live verification JSONLs under `/workspace/rc35/county_fill_20261123/`
- Post-activate sample tests in `/workspace/rc35/county_fill_20261123/post_activate/` (all 6 new states + OR Klamath passed; NM Quay failed)
- Live county configs under `/workspace/gis-tool-v1/counties/` and bundle `2026.11.23-1`

