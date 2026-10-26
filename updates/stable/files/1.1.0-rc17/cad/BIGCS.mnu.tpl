//
//  BIGCS.mnu - BIGCS partial menu: BIGCS toolbar and BIGCS pull-down menu
//  (c) 2026 BIGCS Software. All rights reserved.
//  Load with MENULOAD (Carlson / IntelliCAD / AutoCAD) or let BIGCS_menu.lsp load it.
//  Template: the installer writes BIGCS.mnu from this file with the install folder's cad path in place of the marker.
//

***MENUGROUP=BIGCS

***POP1
**BIGCSMENU
ID_BIGCS_POP     [&BIGCS]
ID_M_PAR         [&Get Parcels...]^C^CBCS
ID_M_TXT         [&Labels Only...]^C^CBCSTXT
ID_M_ADJ         [&Adjoiner Table...]^C^CBCSADJ
ID_M_REF         [&Refresh Labels]^C^CBCSREF
ID_M_LTR         [Le&tters...]^C^CBCSLTR
                 [--]
ID_M_BND         [&Map Layers...]^C^CBCSBND
ID_M_STY         [Label &Style...]^C^CBCSST
ID_M_LOAD        [L&oad Job File...]^C^CBCSLOAD
                 [--]
ID_M_SHOW        [Show BIGCS Tool&bar]^C^CBCSTOOLBAR

***TOOLBARS
**TB_BIGCS
ID_TB_BIGCS      [_Toolbar("BIGCS", _Floating, _Show, 200, 150, 1)]
ID_T_PAR         [_Button("Get Parcels", "@CAD@\BCS_PAR16.bmp", "@CAD@\BCS_PAR32.bmp")]^C^CBCS
ID_T_TXT         [_Button("Labels Only", "@CAD@\BCS_TXT16.bmp", "@CAD@\BCS_TXT32.bmp")]^C^CBCSTXT
ID_T_ADJ         [_Button("Adjoiner Table", "@CAD@\BCS_ADJ16.bmp", "@CAD@\BCS_ADJ32.bmp")]^C^CBCSADJ
ID_T_REF         [_Button("Refresh Labels", "@CAD@\BCS_REF16.bmp", "@CAD@\BCS_REF32.bmp")]^C^CBCSREF
ID_T_LTR         [_Button("Letters", "@CAD@\BCS_LTR16.bmp", "@CAD@\BCS_LTR32.bmp")]^C^CBCSLTR
ID_T_BND         [_Button("Map Layers", "@CAD@\BCS_MAP16.bmp", "@CAD@\BCS_MAP32.bmp")]^C^CBCSBND
ID_T_STY         [_Button("Label Style", "@CAD@\BCS_STY16.bmp", "@CAD@\BCS_STY32.bmp")]^C^CBCSST
ID_T_LOAD        [_Button("Load Job", "@CAD@\BCS_LOAD16.bmp", "@CAD@\BCS_LOAD32.bmp")]^C^CBCSLOAD

***HELPSTRINGS
ID_BIGCS_POP     [BIGCS parcel, label and map layer tools]
ID_M_PAR         [Draw parcel lines and owner labels from county GIS. Pick a point, type lat/lon or State Plane, or search by address or PIN.]
ID_M_TXT         [Place owner labels only, without the parcel lines.]
ID_M_ADJ         [Place a table of adjoining owners and save it as a CSV next to the drawing.]
ID_M_REF         [Update every BIGCS label in this drawing from county GIS and list what changed.]
ID_M_LTR         [Open BIGCS Letters to make adjoiner notice letters from the adjoiner CSV.]
ID_M_BND         [Open the Map Layers window: state and county borders, monuments, roads, flood zones, easements and building footprints.]
ID_M_STY         [Change how owner labels look: lines, wording, name format and layers.]
ID_M_LOAD        [Insert a saved BIGCS job file (.lsp) into the drawing.]
ID_M_SHOW        [Show the BIGCS toolbar again if it was closed.]
ID_T_PAR         [Draw parcel lines and owner labels from county GIS. Pick a point, type lat/lon or State Plane, or search by address or PIN.]
ID_T_TXT         [Place owner labels only, without the parcel lines.]
ID_T_ADJ         [Place a table of adjoining owners and save it as a CSV next to the drawing.]
ID_T_REF         [Update every BIGCS label in this drawing from county GIS and list what changed.]
ID_T_LTR         [Open BIGCS Letters to make adjoiner notice letters from the adjoiner CSV.]
ID_T_BND         [Open the Map Layers window: state and county borders, monuments, roads, flood zones, easements and building footprints.]
ID_T_STY         [Change how owner labels look: lines, wording, name format and layers.]
ID_T_LOAD        [Insert a saved BIGCS job file (.lsp) into the drawing.]
ID_TB_BIGCS      [BIGCS toolbar]

//  End of BIGCS.mnu
