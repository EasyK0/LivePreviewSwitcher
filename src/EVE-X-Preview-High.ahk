; <COMPILER: v1.1.37.01>
#Requires AutoHotkey v2.0
default_JSON := "
(
{
    "global_Settings": {
        "Suspend_Hotkeys_Hotkey": "",
        "Global_Hotkeys": 1,
        "LastUsedProfile": "Default",
        "Minimize_Delay": 100,
        "ThumbnailStartLocation": {
            "x": 20,
            "y": 20,
            "width": 250,
            "height": 140
        },
        "ThumbnailBackgroundColor":"#57504E",
        "ThumbnailSnap": true,
        "ThumbnailSnap_Distance": 20,
        "ThumbnailMinimumSize": {
            "width": 50,
            "height": 50
        }
    },
    "_Profiles": {
        "Default": {
            "Client Settings": {
                "MinimizeInactiveClients": false,
                "AlwaysMaximize": false,
                "TrackClientPossitions": false,
                "Dont_Minimize_Clients": [
                    "Example Name1",
                    "Example Name2",
                    "Example Name3"
                ]
            },
            "Thumbnail Settings": {
                "ShowThumbnailTextOverlay": true,
                "ThumbnailTextColor":"#FAC57A",
                "ThumbnailTextSize": 12,
                "ThumbnailTextFont": "Gill Sans MT",
                "ThumbnailTextMargins": {
                    "x": 15,
                    "y": 5
                },
                "ShowClientHighlightBorder": true,
                "ClientHighligtColor": "#E36A0D",
                "ClientHighligtBorderthickness": 4,
                "HideThumbnailsOnLostFocus": false,
                "ThumbnailOpacity": 80,
                "ShowThumbnailsAlwaysOnTop": true,
                "ShowAllColoredBorders":0,
                "InactiveClientBorderthickness": 2,
                "InactiveClientBorderColor": "#8A8A8A"
            },
            "Hotkeys":[
                {"Example Name1":"1"},
                {"Example Name2":"ctrl & 1"},
                {"Example Name3":"Xbutton1 & 1"},
                {"Example Name4":"^XButton1 & 1"}
            ],
            "Thumbnail Positions": {},
            "Client Possitions": {},
            "Thumbnail Visibility":{},
            "Hotkey Groups":{},
            "Custom Colors":{                
                "cColorActive": "0",
                "cColors": {
                    "CharNames": ["Example Char"],
                    "TextColor": ["FFFFFF"],
                    "Bordercolor":["FFFFFF"],                
                    "IABordercolor":["FFFFFF"]                    
                }                               
            }
        }
    }
} 
)"
class JSON {
static null := ComValue(1, 0), true := ComValue(0xB, 1), false := ComValue(0xB, 0)
static Load(text, keepbooltype := false, as_map := true) {
keepbooltype ? (_true := JSON.true, _false := JSON.false, _null := JSON.null) : (_true := true, _false := false, _null := "")
as_map ? (map_set := (maptype := Map).Prototype.Set) : (map_set := (obj, key, val) => obj.%key% := val, maptype := Object)
NQ := "", LF := "", LP := 0, P := "", R := ""
D := [C := (A := InStr(text := LTrim(text, " `t`r`n"), "[") = 1) ? [] : maptype()], text := LTrim(SubStr(text, 2), " `t`r`n"), L := 1, N := 0, V := K := "", J := C, !(Q := InStr(text, '"') != 1) ? text := LTrim(text, '"') : ""
Loop Parse text, '"' {
Q := NQ ? 1 : !Q
NQ := Q && (SubStr(A_LoopField, -3) = "\\\" || (SubStr(A_LoopField, -1) = "\" && SubStr(A_LoopField, -2) != "\\"))
if !Q {
if (t := Trim(A_LoopField, " `t`r`n")) = "," || (t = ":" && V := 1)
continue
else if t && (InStr("{[]},:", SubStr(t, 1, 1)) || RegExMatch(t, "^-?\d*(\.\d*)?\s*[,\]\}]")) {
Loop Parse t {
if N && N--
continue
if InStr("`n`r `t", A_LoopField)
continue
else if InStr("{[", A_LoopField) {
if !A && !V
throw Error("Malformed JSON - missing key.", 0, t)
C := A_LoopField = "[" ? [] : maptype(), A ? D[L].Push(C) : map_set(D[L], K, C), D.Has(++L) ? D[L] := C : D.Push(C), V := "", A := Type(C) = "Array"
continue
} else if InStr("]}", A_LoopField) {
if !A && V
throw Error("Malformed JSON - missing value.", 0, t)
else if L = 0
throw Error("Malformed JSON - to many closing brackets.", 0, t)
else C := --L = 0 ? "" : D[L], A := Type(C) = "Array"
} else if !(InStr(" `t`r,", A_LoopField) || (A_LoopField = ":" && V := 1)) {
if RegExMatch(SubStr(t, A_Index), "m)^(null|false|true|-?\d+\.?\d*)\s*[,}\]\r\n]", &R) && (N := R.Len(0) - 2, R := R.1, 1) {
if A
C.Push(R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R)
else if V
map_set(C, K, R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R), K := V := ""
else throw Error("Malformed JSON - missing key.", 0, t)
} else {
if A_LoopField == '/' {
nt := SubStr(t, A_Index + 1, 1), N := 0
if nt == '/' {
if nt := InStr(t, '`n', , A_Index + 2)
N := nt - A_Index - 1
} else if nt == '*' {
if nt := InStr(t, '*/', , A_Index + 2)
N := nt + 1 - A_Index
} else nt := 0
if N
continue
}
throw Error("Malformed JSON - unrecognized character-", 0, A_LoopField " in " t)
}
}
}
} else if InStr(t, ':') > 1
throw Error("Malformed JSON - unrecognized character-", 0, SubStr(t, 1, 1) " in " t)
} else if NQ && (P .= A_LoopField '"', 1)
continue
else if A
LF := P A_LoopField, C.Push(InStr(LF, "\") ? UC(LF) : LF), P := ""
else if V
LF := P A_LoopField, map_set(C, K, InStr(LF, "\") ? UC(LF) : LF), K := V := P := ""
else
LF := P A_LoopField, K := InStr(LF, "\") ? UC(LF) : LF, P := ""
}
return J
UC(S, e := 1) {
static m := Map(Ord('"'), '"', Ord("a"), "`a", Ord("b"), "`b", Ord("t"), "`t", Ord("n"), "`n", Ord("v"), "`v", Ord("f"), "`f", Ord("r"), "`r")
local v := ""
Loop Parse S, "\"
if !((e := !e) && A_LoopField = "" ? v .= "\" : !e ? (v .= A_LoopField, 1) : 0)
v .= (t := InStr("ux", SubStr(A_LoopField, 1, 1)) ? SubStr(A_LoopField, 1, RegExMatch(A_LoopField, "i)^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K") - 1) : "") && RegexMatch(t, "i)^[ux][\da-f]+$") ? Chr(Abs("0x" SubStr(t, 2))) SubStr(A_LoopField, RegExMatch(A_LoopField, "i)^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K")) : m.has(Ord(A_LoopField)) ? m[Ord(A_LoopField)] SubStr(A_LoopField, 2) : "\" A_LoopField, e := A_LoopField = "" ? e : !e
return v
}
}
static Dump(obj, expandlevel := unset, space := "  ") {
expandlevel := IsSet(expandlevel) ? Abs(expandlevel) : 10000000
return Trim(CO(obj, expandlevel))
CO(O, J := 0, R := 0, Q := 0) {
static M1 := "{", M2 := "}", S1 := "[", S2 := "]", N := "`n", C := ",", S := "- ", E := "", K := ":"
if (OT := Type(O)) = "Array" {
D := !R ? S1 : ""
for key, value in O {
F := (VT := Type(value)) = "Array" ? "S" : InStr("Map,Object", VT) ? "M" : E
Z := VT = "Array" && value.Length = 0 ? "[]" : ((VT = "Map" && value.count = 0) || (VT = "Object" && ObjOwnPropCount(value) = 0)) ? "{}" : ""
D .= (J > R ? "`n" CL(R + 2) : "") (F ? (%F%1 (Z ? "" : CO(value, J, R + 1, F)) %F%2) : ES(value)) (OT = "Array" && O.Length = A_Index ? E : C)
}
} else {
D := !R ? M1 : ""
for key, value in (OT := Type(O)) = "Map" ? (Y := 1, O) : (Y := 0, O.OwnProps()) {
F := (VT := Type(value)) = "Array" ? "S" : InStr("Map,Object", VT) ? "M" : E
Z := VT = "Array" && value.Length = 0 ? "[]" : ((VT = "Map" && value.count = 0) || (VT = "Object" && ObjOwnPropCount(value) = 0)) ? "{}" : ""
D .= (J > R ? "`n" CL(R + 2) : "") (Q = "S" && A_Index = 1 ? M1 : E) ES(key) K (F ? (%F%1 (Z ? "" : CO(value, J, R + 1, F)) %F%2) : ES(value)) (Q = "S" && A_Index = (Y ? O.count : ObjOwnPropCount(O)) ? M2 : E) (J != 0 || R ? (A_Index = (Y ? O.count : ObjOwnPropCount(O)) ? E : C) : E)
if J = 0 && !R
D .= (A_Index < (Y ? O.count : ObjOwnPropCount(O)) ? C : E)
}
}
if J > R
D .= "`n" CL(R + 1)
if R = 0
D := RegExReplace(D, "^\R+") (OT = "Array" ? S2 : M2)
return D
}
ES(S) {
switch Type(S) {
case "Float":
if (v := '', d := InStr(S, 'e'))
v := SubStr(S, d), S := SubStr(S, 1, d - 1)
if ((StrLen(S) > 17) && (d := RegExMatch(S, "(99999+|00000+)\d{0,3}$")))
S := Round(S, Max(1, d - InStr(S, ".") - 1))
return S v
case "Integer":
return S
case "String":
S := StrReplace(S, "\", "\\")
S := StrReplace(S, "`t", "\t")
S := StrReplace(S, "`r", "\r")
S := StrReplace(S, "`n", "\n")
S := StrReplace(S, "`b", "\b")
S := StrReplace(S, "`f", "\f")
S := StrReplace(S, "`v", "\v")
S := StrReplace(S, '"', '\"')
return '"' S '"'
default:
return S == JSON.true ? "true" : S == JSON.false ? "false" : "null"
}
}
CL(i) {
Loop (s := "", space ? i - 1 : 0)
s .= space
return s
}
}
}
Class LiveThumb
{
Static  Dll_Module :=   0,
OBJ_COUNTER :=          0,
DTP_SIZE :=             48,
DTP_DWFLAGS := {    Destination:            0x0001,
Source:                 0x0002,
Opacity:                0x0004,
Visible:                0x0008,
SourceClientAreaOnly:   0x0010  },
DTP_OFFSETS := {    dwFlags:                0,
Destination:            4,
Source:                 20,
Opacity:                36,
Visible:                37,
SourceClientAreaOnly:   41      }
__New( hSource, hDest )
{
If ( !LiveThumb.DLL_MODULE )
LiveThumb.DLL_MODULE := DllCall("LoadLibrary", "Str","dwmapi.dll", "Ptr")
LiveThumb.OBJ_COUNTER += 1
If ( DllCall( "dwmapi.dll\DwmRegisterThumbnail"
, "Ptr",  hDest
, "Ptr",  hSource
, "Ptr*", &phThumb := 0
, "UPtr" ) )
Return False
this.THUMB_ID := phThumb
this.THUMB_UPDATED := False
this.THUMB_PENDING_UPDATE := True
this.THUMB_UPD_PROP_PTR := Buffer(LiveThumb.DTP_SIZE,0)
this.THUMB_ACT_PROP_PTR := Buffer(LiveThumb.DTP_SIZE,0)
this.Discard( )
Return this
}
__Delete( )
{
If ( this.THUMB_ID )
DllCall( "dwmapi.dll\DwmUnregisterThumbnail"
, "Ptr", this.THUMB_ID )
If ( LiveThumb.DLL_MODULE && !(LiveThumb.OBJ_COUNTER -= 1) )
{
DllCall("FreeLibrary", "Ptr",LiveThumb.DLL_MODULE)
LiveThumb.DLL_MODULE := 0
}
}
__Get(aName, Params) {
If ( LiveThumb.HasOwnProp(aName))
return LiveThumb.%aName%
}
QuerySourceSize( )
{
SIZE := Buffer(8,0)
If ( DllCall( "dwmapi.dll\DwmQueryThumbnailSourceSize"
, "Ptr", this.THUMB_ID
, "Ptr", SIZE
, "UPtr" ) ) {
SIZE := Buffer(0)
Return False
}
SourceSize := [NumGet(SIZE, 0, "Int"), NumGet(SIZE, 4, "Int")]
SIZE := Buffer(0)
Return SourceSize
}
Update( )
{
If ( DllCall( "dwmapi.dll\DwmUpdateThumbnailProperties"
, "Ptr", this.THUMB_ID
, "Ptr", this.THUMB_UPD_PROP_PTR
, "UPtr" ) )
Return False
this.THUMB_UPDATED := True
DllCall( "NtDll.dll\RtlCopyMemory"
, "Ptr",  this.THUMB_ACT_PROP_PTR
, "Ptr",  this.THUMB_UPD_PROP_PTR
, "UInt", LiveThumb.DTP_SIZE )
this.Discard( )
Return True
}
Discard( )
{
NumPut("UInt", 0, this.THUMB_UPD_PROP_PTR, LiveThumb.DTP_OFFSETS.dwFlags)
this.THUMB_PENDING_UPDATE := False
}
Destination {
Get {
If (!this.THUMB_UPDATED)
Return "NOT UPDATED"
arrRet := []
Loop 4
arrRet.Push(NumGet(this.THUMB_ACT_PROP_PTR, LiveThumb.DTP_OFFSETS.Destination * A_Index, "Int"))
Return arrRet
}
Set {
This.SetDwFlags("Destination")
Loop 4
NumPut("Int", value[A_Index], this.THUMB_UPD_PROP_PTR, LiveThumb.DTP_OFFSETS.Destination * A_Index)
}
}
Source {
Get {
If (!this.THUMB_UPDATED)
Return "NOT UPDATED"
arrRet := []
Loop 4
arrRet.Push(NumGet(this.THUMB_ACT_PROP_PTR, LiveThumb.DTP_OFFSETS.Source + 4*(A_Index-1), "Int"))
Return arrRet
}
Set {
This.SetDwFlags("Source")
Loop 4
NumPut("Int", value[A_Index], this.THUMB_UPD_PROP_PTR, LiveThumb.DTP_OFFSETS.Source + 4*(A_Index-1))
}
}
Opacity {
Get {
If (!this.THUMB_UPDATED)
Return "NOT UPDATED"
Return NumGet(this.THUMB_ACT_PROP_PTR, LiveThumb.DTP_OFFSETS.Opacity, "UChar")
}
Set {
This.SetDwFlags("Opacity")
NumPut("UChar", value, this.THUMB_UPD_PROP_PTR, LiveThumb.DTP_OFFSETS.Opacity)
}
}
Visible {
Get {
If (!this.THUMB_UPDATED)
Return "NOT UPDATED"
Return NumGet(this.THUMB_ACT_PROP_PTR, LiveThumb.DTP_OFFSETS.Visible, "Int")
}
Set {
This.SetDwFlags("Visible")
NumPut("Int", value, this.THUMB_UPD_PROP_PTR, LiveThumb.DTP_OFFSETS.Visible)
}
}
SourceClientAreaOnly {
Get {
If (!this.THUMB_UPDATED)
Return "NOT UPDATED"
Return NumGet(this.THUMB_ACT_PROP_PTR, LiveThumb.DTP_OFFSETS.SourceClientAreaOnly, "Int")
}
Set {
This.SetDwFlags("SourceClientAreaOnly")
NumPut("Uint", value, this.THUMB_UPD_PROP_PTR, LiveThumb.DTP_OFFSETS.SourceClientAreaOnly)
}
}
SetDwFlags(aName)
{
If (LiveThumb.DTP_DWFLAGS.HasOwnProp(aName)) {
NumPut( "UInt", NumGet( this.THUMB_UPD_PROP_PTR,
LiveThumb.DTP_OFFSETS.dwFlags, "UInt" ) | LiveThumb.DTP_DWFLAGS.%aName%,
this.THUMB_UPD_PROP_PTR,
LiveThumb.DTP_OFFSETS.dwFlags)
this.THUMB_PENDING_UPDATE := true
}
}
}
Class Main_Class extends ThumbWindow {
Static  WM_DESTROY := 0x02,
WM_SIZE := 0x05,
WM_NCCALCSIZE := 0x83,
WM_NCHITTEST := 0x84,
WM_NCLBUTTONDOWN := 0xA1,
WM_SYSKEYDOWN := 0x104,
WM_SYSKEYUP := 0x105,
WM_MOUSEMOVE := 0x200,
WM_LBUTTONDOWN := 0x201,
WM_LBUTTONUP := 0x0202,
WM_RBUTTONDOWN := 0x0204,
WM_RBUTTONUP := 0x0205,
WM_KEYDOWN := 0x0100,
WM_MOVE := 0x03,
WM_MOUSELEAVE := 0x02A2
static virtualKey := "vk0xE8"
LISTENERS := [
Main_Class.WM_LBUTTONDOWN,
Main_Class.WM_RBUTTONDOWN
]
EVEExe := "Ahk_Exe exefile.exe"
border_size := 4
HT_VALUES := [[13, 12, 14], [10, 1, 11], [16, 15, 17]]
EventHooks := Map()
ThumbWindows := {}
ThumbHwnd_EvEHwnd := Map()
__New() {
This._JSON := Load_JSON()
This.default_JSON := JSON.Load(default_JSON)
This.TrayMenu()
This.MinimizeDelay := This.Minimizeclients_Delay
prefixArr := ["","^","!", "#", "+", "+^", "+#", "+!", "^#", "^!","#!", "^+!", "^+#", "^#!", "+!#","^+#!"]
for index, prefix in prefixArr
Hotkey(  prefix . Main_Class.virtualKey, ObjBindMethod(This, "ActivateForgroundWindow"), "S P1")
if (This.Suspend_Hotkeys_Hotkey != "") {
HotIf (*) => WinExist(This.EVEExe)
try {
Hotkey This.Suspend_Hotkeys_Hotkey, ( * ) => This.Suspend_Hotkeys(), "S1"
}
catch ValueError as e {
MsgBox(e.Message ": --> " e.Extra " <-- in: Global Settings -> Suspend Hotkeys-Hotkey" )
}
}
this.timer := ObjBindMethod(this, "EVEMinimize")
This.margins := Buffer(16, 0)
NumPut("Int", 0, This.margins)
for i, message in this.LISTENERS
OnMessage(message, ObjBindMethod(This, "_OnMessage"))
This.CheckforActiveWindow := ObjBindMethod(This, "HideOnLostFocusTimer")
SetTimer(ObjBindMethod(This, "HandleMainTimer"), 50)
This.Save_Settings_Delay_Timer := ObjBindMethod(This, "SaveJsonToFile")
This.DestroyThumbnails := ObjBindMethod(This, "EvEWindowDestroy")
This.DestroyThumbnailsToggle := 1
This.Register_Hotkey_Groups()
This.BorderActive := 0
return This
}
HandleMainTimer() {
static HideShowToggle := 0, WinList := {}
try
WinList := WinGetList(This.EVEExe)
Catch
return
if (WinList.Length) {
try {
for index, hwnd in WinList {
WinList.%hwnd% := { Title: This.CleanTitle(WinGetTitle(hwnd)) }
if !This.ThumbWindows.HasProp(hwnd) {
This.EVE_WIN_Created(hwnd, WinList.%hwnd%.title)
if (!This.HideThumbnailsOnLostFocus)
This.ShowThumb(hwnd, "Show")
HideShowToggle := 1
}
else if (This.ThumbWindows.HasProp(hwnd)) {
if (This.ThumbWindows.%hwnd%["Window"].Title != WinList.%hwnd%.Title) {
This.EVENameChange(hwnd, WinList.%hwnd%.Title)
}
}
}
}
catch
return
try {
ActiveProcessName := WinGetProcessName("A")
if ((DllCall("IsIconic","UInt", WinActive("ahk_exe exefile.exe")) || ActiveProcessName != "exefile.exe") && !HideShowToggle && This.HideThumbnailsOnLostFocus) {
SetTimer(This.CheckforActiveWindow, -500)
HideShowToggle := 1
}
else if ( ActiveProcessName = "exefile.exe" && !DllCall("IsIconic","UInt", WinActive("ahk_exe exefile.exe"))) {
Ahwnd := WinExist("A")
if HideShowToggle {
for EVEHWND in This.ThumbWindows.OwnProps() {
This.ShowThumb(EVEHWND, "Show")
}
HideShowToggle := 0
This.BorderActive := 0
}
else if (Ahwnd != This.BorderActive) {
if (This.ShowThumbnailsAlwaysOnTop)
WinSetAlwaysOnTop(1,This.ThumbWindows.%Ahwnd%["Window"].Hwnd )
This.ShowActiveBorder(Ahwnd)
This.UpdateThumb_AfterActivation(, Ahwnd)
This.BorderActive := Ahwnd
}
}
}
}
if ( This.DestroyThumbnailsToggle ) {
for k, v in This.ThumbWindows.Clone().OwnProps() {
if !Winlist.HasProp(k) {
SetTimer(This.DestroyThumbnails, -500)
This.DestroyThumbnailsToggle := 0
}
}
}
}
HideOnLostFocusTimer() {
Try {
ForegroundPName := WinGetProcessName("A")
if (ForegroundPName = "exefile.exe") {
if (DllCall("IsIconic", "UInt", WinActive("ahk_exe exefile.exe"))) {
for EVEHWND in This.ThumbWindows.OwnProps() {
This.ShowThumb(EVEHWND, "Hide")
}
}
}
else if (ForegroundPName != "exefile.exe") {
for EVEHWND in This.ThumbWindows.OwnProps() {
This.ShowThumb(EVEHWND, "Hide")
}
}
}
}
RegisterHotkeys(title, EvE_hwnd) {
static registerGroups := 0
if (This._Hotkeys[title]) {
if(This.Global_Hotkeys) {
HotIf (*) => WinExist(This.EVEExe) && WinExist("EVE - " title ) && !WinActive("EVE-X-Preview - Settings")
try {
Hotkey This._Hotkeys[title], (*) => This.ActivateEVEWindow(,,title), "P1"
}
catch ValueError as e {
MsgBox(e.Message ": --> " e.Extra " <-- in Profile Settings - " This.LastUsedProfile " Hotkeys" )
}
}
else {
HotIf (*) => WinExist("EVE - " title ) && WinActive(This.EVEExe)
try {
Hotkey This._Hotkeys[title], (*) => This.ActivateEVEWindow(,,title),"P1"
}
catch ValueError as e {
MsgBox(e.Message ": --> " e.Extra " <-- in Profile Settings - " This.LastUsedProfile " Hotkeys" )
}
}
}
}
Register_Hotkey_Groups() {
static Fkey := "", BKey := "", Arr := []
if (IsObject(This.Hotkey_Groups) && This.Hotkey_Groups.Count != 0) {
for k, v in This.Hotkey_Groups {
if(This.Global_Hotkeys) {
if( v["ForwardsHotkey"] != "" ) {
Fkey := v["ForwardsHotkey"], Arr := v["Characters"]
HotIf ObjBindMethod(This, "OnWinExist", Arr)
try {
Hotkey( v["ForwardsHotkey"], ObjBindMethod(This, "Cycle_Hotkey_Groups",Arr,"ForwardsHotkey"), "P1")
}
catch ValueError as e {
MsgBox(e.Message ": --> " e.Extra " <-- in Profile Settings - " This.LastUsedProfile " - Hotkey Groups - " k "  - Forwards Hotkey" )
}
}
if( v["BackwardsHotkey"] != "" ) {
Fkey := v["BackwardsHotkey"], Arr := v["Characters"]
HotIf ObjBindMethod(This, "OnWinExist", Arr)
try {
Hotkey( v["BackwardsHotkey"], ObjBindMethod(This, "Cycle_Hotkey_Groups",Arr,"BackwardsHotkey"), "P1")
}
catch ValueError as e {
MsgBox(e.Message ": --> " e.Extra " <-- in Profile Settings - " This.LastUsedProfile " Hotkey Groups - " k " - Backwards Hotkey" )
}
}
}
else {
if( v["ForwardsHotkey"] != "" ) {
Fkey := v["ForwardsHotkey"], Arr := v["Characters"]
HotIf ObjBindMethod(This, "OnWinActive", Arr)
try {
Hotkey( v["ForwardsHotkey"], ObjBindMethod(This, "Cycle_Hotkey_Groups",Arr,"ForwardsHotkey"), "P1")
}
catch ValueError as e {
MsgBox(e.Message ": --> " e.Extra " <-- in Profile Settings - " This.LastUsedProfile " - Hotkey Groups - " k "  - Forwards Hotkey" )
}
}
if( v["BackwardsHotkey"] != "" ) {
Fkey := v["BackwardsHotkey"], Arr := v["Characters"]
HotIf ObjBindMethod(This, "OnWinActive", Arr)
try {
Hotkey( v["BackwardsHotkey"], ObjBindMethod(This, "Cycle_Hotkey_Groups",Arr,"BackwardsHotkey"), "P1")
}
catch ValueError as e {
MsgBox(e.Message ": --> " e.Extra " <-- in Profile Settings - " This.LastUsedProfile " Hotkey Groups - " k " - Backwards Hotkey" )
}
}
}
}
}
}
Cycle_Hotkey_Groups(Arr, direction,*) {
static Index := 0
length := Arr.Length
if (direction == "ForwardsHotkey") {
Try
Index := (n := IsActiveWinInGroup(This.CleanTitle(WinGetTitle("A")), Arr)) ? n+1 : 1
if (Index > length)
Index := 1
if (This.OnWinExist(Arr)) {
Try {
if !(WinExist("EVE - " This.CleanTitle(Arr[Index]))) {
while (!(WinExist("EVE - " This.CleanTitle(Arr[Index])))) {
index += 1
if (Index > length)
Index := 1
}
}
This.ActivateEVEWindow(,,This.CleanTitle(Arr[Index]))
}
}
}
else if (direction == "BackwardsHotkey") {
Try
Index := (n := IsActiveWinInGroup(This.CleanTitle(WinGetTitle("A")), Arr)) ? n-1 : length
if (Index <= 0)
Index := length
if (This.OnWinExist(Arr)) {
if !(WinExist("EVE - " This.CleanTitle(Arr[Index]))) {
while (!(WinExist("EVE - " This.CleanTitle(Arr[Index])))) {
Index -= 1
if (Index <= 0)
Index := length
}
}
This.ActivateEVEWindow(,,This.CleanTitle(Arr[Index]))
}
}
IsActiveWinInGroup(Title, Arr) {
for index, names in Arr {
if names = Title
return index
}
return false
}
}
OnWinExist(Arr, *) {
for index, Name in Arr {
If ( WinExist("EVE - " Name " Ahk_Exe exefile.exe") && !WinActive("EVE-X-Preview - Settings") ) {
return true
}
}
return false
}
OnWinActive(Arr, *) {
If (This.OnWinExist(Arr) && WinActive("Ahk_exe exefile.exe")) {
return true
}
return false
}
UpdateThumb_AfterActivation(event?, hwnd?) {
MinMax := -1
try MinMax := WinGetMinMax("ahk_id " hwnd)
if (This.ThumbWindows.HasProp(hwnd)) {
if !(MinMax == -1) {
This.Update_Thumb(false, This.ThumbWindows.%hwnd%["Window"].Hwnd)
}
}
}
EVENameChange(hwnd, title) {
if (This.ThumbWindows.HasProp(hwnd)) {
This.SetThumbnailText[hwnd] := title
This.RestoreClientPossitions(hwnd, title)
if (title = "") {
This.EvEWindowDestroy(hwnd, title)
This.EVE_WIN_Created(hwnd,title)
}
else If (This.ThumbnailPositions.Has(title)) {
This.EvEWindowDestroy(hwnd, title)
This.EVE_WIN_Created(hwnd,title)
rect := This.ThumbnailPositions[title]
This.ShowThumb(hwnd, "Hide")
This.ThumbMove( rect["x"],
rect["y"],
rect["width"],
rect["height"],
This.ThumbWindows.%hwnd% )
This.BorderSize(This.ThumbWindows.%hwnd%["Window"].Hwnd, This.ThumbWindows.%hwnd%["Border"].Hwnd)
This.Update_Thumb(true)
If ( This.HideThumbnailsOnLostFocus && WinActive(This.EVEExe) || !This.HideThumbnailsOnLostFocus && !WinActive(This.EVEExe) || !This.HideThumbnailsOnLostFocus && WinActive(This.EVEExe)) {
for k, v in This.ThumbWindows.OwnProps()
This.ShowThumb(k, "Show")
}
}
This.BorderActive := 0
This.RegisterHotkeys(title, hwnd)
}
}
_OnMessage(wparam, lparam, msg, hwnd) {
If (This.ThumbHwnd_EvEHwnd.Has(hwnd)  ) {
If (msg == Main_Class.WM_RBUTTONDOWN) {
while (GetKeyState("RButton")) {
if !(GetKeyState("LButton")) {
This.Mouse_DragMove(wparam, lparam, msg, hwnd)
This.Window_Snap(hwnd, This.ThumbWindows)
}
else
This.Mouse_ResizeThumb(wparam, lparam, msg, hwnd)
}
return 0
}
Else If (msg == Main_Class.WM_LBUTTONDOWN) {
if (wparam = 1) {
if !(WinActive(This.ThumbHwnd_EvEHwnd[hwnd]))
This.ActivateEVEWindow(hwnd)
}
else if (wparam = 9) {
if (!GetKeyState("RButton"))
PostMessage 0x0112, 0xF020, , , This.ThumbHwnd_EvEHwnd[hwnd]
}
return 0
}
}
}
EVE_WIN_Created(Win_Hwnd, Win_Title) {
This.RestoreClientPossitions(Win_Hwnd, Win_Title)
If !(This.ThumbWindows.HasProp(Win_Hwnd)) {
This.ThumbWindows.%Win_Hwnd% := This.Create_Thumbnail(Win_Hwnd, Win_Title)
This.ThumbHwnd_EvEHwnd[This.ThumbWindows.%Win_Hwnd%["Window"].Hwnd] := Win_Hwnd
if (This.ThumbWindows.%Win_Hwnd%["Window"].Title = "") {
This.SetThumbnailText[Win_Hwnd] := Win_Title
This.ShowThumb(Win_Hwnd, "Show")
return
}
else If (This.ThumbnailPositions.Has(Win_Title)) {
This.SetThumbnailText[Win_Hwnd] := Win_Title
rect := This.ThumbnailPositions[Win_Title]
This.ThumbMove( rect["x"],
rect["y"],
rect["width"],
rect["height"],
This.ThumbWindows.%Win_Hwnd% )
This.BorderSize(This.ThumbWindows.%Win_Hwnd%["Window"].Hwnd, This.ThumbWindows.%Win_Hwnd%["Border"].Hwnd)
This.Update_Thumb(true)
If ( This.HideThumbnailsOnLostFocus && WinActive(This.EVEExe) || !This.HideThumbnailsOnLostFocus && !WinActive(This.EVEExe) || !This.HideThumbnailsOnLostFocus && WinActive(This.EVEExe)) {
for k, v in This.ThumbWindows.OwnProps()
This.ShowThumb(k, "Show")
}
}
This.RegisterHotkeys(Win_Title, Win_Hwnd)
}
}
EvEWindowDestroy(hwnd?, WinTitle?) {
if (IsSet(hwnd) && This.ThumbWindows.HasProp(hwnd)) {
for k, v in This.ThumbWindows.Clone().%hwnd% {
if (K = "Thumbnail")
continue
v.Destroy()
}
This.ThumbWindows.DeleteProp(hwnd)
Return
}
for Win_Hwnd,v in This.ThumbWindows.Clone().OwnProps() {
if (!WinExist("Ahk_Id " Win_Hwnd)) {
for k,v in This.ThumbWindows.Clone().%Win_Hwnd% {
if (K = "Thumbnail")
continue
v.Destroy()
}
This.ThumbWindows.DeleteProp(Win_Hwnd)
}
}
This.DestroyThumbnailsToggle := 1
}
ActivateEVEWindow(hwnd?,ThisHotkey?, title?) {
if (IsSet(hwnd) && This.ThumbHwnd_EvEHwnd.Has(hwnd)) {
hwnd := WinExist(This.ThumbHwnd_EvEHwnd[hwnd])
title := This.CleanTitle(WinGetTitle("Ahk_id " Hwnd))
}
Else if (IsSet(title)) {
title := "EVE - " title
hwnd := WinExist(title " Ahk_exe exefile.exe")
}
if (WinActive("Ahk_id " hwnd))
Return
If (DllCall("IsIconic", "UInt", hwnd)) {
if (This.AlwaysMaximize)  || ( This.TrackClientPossitions && This.ClientPossitions[This.CleanTitle(title)]["IsMaximized"] ) {
This.ShowWindowAsync(hwnd, 3)
}
else {
This.ShowWindowAsync(hwnd)
}
}
Else {
This.ActivateHwnd := hwnd
SendEvent("{Blind}{" Main_Class.virtualKey "}")
}
if (This.MinimizeInactiveClients) {
This.wHwnd := hwnd
SetTimer(This.timer, -This.MinimizeDelay)
}
}
ActivateForgroundWindow(*) {
try {
if !(DllCall("SetForegroundWindow", "UInt", This.ActivateHwnd)) {
DllCall("SetForegroundWindow", "UInt", This.ActivateHwnd)
}
if (This.AlwaysMaximize && WinGetMinMax("ahk_id " This.ActivateHwnd) = 0) || ( This.TrackClientPossitions && This.ClientPossitions[This.CleanTitle(WinGetTitle("Ahk_id " This.ActivateHwnd))]["IsMaximized"] && WinGetMinMax("ahk_id " This.ActivateHwnd) = 0 )
This.ShowWindowAsync(This.ActivateHwnd, 3)
}
Return
}
EVEMinimize() {
for EveHwnd, GuiObj in This.ThumbWindows.OwnProps() {
ThumbHwnd := GuiObj["Window"].Hwnd
try
WinTitle := WinGetTitle("Ahk_Id " EveHwnd)
catch
continue
if (EveHwnd = This.wHwnd || Dont_Minimze_Enum(EveHwnd, WinTitle) || WinTitle == "EVE" || WinTitle = "")
continue
else {
if !(EveHwnd = WinExist("A")) {
This.ShowWindowAsync(EveHwnd, 11)
}
}
}
Dont_Minimze_Enum(hwnd, EVEwinTitle) {
WinTitle := This.CleanTitle(EVEwinTitle)
if !(WinTitle = "") {
for k in This.Dont_Minimize_Clients {
value := This.CleanTitle(k)
if value == WinTitle
return 1
}
return 0
}
}
}
ThumbMove(x := "", y := "", Width := "", Height := "", GuiObj := "") {
for Names, Obj in GuiObj {
if (Names = "Thumbnail")
continue
WinMove(x, y, Width, Height, Obj.Hwnd)
}
}
Client_Possitions() {
IDs := WinGetList("Ahk_Exe " This.EVEExe)
for k, v in IDs {
Title := This.CleanTitle(WinGetTitle("Ahk_id " v))
if !(Title = "") {
if (DllCall("IsIconic", "UInt", v)) {
This.ShowWindowAsync(v)
if (WinWaitActive("Ahk_Id " v, , 2)) {
Sleep(200)
WinGetPos(&X, &Y, &Width, &Height, "Ahk_Id " v)
if (DllCall("IsZoomed", "UInt", v)) {
This.ClientPossitions[Title] := [X, Y, Width, Height, 1]
}
else {
This.ClientPossitions[Title] := [X, Y, Width, Height, 0]
}
}
}
else {
WinGetPos(&X, &Y, &Width, &Height, "Ahk_Id " v)
if (DllCall("IsZoomed", "UInt", v)) {
This.ClientPossitions[Title] := [X, Y, Width, Height, 1]
}
else
This.ClientPossitions[Title] := [X, Y, Width, Height, 0]
}
}
}
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
RestoreClientPossitions(hwnd, title) {
if (This.TrackClientPossitions) {
if ( This.TrackClientPossitions && This.ClientPossitions[title] ) {
if (DllCall("IsIconic", "UInt", hwnd) && This.ClientPossitions[title]["IsMaximized"] || DllCall("IsZoomed", "UInt", hwnd) && This.ClientPossitions[title]["IsMaximized"])  {
This.SetWindowPlacement(hwnd,This.ClientPossitions[title]["x"], This.ClientPossitions[title]["y"],
This.ClientPossitions[title]["width"], This.ClientPossitions[title]["height"], 9 )
This.ShowWindowAsync(hwnd, 3)
Return
}
else if (DllCall("IsIconic", "UInt", hwnd) && !This.ClientPossitions[title]["IsMaximized"] || DllCall("IsZoomed", "UInt", hwnd) && !This.ClientPossitions[title]["IsMaximized"])  {
This.SetWindowPlacement(hwnd,This.ClientPossitions[title]["x"], This.ClientPossitions[title]["y"],
This.ClientPossitions[title]["width"], This.ClientPossitions[title]["height"], 9 )
This.ShowWindowAsync(hwnd, 4)
Return
}
else if ( This.ClientPossitions[title]["IsMaximized"]) {
This.SetWindowPlacement(hwnd,This.ClientPossitions[title]["x"], This.ClientPossitions[title]["y"],
This.ClientPossitions[title]["width"], This.ClientPossitions[title]["height"] )
This.ShowWindowAsync(hwnd, 3)
Return
}
else if ( !This.ClientPossitions[title]["IsMaximized"]) {
This.SetWindowPlacement(hwnd,This.ClientPossitions[title]["x"], This.ClientPossitions[title]["y"],
This.ClientPossitions[title]["width"], This.ClientPossitions[title]["height"], 4 )
This.ShowWindowAsync(hwnd, 4)
Return
}
}
}
}
GetWindowPlacement(hwnd) {
DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", WP := Buffer(44))
Lo := NumGet(WP, 28, "Int")
To := NumGet(WP, 32, "Int")
Wo := NumGet(WP, 36, "Int") - Lo
Ho := NumGet(WP, 40, "Int") - To
CMD := NumGet(WP, 8, "Int")
flags := NumGet(WP, 4, "Int")
MinX := NumGet(WP, 12, "Int")
MinY := NumGet(WP, 16, "Int")
MaxX := NumGet(WP, 20, "Int")
MaxY := NumGet(WP, 24, "Int")
WP := ""
return { X: Lo, Y: to, W: Wo, H: Ho , cmd: CMD, flags: flags, MinX: MinX, MinY: MinY, MaxX: MaxX, MaxY: MaxY }
}
SetWindowPlacement(hwnd:="", X:="", Y:="", W:="", H:="", action := 9) {
DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", WP := Buffer(44))
Lo := NumGet(WP, 28, "Int")
To := NumGet(WP, 32, "Int")
Wo := NumGet(WP, 36, "Int") - Lo
Ho := NumGet(WP, 40, "Int") - To
L := X = "" ? Lo : X
T := Y = "" ? To : Y
R := L + (W = "" ? Wo : W)
B := T + (H = "" ? Ho : H)
NumPut("UInt",action,WP,8)
NumPut("UInt",L,WP,28)
NumPut("UInt",T,WP,32)
NumPut("UInt",R,WP,36)
NumPut("UInt",B,WP,40)
Return DllCall("User32.dll\SetWindowPlacement", "Ptr", hwnd, "Ptr", WP)
}
ShowWindowAsync(hWnd, nCmdShow := 9) {
DllCall("ShowWindowAsync", "UInt", hWnd, "UInt", nCmdShow)
}
GetActiveWindow() {
Return DllCall("GetActiveWindow", "Ptr")
}
SetActiveWindow(hWnd) {
Return DllCall("SetActiveWindow", "Ptr", hWnd)
}
SetFocus(hWnd) {
Return DllCall("SetFocus", "Ptr", hWnd)
}
SetWindowPos(hWnd, x, y, w, h, hWndInsertAfter := 0, uFlags := 0x0020) {
Return DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", hWndInsertAfter, "Int", x, "Int", y, "Int", w, "Int", h, "UInt", uFlags)
}
CleanTitle(title) {
Return RegExReplace(title, "^(?i)eve(?:\s*-\s*)?\b", "")
}
SaveJsonToFile() {
FileDelete("EVE-X-Preview.json")
FileAppend(JSON.Dump(This._JSON, , "    "), "EVE-X-Preview.json")
}
}
Class ThumbWindow extends Propertys {
Create_Thumbnail(Win_Hwnd, Win_Title) {
ThumbObj := Map()
ThumbObj["Window"] := Gui("+Owner +LastFound -Caption +ToolWindow +E0x08000000 " (This.ShowThumbnailsAlwaysOnTop ? "AlwaysOnTop" : "-AlwaysOnTop") , Win_Title)
ThumbObj["Window"].OnEvent("Close", GUI_Close_Button)
Try
ThumbObj["Window"].BackColor := This.ThumbnailBackgroundColor
catch as e {
ThumbObj["Window"].BackColor := 0x57504e
This.ThumbnailBackgroundColor := 0x57504e
ThumbObj["Window"].BackColor := This.ThumbnailBackgroundColor
MsgBox( "Invalid Color:  Global Settings -> Thumbnail Background Color`n`nUse the following syntax:`n HEX =>: #FFFFFF or 0xFFFFFF or FFFFFF`nRGB =>: 255, 255, 255 or rgb(255, 255, 255)`n`nColor is now set to default")
}
DllCall("Dwmapi\DwmExtendFrameIntoClientArea",
"Ptr", ThumbObj["Window"].Hwnd,
"Ptr", This.margins,
)
WinSetTransparent(This.ThumbnailOpacity)
ThumbObj["Window"].Show("Hide")
WinMove(    This.ThumbnailStartLocation["x"],
This.ThumbnailStartLocation["y"],
This.ThumbnailStartLocation["width"],
This.ThumbnailStartLocation["height"]
)
WinGetClientPos(, , &W, &H, "ahk_id " Win_Hwnd)
ThumbObj["Thumbnail"] := LiveThumb(Win_Hwnd, ThumbObj["Window"].Hwnd)
ThumbObj["Thumbnail"].Source := [0, 0, W, H]
ThumbObj["Thumbnail"].Destination := [0, 0, This.ThumbnailStartLocation["width"], This.ThumbnailStartLocation["height"]]
ThumbObj["Thumbnail"].SourceClientAreaOnly := True
ThumbObj["Thumbnail"].Visible := True
ThumbObj["Thumbnail"].Opacity := 255
ThumbObj["Thumbnail"].Update()
ThumbObj["TextOverlay"] := Gui("+LastFound -Caption +E0x20 +Owner" ThumbObj["Window"].Hwnd " " (This.ShowThumbnailsAlwaysOnTop ? "AlwaysOnTop" : "-AlwaysOnTop"), Win_Title)
ThumbObj["TextOverlay"].MarginX := This.ThumbnailTextMargins["x"]
ThumbObj["TextOverlay"].MarginY := This.ThumbnailTextMargins["y"]
CheckError := 0
if (This.CustomColorsActive) {
if (This.CustomColorsGet[Win_Title]["Char"] != "" && This.CustomColorsGet[Win_Title]["Text"] != "") {
try {
ThumbObj["TextOverlay"].SetFont("s" This.ThumbnailTextSize " q6 w500 c" This.CustomColorsGet[Win_Title]["Text"] , This.ThumbnailTextFont)
}
catch as e {
CheckError := 1
MsgBox("Error: Thumbnail Text Color is wrong´nin: Profile Settings - " This.LastUsedProfile " - Custom Colors -> " Win_Title "`nUse the following syntax:`n HEX =>: #FFFFFF or 0xFFFFFF or FFFFFF`nRGB =>: 255, 255, 255 or rgb(255, 255, 255)")
}
}
else
CheckError := 1
}
if (CheckError || !This.CustomColorsActive) {
try {
ThumbObj["TextOverlay"].SetFont("s" This.ThumbnailTextSize " q6 w500 c" This.ThumbnailTextColor, This.ThumbnailTextFont)
}
catch as e {
MsgBox("Error: Thumbnail Text Color Or Thumbnail Text Font are wrong´nin: Profile Settings - " This.LastUsedProfile " - Thumbnail Settings`nUse the following syntax:`n HEX =>: #FFFFFF or 0xFFFFFF or FFFFFF`nRGB =>: 255, 255, 255 or rgb(255, 255, 255)`nValues are now Set to Default")
This.ThumbnailTextSize := "12", This.ThumbnailTextColor := "0xfac57a", This.ThumbnailTextFont := "Gill Sans MT"
ThumbObj["TextOverlay"].SetFont("s" This.ThumbnailTextSize " q6 w500 c" This.ThumbnailTextColor, This.ThumbnailTextFont)
}
}
ThumbTitle := ThumbObj["TextOverlay"].Add("Text", "vOverlayText w" This.ThumbnailStartLocation["width"], Win_Title)
ThumbTitle.Opt("+Background040101")
ThumbObj["TextOverlay"].BackColor := "040101"
WinSetTransColor("040101")
ThumbObj["TextOverlay"].Show("Hide")
WinMove(This.ThumbnailStartLocation["x"],
This.ThumbnailStartLocation["y"],
This.ThumbnailStartLocation["width"],
This.ThumbnailStartLocation["height"]
)
border_thickness := This.ClientHighligtBorderthickness
border_color := This.ClientHighligtColor
ThumbObj["Border"] := Gui("-Caption +E0x20 +Owner" ThumbObj["Window"].Hwnd)
CheckError := 0
if (This.CustomColorsActive && !This.ShowAllColoredBorders) {
if (This.CustomColorsGet[Win_Title]["Char"] != "" && This.CustomColorsGet[Win_Title]["Border"] != "") {
try {
ThumbObj["Border"].BackColor := This.CustomColorsGet[Win_Title]["Border"]
}
catch as e {
CheckError := 1
MsgBox("Error: Client Highligt Color are wrong´nin: Profile Settings - " This.LastUsedProfile " - Custom Colors - " Win_Title "`nUse the following syntax:`n HEX =>: #FFFFFF or 0xFFFFFF or FFFFFF`nRGB =>: 255, 255, 255 or rgb(255, 255, 255)")
}
}
else
CheckError := 1
}
else if (This.ShowAllColoredBorders) {
if (This.CustomColorsActive && This.CustomColorsGet[Win_Title]["Char"] != "" && This.CustomColorsGet[Win_Title]["IABorder"] != "") {
try {
ThumbObj["Border"].BackColor := This.CustomColorsGet[Win_Title]["IABorder"]
}
catch as e {
CheckError := 1
MsgBox("Error: Client Highligt Color are wrong´nin: Profile Settings - " This.LastUsedProfile " - Custom Colors - " Win_Title "`nUse the following syntax:`n HEX =>: #FFFFFF or 0xFFFFFF or FFFFFF`nRGB =>: 255, 255, 255 or rgb(255, 255, 255)")
}
}
else {
try {
ThumbObj["Border"].BackColor := This.InactiveClientBorderColor
}
catch as e {
CheckError := 1
MsgBox("Error: Client Highligt Color are wrong´nin: Profile Settings - " This.LastUsedProfile " Thumbnail Settings - Inactive Border Color `nUse the following syntax:`n HEX =>: #FFFFFF or 0xFFFFFF or FFFFFF`nRGB =>: 255, 255, 255 or rgb(255, 255, 255)")
}
}
}
if ((CheckError) || (!This.CustomColorsActive && !This.ShowAllColoredBorders)) {
try {
ThumbObj["Border"].BackColor := border_color
}
catch as e {
MsgBox("Error: Client Highligt Color are wrong´nin: Profile Settings - " This.LastUsedProfile " - Thumbnail Settings`nUse the following syntax:`n HEX =>: #FFFFFF or 0xFFFFFF or FFFFFF`nRGB =>: 255, 255, 255 or rgb(255, 255, 255)`nValues are now Set to Default")
This.ClientHighligtColor := "0xe36a0d"
ThumbObj["Border"].BackColor := This.ClientHighligtColor
}
}
size := This.BorderSize(ThumbObj["Window"].Hwnd, ThumbObj["Border"].Hwnd)
ThumbObj["Border"].Show("w" size.w " h" size.h " x" size.x " y" size.y "NoActivate Hide")
return ThumbObj
GUI_Close_Button(*) {
return
}
}
BorderSize(DesinationHwnd, BorderHwnd, thickness?) {
if (IsSet(thickness))
border_thickness := thickness
else if (This.ShowAllColoredBorders)
border_thickness := This.InactiveClientBorderthickness
else
border_thickness := This.ClientHighligtBorderthickness
WinGetPos(&dx, &dy, &dw, &dh, DesinationHwnd)
offset := 0
outerX := offset
outerY := offset
outerX2 := dw - offset
outerY2 := dh - offset
innerX := border_thickness + offset
innerY := border_thickness + offset
innerX2 := dw - border_thickness - offset
innerY2 := dh - border_thickness - offset
newX := dx
newY := dy
newW := dw
newH := dh
WinSetRegion(outerX "-" outerY " " outerX2 "-" outerY " " outerX2 "-" outerY2 " " outerX "-" outerY2 " " outerX "-" outerY "    " innerX "-" innerY " " innerX2 "-" innerY " " innerX2 "-" innerY2 " " innerX "-" innerY2 " " innerX "-" innerY, BorderHwnd)
return { x: newX, y: newY, w: newW, h: newH }
}
Mouse_DragMove(wparam, lparam, msg, hwnd) {
This.Resize := 1
dragging := 0
ThumbMap := Map()
MouseGetPos(&x0, &y0, &window_id)
if !(This.ThumbHwnd_EvEHwnd.Has(window_id))
return
WinGetPos &wx, &wy, &wn, &wh, window_id
for ThumbIDs in This.ThumbHwnd_EvEHwnd {
if (ThumbIDs == This.ThumbHwnd_EvEHwnd[hwnd])
continue
if This.ThumbWindows.HasProp(This.ThumbHwnd_EvEHwnd[ThumbIDs]) {
for k, v in This.ThumbWindows.%This.ThumbHwnd_EvEHwnd[ThumbIDs]% {
WinGetPos(&Tempx, &Tempy, , , v.Hwnd)
ThumbMap[v.Hwnd] := { x: Tempx, y: Tempy }
}
}
}
while (GetKeyState("RButton") && !GetKeyState("LButton")) {
MouseGetPos &x, &y
Nx := x - x0, NEUx := wx + Nx
Ny := y - y0, NEUy := wy + Ny
if This.ThumbWindows.HasProp(This.ThumbHwnd_EvEHwnd[hwnd]) {
for k, v in This.ThumbWindows.%This.ThumbHwnd_EvEHwnd[hwnd]% {
WinMove(NEUx, NEUy, , , v.Hwnd)
}
}
if (wparam = 10) {
for k, v in This.ThumbWindows.OwnProps() {
for type, Obj in v {
if (hwnd == Obj.Hwnd)
continue
Ax := ThumbMap[Obj.Hwnd].x + Nx
Ay := ThumbMap[Obj.Hwnd].y + Ny
WinMove(Ax, Ay, , , Obj.Hwnd)
}
}
}
}
}
Mouse_ResizeThumb(wparam, lparam, msg, hwnd) {
This.Resize := 0
while (GetKeyState("LButton") && GetKeyState("RButton")) {
Sleep 10
if !(This.Resize) {
WinGetPos(&Rx, &Ry, &Width, &Height, hwnd)
MouseGetPos(&Bx, &By)
This.Resize := 1
}
MouseGetPos(&DragX, &DragY)
x := DragX - Bx, Wn := Width + x
y := DragY - BY, Wh := Height + y
if (Wn < This.ThumbnailMinimumSize["width"]) {
Wn := This.ThumbnailMinimumSize["width"]
}
if (Wh < This.ThumbnailMinimumSize["height"]) {
Wh := This.ThumbnailMinimumSize["height"]
}
for k, v in This.ThumbWindows.%This.ThumbHwnd_EvEHwnd[hwnd]% {
WinMove(, , Wn, Wh, v.hwnd)
}
This.Update_Thumb(false, hwnd)
This.BorderSize(This.ThumbWindows.%This.ThumbHwnd_EvEHwnd[hwnd]%["Window"].Hwnd, This.ThumbWindows.%This.ThumbHwnd_EvEHwnd[hwnd]%["Border"].Hwnd)
if (!GetKeyState("LCtrl")) {
for ThumbIDs in This.ThumbHwnd_EvEHwnd {
if (ThumbIDs == This.ThumbHwnd_EvEHwnd[hwnd])
continue
for k, v in This.ThumbWindows.%This.ThumbHwnd_EvEHwnd[ThumbIDs]% {
if k = "Window"
window := v.Hwnd
WinMove(, , Wn, Wh, v.Hwnd)
if (k = "Border") {
border := v.Hwnd
}
if (k = "TextOverlay") {
TextOverlay := v.Hwnd
continue
}
}
This.BorderSize(window, border)
}
This.Update_Thumb()
}
}
}
Window_Snap(hwnd, GuiObject, SnapRange := 20) {
if (This.ThumbnailSnap) {
SnapRange := This.ThumbnailSnap_Distance
WinGetPos(&X, &Y, &Width, &Height, hwnd)
A_RECT := { TL: [X, Y],
TR: [X + Width, Y],
BL: [X, Y + Height],
BR: [X + Width, Y + Height] }
destX := X, destY := Y, shouldMove := false
for index, _Gui in GuiObject.OwnProps() {
if (hwnd = _Gui["Window"].Hwnd) {
continue
}
WinGetPos(&X, &Y, &Width, &Height, _Gui["Window"].Hwnd)
Gui_RECT := { TL: [X, Y],
TR: [X + Width, Y],
BL: [X, Y + Height],
BR: [X + Width, Y + Height] }
for _, corner in A_RECT.OwnProps() {
for _, neighborCorner in Gui_RECT.OwnProps() {
dist := Distance(corner, neighborCorner)
if (dist <= SnapRange) {
shouldMove := true
destX := neighborCorner[1] - (corner = A_RECT.TR || corner = A_RECT.BR ? Width : 0)
destY := neighborCorner[2] - (corner = A_RECT.BL || corner = A_RECT.BR ? Height : 0)
}
}
}
}
if (shouldMove) {
for k, v in This.ThumbWindows.%This.ThumbHwnd_EvEHwnd[hwnd]%
WinMove(destX, destY, , , v.Hwnd)
}
}
Distance(pt1, pt2) {
return Sqrt((pt1[1] - pt2[1]) ** 2 + (pt1[2] - pt2[2]) ** 2)
}
}
ShowThumb(EVEWindowHwnd, HideOrShow) {
try
title := WinGetTitle("Ahk_Id " EVEWindowHwnd)
catch
title := 0
if (!This.Thumbnail_visibility.Has(This.CleanTitle(title))) {
if (HideOrShow = "Show") {
for k, v in This.ThumbWindows.%EVEWindowHwnd% {
if (k = "Thumbnail")
continue
if (k = "Border" && !This.ShowAllColoredBorders)
continue
This.ThumbWindows.%EVEWindowHwnd%[k].Show("NoActivate")
if (k = "TextOverlay" && !This.ShowThumbnailTextOverlay)
This.ThumbWindows.%EVEWindowHwnd%["TextOverlay"].Show("Hide")
else if (k = "TextOverlay" && This.ShowThumbnailTextOverlay)
This.ThumbWindows.%EVEWindowHwnd%["TextOverlay"].Show("NoActivate")
}
}
else {
if (This.ThumbWindows.%EVEWindowHwnd%["Window"].Title = "") {
This.ThumbWindows.%EVEWindowHwnd%["Border"].Show("Hide")
return
}
for k, v in This.ThumbWindows.%EVEWindowHwnd% {
if (k = "Thumbnail")
continue
This.ThumbWindows.%EVEWindowHwnd%[k].Show("Hide")
}
}
}
}
Update_Thumb(AllOrOne := true, ThumbHwnd?) {
If (AllOrOne && !IsSet(ThumbHwnd)) {
for EvEHwnd, ThumbObj in This.ThumbWindows.OwnProps() {
for Name, Obj in ThumbObj {
if (Name = "Window") {
WinGetPos(, , &TWidth, &THeight, Obj.Hwnd)
WinGetClientPos(, , &EWidth, &EHeight, "Ahk_Id" EvEHwnd)
ThumbObj["Thumbnail"].Source := [0, 0, EWidth, EHeight]
ThumbObj["Thumbnail"].Destination := [0, 0, TWidth, THeight]
ThumbObj["Thumbnail"].Update()
}
}
}
}
else {
If (IsSet(ThumbHwnd)) {
WinGetPos(, , &TWidth, &THeight, ThumbHwnd)
WinGetClientPos(, , &EWidth, &EHeight, This.ThumbHwnd_EvEHwnd[ThumbHwnd])
ThumbObj := This.ThumbWindows.%This.ThumbHwnd_EvEHwnd[ThumbHwnd]%
ThumbObj["Thumbnail"].Source := [0, 0, EWidth, EHeight]
ThumbObj["Thumbnail"].Destination := [0, 0, TWidth, THeight]
ThumbObj["Thumbnail"].Update()
}
}
}
ShowActiveBorder(EVEHwnd?, ThumbHwnd?) {
If (IsSet(EVEHwnd) && This.ThumbWindows.HasProp(EVEHwnd)) {
Win_Title := This.CleanTitle(WinGetTitle("Ahk_Id " EVEHwnd))
for EW_Hwnd, Objs in This.ThumbWindows.OwnProps() {
for names, GuiObj in Objs {
if (names = "Border") {
if ((!This.ShowAllColoredBorders && !This.ShowClientHighlightBorder) || (!This.ShowAllColoredBorders && This.ShowClientHighlightBorder)) {
GuiObj.Show("Hide")
}
else {
if (This.ThumbWindows.%EW_Hwnd%["Window"].Name = Win_Title)
continue
else if (!This.CustomColorsActive && This.ShowAllColoredBorders) {
try
This.ThumbWindows.%EW_Hwnd%["Border"].BackColor := This.InactiveClientBorderColor
catch
This.ThumbWindows.%EW_Hwnd%["Border"].BackColor := "8A8A8A"
This.BorderSize(This.ThumbWindows.%EW_Hwnd%["Window"].Hwnd, This.ThumbWindows.%EW_Hwnd%["Border"].Hwnd, This.InactiveClientBorderthickness)
}
else if (This.CustomColorsActive && This.ShowAllColoredBorders) {
title := This.CleanTitle(WinGetTitle("Ahk_Id " EW_Hwnd))
if (This.CustomColorsGet[title]["Char"] != "" && This.CustomColorsGet[title]["IABorder"] != "") {
try
This.ThumbWindows.%EW_Hwnd%["Border"].BackColor := This.CustomColorsGet[title]["IABorder"]
catch
This.ThumbWindows.%EW_Hwnd%["Border"].BackColor := "8A8A8A"
}
else {
try
This.ThumbWindows.%EW_Hwnd%["Border"].BackColor := This.InactiveClientBorderColor
catch
This.ThumbWindows.%EW_Hwnd%["Border"].BackColor := "8A8A8A"
}
This.BorderSize(This.ThumbWindows.%EW_Hwnd%["Window"].Hwnd, This.ThumbWindows.%EW_Hwnd%["Border"].Hwnd, This.InactiveClientBorderthickness)
}
}
}
}
}
if (!This.Thumbnail_visibility.Has(Win_Title) && This.ShowClientHighlightBorder) {
if (This.CustomColorsActive && This.CustomColorsGet[Win_Title]["Char"] != "" && This.CustomColorsGet[Win_Title]["Border"] != "") {
This.ThumbWindows.%EVEHwnd%["Border"].BackColor := This.CustomColorsGet[Win_Title]["Border"]
This.BorderSize(This.ThumbWindows.%EVEHwnd%["Window"].Hwnd, This.ThumbWindows.%EVEHwnd%["Border"].Hwnd, This.ClientHighligtBorderthickness)
}
else {
This.ThumbWindows.%EVEHwnd%["Border"].BackColor := This.ClientHighligtColor
This.BorderSize(This.ThumbWindows.%EVEHwnd%["Window"].Hwnd, This.ThumbWindows.%EVEHwnd%["Border"].Hwnd, This.ClientHighligtBorderthickness)
}
This.ThumbWindows.%EVEHwnd%["Border"].Show("NoActivate")
}
}
}
}
Class TrayMenu extends Settings_Gui {
TrayMenuObj := A_TrayMenu
Saved_overTray := 0
Tray_Profile_scwitch := 0
TrayMenu() {
Profiles_Submenu := Menu()
for k in This.Profiles {
If (k = This.LastUsedProfile) {
Profiles_Submenu.Add(This.LastUsedProfile, MenuHandler)
Profiles_Submenu.Check(This.LastUsedProfile)
}
Profiles_Submenu.Add(k, MenuHandler)
}
TrayMenu := This.TrayMenuObj
TrayMenu.Delete()
TrayMenu.Add("Open", MenuHandler)
TrayMenu.Add()
TrayMenu.Add("Profiles", Profiles_Submenu)
TrayMenu.Add()
TrayMenu.Add("Suspend Hotkeys", MenuHandler)
TrayMenu.Add()
TrayMenu.Add()
TrayMenu.Add("Close all EVE Clients", (*) => This.CloseAllEVEWindows())
TrayMenu.Add()
TrayMenu.Add()
TrayMenu.Add("Restore Client Positions", MenuHandler)
if (This.TrackClientPossitions)
TrayMenu.check("Restore Client Positions")
else
TrayMenu.Uncheck("Restore Client Positions")
TrayMenu.Add("Save Client Positions", (*) => This.Client_Possitions())
TrayMenu.Add()
TrayMenu.Add()
TrayMenu.Add("Save Thumbnail Positions", MenuHandler)
TrayMenu.Add("Reload", (*) => Reload())
TrayMenu.Add()
TrayMenu.Add("Exit", (*) => ExitApp())
TrayMenu.Default := "Open"
MenuHandler(ItemName, ItemPos, MyMenu) {
If (ItemName = "Exit")
ExitApp
Else if (ItemName = "Save Thumbnail Positions") {
This.Save_ThumbnailPossitions
}
Else if (ItemName = "Restore Client Positions") {
This.TrackClientPossitions := !This.TrackClientPossitions
TrayMenu.ToggleCheck("Restore Client Positions")
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
Else if (This.Profiles.Has(ItemName)) {
This.LastUsedProfile := ItemName
This.SaveJsonToFile()
Sleep(500)
Reload()
}
Else if (ItemName = "Open") {
if WinExist("EVE-X-Preview - Settings") {
WinActivate("EVE-X-Preview - Settings")
Return
}
This.MainGui()
}
Else If (ItemName = "Suspend Hotkeys") {
Suspend(-1)
TrayMenu.ToggleCheck("Suspend Hotkeys")
}
}
}
CloseAllEVEWindows(*) {
try {
list := WinGetList("Ahk_Exe exefile.exe")
GroupAdd("EVE", "Ahk_Exe exefile.exe")
for k in list {
PostMessage 0x0112, 0xF060, , , k
Sleep(50)
}
}
}
}
class Propertys extends TrayMenu {
SetThumbnailText[hwnd, *] {
set {
if (This.ThumbWindows.HasProp(hwnd)) {
newtext := Value
for k, v in This.ThumbWindows.%hwnd% {
if (k = "Thumbnail" || k = "Border")
continue
if (k = "TextOverlay") {
for chwnd, cobj in v {
cobj.Value := newtext
}
}
if (k = "Window")
v.Title := newtext
}
}
}
}
Profiles => This._JSON["_Profiles"]
ThumbnailStartLocation[key] {
get => This._JSON["global_Settings"]["ThumbnailStartLocation"][key]
set => This._JSON["global_Settings"]["ThumbnailStartLocation"][key] := value
}
Minimizeclients_Delay {
get => This._JSON["global_Settings"]["Minimize_Delay"]
set => This._JSON["global_Settings"]["Minimize_Delay"] := (value < 50 ? "50" : value)
}
Suspend_Hotkeys_Hotkey {
get => This._JSON["global_Settings"]["Suspend_Hotkeys_Hotkey"]
set => This._JSON["global_Settings"]["Suspend_Hotkeys_Hotkey"] := value
}
ThumbnailBackgroundColor {
get => convertToHex(This._JSON["global_Settings"]["ThumbnailBackgroundColor"])
set => This._JSON["global_Settings"]["ThumbnailBackgroundColor"] := convertToHex(value)
}
ThumbnailSnap[*] {
get => This._JSON["global_Settings"]["ThumbnailSnap"]
set => This._JSON["global_Settings"]["ThumbnailSnap"] := Value
}
Global_Hotkeys {
get => This._JSON["global_Settings"]["Global_Hotkeys"]
set => This._JSON["global_Settings"]["Global_Hotkeys"] := value
}
ThumbnailSnap_Distance {
get => This._JSON["global_Settings"]["ThumbnailSnap_Distance"]
set => This._JSON["global_Settings"]["ThumbnailSnap_Distance"] := (value ? value : "20")
}
ThumbnailMinimumSize[key] {
get => This._JSON["global_Settings"]["ThumbnailMinimumSize"][key]
set => This._JSON["global_Settings"]["ThumbnailMinimumSize"][key] := value
}
ShowAllColoredBorders {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ShowAllColoredBorders"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ShowAllColoredBorders"] := value
}
LastUsedProfile {
get => This._JSON["global_Settings"]["LastUsedProfile"]
set => This._JSON["global_Settings"]["LastUsedProfile"] := value
}
_ProfileProps {
get {
Arr := []
for k in This._JSON["_Profiles"][This.LastUsedProfile] {
If (k = "Thumbnail Positions" || k = "Client Possitions")
continue
Arr.Push(k)
}
return Arr
}
}
Thumbnail_visibility[key?] {
get {
return This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Visibility"]
}
set {
if (IsObject(value)) {
This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Visibility"] := value
}
This.Save_Settings()
}
}
HideThumbnailsOnLostFocus {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["HideThumbnailsOnLostFocus"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["HideThumbnailsOnLostFocus"] := value
}
ShowThumbnailsAlwaysOnTop {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ShowThumbnailsAlwaysOnTop"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ShowThumbnailsAlwaysOnTop"] := value
}
ThumbnailOpacity {
get {
percentage := This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailOpacity"]
return Round((percentage < 0 ? 0 : percentage > 100 ? 100 : percentage) * 2.55)
}
set {
This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailOpacity"] := Value
}
}
ClientHighligtBorderthickness {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ClientHighligtBorderthickness"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ClientHighligtBorderthickness"] := (Trim(value, "`n ") <= 0 ? 1 : Trim(value, "`n "))
}
ClientHighligtColor {
get => convertToHex(This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ClientHighligtColor"])
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ClientHighligtColor"] := convertToHex(Trim(value, "`n "))
}
ShowClientHighlightBorder {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ShowClientHighlightBorder"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ShowClientHighlightBorder"] := value
}
ThumbnailTextFont {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailTextFont"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailTextFont"] := Trim(value, "`n ")
}
ThumbnailTextSize {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailTextSize"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailTextSize"] := Trim(value, "`n ")
}
ThumbnailTextColor {
get => convertToHex(This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailTextColor"])
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailTextColor"] := convertToHex(Trim(value, "`n "))
}
ShowThumbnailTextOverlay {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ShowThumbnailTextOverlay"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ShowThumbnailTextOverlay"] := value
}
ThumbnailTextMargins[var] {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailTextMargins"][var]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["ThumbnailTextMargins"][var] := Trim(value, "`n ")
}
InactiveClientBorderthickness {
get {
if ( !This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"].Has("InactiveClientBorderthickness") )
This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["InactiveClientBorderthickness"] := "2"
return This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["InactiveClientBorderthickness"]
}
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["InactiveClientBorderthickness"] := (Trim(value, "`n ") <= 0 ? 1 : Trim(value, "`n "))
}
InactiveClientBorderColor {
get {
if ( !This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"].Has("InactiveClientBorderColor") )
This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["InactiveClientBorderColor"] := "#8A8A8A"
return convertToHex(This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["InactiveClientBorderColor"])
}
set => This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Settings"]["InactiveClientBorderColor"] := convertToHex(Trim(value, "`n "))
}
CustomColorsGet[CName?] {
get {
name := "", nameIndex := 0, ctext := "", cBorder := "", cIABorder := ""
for index, names in This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["CharNames"] {
if (names = CName) {
nameIndex := index
name := names
break
}
else
nameIndex := index
}
if (nameIndex) {
if (This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["Bordercolor"].Length >= nameIndex) {
cBorder := This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["Bordercolor"][nameIndex]
}
if (This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["TextColor"].Length >= nameIndex)
ctext := This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["TextColor"][nameIndex]
if (This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["IABordercolor"].Length >= nameIndex)
cIABorder := This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["IABordercolor"][nameIndex]
}
return Map("Char", name, "Border", cBorder, "Text", ctext, "IABorder", cIABorder)
}
}
IndexcChars => This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["CharNames"].Length
IndexcBorder => This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["Bordercolor"].Length
IndexcText => This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["TextColor"].Length
IndexcIABorders => This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["IABordercolor"].Length
CustomColors_AllCharNames {
get {
names := ""
for k, v in This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["CharNames"] {
if (A_Index < This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["CharNames"].Length)
names .= k ": " v "`n"
else
names .= k ": " v
}
return names
}
set {
tempvar := []
ListChars := StrSplit(value, "`n")
for k, v in ListChars {
chars := RegExReplace(This.CleanTitle(Trim(v, "`n ")), ".*:\s*", "")
tempvar.Push(chars)
}
This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["CharNames"] := tempvar
}
}
CustomColors_AllBColors {
get {
names := ""
for k, v in This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["Bordercolor"] {
if (A_Index < This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["Bordercolor"].Length)
names .= k ": " v "`n"
else
names .= k ": " v
}
return names
}
set {
tempvar := []
ListChars := StrSplit(value, "`n")
for k, v in ListChars {
chars := RegExReplace(Trim(v, "`n "), ".*:\s*", "")
tempvar.Push(convertToHex(chars))
}
This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["Bordercolor"] := tempvar
}
}
CustomColors_AllTColors {
get {
names := ""
for k, v in This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["TextColor"] {
if (A_Index < This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["TextColor"].Length)
names .= k ": " v "`n"
else
names .= k ": " v
}
return names
}
set {
tempvar := []
ListChars := StrSplit(value, "`n")
for k, v in ListChars {
chars := RegExReplace(Trim(v, "`n "), ".*:\s*", "")
tempvar.Push(convertToHex(chars))
}
This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["TextColor"] := tempvar
}
}
CustomColors_IABorder_Colors {
get {
names := ""
if (!This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"].Has("IABordercolor")) {
This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["IABordercolor"] := ["FFFFFF"]
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
for k, v in This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["IABordercolor"] {
if (A_Index < This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["IABordercolor"].Length)
names .= k ": " v "`n"
else
names .= k ": " v
}
return names
}
set {
tempvar := []
ListChars := StrSplit(value, "`n")
for k, v in ListChars {
chars := RegExReplace(Trim(v, "`n "), ".*:\s*", "")
tempvar.Push(convertToHex(chars))
}
This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColors"]["IABordercolor"] := tempvar
}
}
CustomColorsActive {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColorActive"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Custom Colors"]["cColorActive"] := Value
}
MinimizeInactiveClients {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["MinimizeInactiveClients"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["MinimizeInactiveClients"] := value
}
AlwaysMaximize {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["AlwaysMaximize"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["AlwaysMaximize"] := value
}
TrackClientPossitions {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["TrackClientPossitions"]
set => This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["TrackClientPossitions"] := value
}
Dont_Minimize_Clients {
get => This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["Dont_Minimize_Clients"]
set {
This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["Dont_Minimize_Clients"] := []
For index, Client in StrSplit(Value, ["`n", ","]) {
if (Client = "")
continue
This._JSON["_Profiles"][This.LastUsedProfile]["Client Settings"]["Dont_Minimize_Clients"].Push(Trim(Client, "`n "))
}
}
}
ThumbnailPositions[wTitle?] {
get {
if (IsSet(wTitle))
return This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Positions"][wTitle]
return This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Positions"]
}
set {
form := ["x", "y", "width", "height"]
if !(This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Positions"].Has(wTitle))
This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Positions"][wTitle] := Map()
for v in form {
This._JSON["_Profiles"][This.LastUsedProfile]["Thumbnail Positions"][wTitle][v] := value[A_Index]
}
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
}
ClientPossitions[wTitle] {
get {
if (This._JSON["_Profiles"][This.LastUsedProfile]["Client Possitions"].Has(wTitle))
return This._JSON["_Profiles"][This.LastUsedProfile]["Client Possitions"][wTitle]
else
return 0
}
set {
form := ["x", "y", "width", "height", "IsMaximized"]
if !(This._JSON["_Profiles"][This.LastUsedProfile]["Client Possitions"].Has(wTitle))
This._JSON["_Profiles"][This.LastUsedProfile]["Client Possitions"][wTitle] := Map()
for v in form {
This._JSON["_Profiles"][This.LastUsedProfile]["Client Possitions"][wTitle][v] := value[A_Index]
}
}
}
Hotkey_Groups[key?] {
get {
if (IsSet(key)) {
return This._JSON["_Profiles"][This.LastUsedProfile]["Hotkey Groups"][key]
}
else
return This._JSON["_Profiles"][This.LastUsedProfile]["Hotkey Groups"]
}
set {
This._JSON["_Profiles"][This.LastUsedProfile]["Hotkey Groups"][Key] := Map("Characters", value, "ForwardsHotkey", "", "BackwardsHotkey", "")
}
}
_Hotkeys[key?] {
get {
if (IsSet(Key)) {
loop This._JSON["_Profiles"][This.LastUsedProfile]["Hotkeys"].Length {
if (This._JSON["_Profiles"][This.LastUsedProfile]["Hotkeys"][A_Index].Has(key)) {
return This._JSON["_Profiles"][This.LastUsedProfile]["Hotkeys"][A_Index][key]
}
}
return 0
}
if !(IsSet(Key))
return This._JSON["_Profiles"][This.LastUsedProfile]["Hotkeys"]
}
set => This._JSON["_Profiles"][This.LastUsedProfile]["Hotkeys"] := Value
}
_Hotkey_Delete(*) {
if (This.LV_Item) {
try {
HKey_Char_Name := This.LV.GetText(This.LV_Item)
if (This._Hotkeys.Has(HKey_Char_Name)) {
This._Hotkeys.Delete(HKey_Char_Name)
This.LV.Delete(This.LV_Item)
}
}
}
}
_Hotkey_Add(*) {
Obj := InputBox("Enter the Char Name", "Add New Char", "w200 h90")
if (Obj.Result = "OK") {
This._Hotkeys[Trim(Obj.Value, " ")] := ""
This.LV.Add(, Trim(Obj.Value, " "))
}
}
_Hotkey_Edit(*) {
if (This.LV_Item) {
HKey_Char_Key := This.LV.GetText(This.LV_Item, 2), HKey_Char_Name := This.LV.GetText(This.LV_Item)
if (This._Hotkeys.Has(HKey_Char_Name)) {
Obj := InputBox(HKey_Char_Key, "Edit Hotkey for -> " HKey_Char_Name, "w250 h100")
if (Obj.Result = "OK") {
This._Hotkeys[HKey_Char_Name] := Trim(Obj.Value, " ")
This.LV.Modify(This.LV_Item, , , Trim(Obj.Value, " "))
This.LV.Modify(This.LV_Item, "+Focus +Select")
}
}
}
}
_Tv_LVSelectedRow(GuiCtrlObj, Item, Checked) {
Obj := Map()
if (GuiCtrlObj == This.Tv_LV) {
loop {
RowNumber := This.Tv_LV.GetNext(A_Index - 1, "Checked")
if not RowNumber
break
Obj[This.Tv_LV.GetText(RowNumber)] := 1
This.Thumbnail_visibility[This.Tv_LV.GetText(RowNumber)] := 1
}
This.Thumbnail_visibility := Obj
SetTimer(This.Save_Settings_Delay_Timer, -200)
This.NeedRestart := 1
}
}
_LVSelectedRow(GuiCtrlObj, Item, Selected) {
if (GuiCtrlObj == This.LV && Selected) {
This.LV_Item := Item
ddd := GuiCtrlObj.GetText(Item)
}
}
Suspend_Hotkeys(*) {
static state := 0
ToolTip()
state := !state
state ? ToolTip("Hotkeys disabled") : ToolTip("Hotkeys enabled")
Suspend(-1)
SetTimer((*) => ToolTip(), -1500)
}
Delete_Profile(*) {
if (This.SelectProfile_DDL.Text = "Default") {
MsgBox("You cannot delete the default settings")
Return
}
if (This.SelectProfile_DDL.Text = This.LastUsedProfile) {
This.LastUsedProfile := "Default"
}
This._JSON["_Profiles"].Delete(This.SelectProfile_DDL.Text)
if (This.LastUsedProfile = "" || !This.Profiles.Has(This.LastUsedProfile))
This.LastUsedProfile := "Default"
SetTimer(This.Save_Settings_Delay_Timer, -200)
This.SelectProfile_DDL.Delete(This.SelectProfile_DDL.Value)
This.SelectProfile_DDL.Redraw()
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL {
for _, ob in v {
ob.Enabled := 0
}
}
}
Create_Profile(*) {
Obj := InputBox("Enter a Profile Name", "Create New Profile", "w200 h90")
if (Obj.Result != "OK" || Obj.Result = "")
return
if (This.Profiles.Has(Obj.value)) {
MsgBox("A profile with this name already exists")
return
}
if !(This.LastUsedProfile = "Default") {
Result := MsgBox("Do you want to use the current settings for the new profile?", , "YesNo")
}
else
Result := "No"
if Result = "Yes"
This._JSON["_Profiles"][Obj.value] := JSON.Load(FileRead("EVE-X-Preview.json"))["_Profiles"][This.LastUsedProfile]
else if Result = "No"
This._JSON["_Profiles"][Obj.value] := This.default_JSON["_Profiles"]["Default"]
else
Return 0
FileDelete("EVE-X-Preview.json")
FileAppend(JSON.Dump(This._JSON, , "    "), "EVE-X-Preview.json")
This.SelectProfile_DDL.Delete()
This.SelectProfile_DDL.Add(This.Profiles_to_Array())
ControlChooseString(Obj.value, This.SelectProfile_DDL, "EVE-X-Preview - Settings")
This.LastUsedProfile := Obj.value
Return
}
Save_ThumbnailPossitions() {
for EvEHwnd, GuiObj in This.ThumbWindows.OwnProps() {
for Names, Obj in GuiObj {
if (Names = "Window" && Obj.Title = "" || Obj.Title = "EVE")
continue
Else if (Names = "Window") {
WinGetPos(&wX, &wY, &wWidth, &wHeight, Obj.Hwnd)
This.ThumbnailPositions[Obj.Title] := [wX, wY, wWidth, wHeight]
}
}
}
}
Save_Settings() {
for EvEHwnd, GuiObj in This.ThumbWindows.OwnProps() {
for Names, Obj in GuiObj {
if (Names = "Window" && Obj.Title = "" || Obj.Title = "EVE")
continue
Else if (Names = "Window") {
WinGetPos(&wX, &wY, &wWidth, &wHeight, Obj.Hwnd)
This.ThumbnailPositions[Obj.Title] := [wX, wY, wWidth, wHeight]
}
}
}
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
}
Add_New_Profile() {
return
}
convertToHex(rgbString) {
if (RegExMatch(rgbString, "^\s*(rgb\s*\(?)?\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)?\s*$", &matches)) {
red := matches[2], green := matches[3], blue := matches[4]
hexValue := Format("{:02X}{:02X}{:02X}", red, green, blue)
return hexValue
}
if (RegExMatch(rgbString, "^\s*(#|0x)?([0-9A-Fa-f]{6})\s*$", &matches)) {
hexValue := matches[2]
hexValue := StrLower(hexValue)
return hexValue
}
return rgbString
}
Class Settings_Gui {
MainGui() {
This.NeedRestart := 0
SetControlDelay(-1)
This.S_Gui := Gui("+OwnDialogs +MinimizeBox -Resize -MaximizeBox SysMenu +MinSize500x250")
This.S_Gui.Title := "EVE-X-Preview - Settings"
This.S_Gui.SetFont("s10 w700")
This.S_Gui.MarginX := 80, This.S_Gui.MarginY := 20
This.S_Gui.Add("Button", " x140 y20 w120 h40 vGlobal_Settings", "Global Settings").OnEvent("Click", (obj, *) => Button_Handler(obj))
This.S_Gui.Add("Button", "x+40 y+-40 wp hp vProfile_Settings", "Profile Settings").OnEvent("Click", (obj, *) => Button_Handler(obj))
This.S_Gui.Show("hide")
This.S_Gui.Controls := [], This.S_Gui.ClientSettings := []
This.S_Gui.MarginX := 25
This.S_Gui.SetFont("s9 w400")
This.Global_Settings(), This.Profile_Settings(), This.ClientSettings_Ctrl(), This.Custom_ColorsCtrl()
This.Hotkey_GroupsCtrl(), This.HotkeysCtrl(), This.ThumbnailSettings_Ctrl(), This.Thumbnail_visibilityCtrl()
This.S_Gui.Show("AutoSize Center")
This._Button_Load()
This.Seetings_DDL.OnEvent("Change", (Obj, *) => SettingsDDL_Handler(Obj))
This.S_Gui.OnEvent("Close", (*) => GuiDestroy())
GuiDestroy(*) {
This.S_Gui.Destroy()
if (This.NeedRestart)
Reload()
}
SettingsDDL_Handler(Obj) {
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL {
if k = Obj.Text {
for _, ob in v
ob.Visible := 1
}
else {
for _, ob in v
ob.Visible := 0
}
}
This.S_Gui.Show("AutoSize")
}
Button_Handler(obj) {
if (obj.Name = "Global_Settings") {
for ButtonName, Controls in This.S_Gui.Controls.OwnProps() {
if ButtonName = obj.Name {
for _, Ctrl in Controls {
Ctrl.Visible := 1
}
}
else {
for _, Ctrl in Controls {
Ctrl.Visible := 0
}
for _, Ctrl in This.S_Gui.Controls.Profile_Settings.PsDDL {
for k, v in Ctrl
v.Visible := 0
}
}
}
}
else if (obj.Name = "Profile_Settings") {
for ButtonName, Controls in This.S_Gui.Controls.OwnProps() {
if ButtonName = obj.Name {
for _, Ctrl in Controls {
Ctrl.Visible := 1
}
for _, Ctrl in This.S_Gui.Controls.Profile_Settings.PsDDL {
if (This.Seetings_DDL.Text = _) {
for k, v in Ctrl {
v.Visible := 1
}
}
}
}
else {
for _, Ctrl in Controls {
Ctrl.Visible := 0
}
}
}
if (This.Profiles.Count = 1 && This.SelectProfile_DDL.Text = "Default")
MsgBox("you need create a profile first to change the settings")
}
This.S_Gui.Show("AutoSize")
}
}
Global_Settings(visible?) {
This.S_Gui.Controls.Global_Settings := []
This.S_Gui.SetFont("s10 w400")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("GroupBox", "x20 y80 h280 w500")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xp+15 yp+20 Section", "Suspend Hotkeys - Hotkey:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+15", "Hotkey activation Scope:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+15", "Thumbnail Background Color:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+15", "Thumbnail Default Location:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+15", "Thumbnail Minimum Size:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+15", "Thumbnail Snap:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+15", "Thumbnail Snap Distance:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+15", "Minimize EVE Window Delay:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "xs+230 ys-3 w150 Section vSuspend_Hotkeys_Hotkey", This.Suspend_Hotkeys_Hotkey)
This.S_Gui["Suspend_Hotkeys_Hotkey"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("DDL", "xp y+5 w180 vTTT vHotkey_Scoope Choose" (This.Global_Hotkeys ? 1 : 2), ["Global", "If an EVE window is Active"])
This.S_Gui["Hotkey_Scoope"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "xp y+5 w120 section vThumbnailBackgroundColor", This.ThumbnailBackgroundColor)
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xp+130 yp+4", "Hex or RGB")
This.S_Gui["ThumbnailBackgroundColor"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs+2 y+17 section", "x:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "x+5 y+-18 w40 vThumbnailStartLocationx", This.ThumbnailStartLocation["x"])
This.S_Gui["ThumbnailStartLocationx"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "x+8 ys ", "y:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "x+5 y+-18 w40 vThumbnailStartLocationy", This.ThumbnailStartLocation["y"])
This.S_Gui["ThumbnailStartLocationy"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "x+8 ys ", "w:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "x+5 y+-18 w40 vThumbnailStartLocationwidth", This.ThumbnailStartLocation["width"])
This.S_Gui["ThumbnailStartLocationwidth"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "x+8 ys ", "h:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "x+5 y+-18 w40 vThumbnailStartLocationheight", This.ThumbnailStartLocation["height"])
This.S_Gui["ThumbnailStartLocationheight"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+10 section ", "width:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "x+5 y+-18 w40 vThumbnailMinimumSizewidth", This.ThumbnailMinimumSize["width"])
This.S_Gui["ThumbnailMinimumSizewidth"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "x+8 ys ", "height:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "x+5 y+-18 w40 vThumbnailMinimumSizeheight", This.ThumbnailMinimumSize["height"])
This.S_Gui["ThumbnailMinimumSizeheight"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Radio", "xs y+10 w37 vThumbnailSnapOn Checked" This.ThumbnailSnap, "On")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Radio", " xp+50 yp w37 vThumbnailSnapOff Checked" (This.ThumbnailSnap ? 0 : 1), "Off")
This.S_Gui["ThumbnailSnapOn"].OnEvent("Click", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui["ThumbnailSnapOff"].OnEvent("Click", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+15 ", "pixel:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "x+5 y+-18 w40 vThumbnailSnap_Distance", This.ThumbnailSnap_Distance)
This.S_Gui["ThumbnailSnap_Distance"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Text", "xs y+9 ", "Milliseconds:")
This.S_Gui.Controls.Global_Settings.Push This.S_Gui.Add("Edit", "xp+80 yp-3 w40 vMinimizeclients_Delay", This.Minimizeclients_Delay)
This.S_Gui["Minimizeclients_Delay"].OnEvent("Change", (obj, *) => gSettings_EventHandler(obj))
gSettings_EventHandler(obj) {
if (obj.name = "Suspend_Hotkeys_Hotkey") {
This.Suspend_Hotkeys_Hotkey := Trim(obj.value, "`n ")
This.NeedRestart := 1
}
else if (obj.name = "Hotkey_Scoope") {
This.Global_Hotkeys := (obj.value = 1 ? 1 : 0)
This.NeedRestart := 1
}
else if (obj.name = "ThumbnailBackgroundColor") {
This.ThumbnailBackgroundColor := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ThumbnailStartLocationx") {
This.ThumbnailStartLocation["x"] := obj.value
}
else if (obj.name = "ThumbnailStartLocationy") {
This.ThumbnailStartLocation["y"] := obj.value
}
else if (obj.name = "ThumbnailStartLocationwidth") {
This.ThumbnailStartLocation["width"] := obj.value
}
else if (obj.name = "ThumbnailStartLocationheight") {
This.ThumbnailStartLocation["height"] := obj.value
}
else if (obj.name = "ThumbnailMinimumSizewidth") {
This.ThumbnailMinimumSize["width"] := obj.value
}
else if (obj.name = "ThumbnailMinimumSizeheight") {
This.ThumbnailMinimumSize["height"] := obj.value
}
else if (obj.name = "ThumbnailSnapOn") {
This.ThumbnailSnap := 1
}
else if (obj.name = "ThumbnailSnapOff") {
This.ThumbnailSnap := 0
}
else if (obj.name = "ThumbnailSnap_Distance") {
This.ThumbnailSnap_Distance := obj.value
}
else if (obj.name = "Minimizeclients_Delay") {
This.Minimizeclients_Delay := obj.value
This.NeedRestart := 1
}
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
}
Profile_Settings(visible?) {
This.S_Gui.Controls.Profile_Settings := [], This.S_Gui.Controls.Profile_Settings.PsDDL := Map()
This.S_Gui.Controls.Profile_Settings.Push This.S_Gui.Add("Text", "x58 y95", "Select Profile:")
This.SelectProfile_DDL := This.S_Gui.Add("DDL", "w200 xp-30 yp+18 Section vSelectedProfile", This.Profiles_to_Array())
This.S_Gui.Controls.Profile_Settings.Push This.SelectProfile_DDL
This.SelectProfile_DDL.Choose(This.LastUsedProfile)
This.SelectProfile_DDL.OnEvent("Change", (obj,*) => This._Button_Load(Obj))
Button_Delete := This.S_Gui.Add("Button", "w60 xs+360 yp-2 ", "Delete")
This.S_Gui.Controls.Profile_Settings.Push Button_Delete
Button_Delete.OnEvent("Click", ObjBindMethod(This, "Delete_Profile"))
Button_New := This.S_Gui.Add("Button", "wp x+5 yp ", "New")
This.S_Gui.Controls.Profile_Settings.Push Button_New
Button_New.OnEvent("Click", ObjBindMethod(This, "Create_Profile"))
This.Seperator_text := This.S_Gui.Add("Text", "xs+15 y+5 w460 h2 +0x10")
This.S_Gui.Controls.Profile_Settings.Push This.Seperator_text
This.S_Gui.Controls.Profile_Settings.Push This.S_Gui.Add("Text", "xp+190 y+5", "Profile Settings:")
This.Seetings_DDL := This.S_Gui.Add("DDL", "w180 xp-40 y+5 vSeetings_Props", This._ProfileProps)
This.Seetings_DDL.Choose(1)
This.S_Gui.Controls.Profile_Settings.Push This.Seetings_DDL
This.S_Gui.Controls.Profile_Settings.Push This.S_Gui.Add("Text", "x150 yp+30 w260 h2 Section +0x10")
for k, v in This.S_Gui.Controls.Profile_Settings
v.Visible := 0
}
ClientSettings_Ctrl(visible?) {
This.S_Gui.Controls.Profile_Settings.PsDDL["Client Settings"] := [], ClientSettings := []
ClientSettings.Push This.S_Gui.Add("GroupBox", "x20 y80 h400 w500 Section", "")
ClientSettings.Push This.S_Gui.Add("Text", " xp+15 yp+140 Section ", "Minimize Inactive Clients:")
ClientSettings.Push This.S_Gui.Add("Text", "xs y+15 ", "Always Maximize Clients:")
ClientSettings.Push This.S_Gui.Add("Text", "xs y+15 ", "Dont Minimize Clients:")
ClientSettings.Push This.S_Gui.Add("CheckBox", "xs+230 ys Section vMinimizeInactiveClients Checked" This.MinimizeInactiveClients, "On/Off")
This.S_Gui["MinimizeInactiveClients"].OnEvent("Click", (obj, *) => cSettings_EventHandler(obj))
ClientSettings.Push This.S_Gui.Add("CheckBox", "xs y+15 vAlwaysMaximize Checked" This.AlwaysMaximize, "On/Off")
This.S_Gui["AlwaysMaximize"].OnEvent("Click", (obj, *) => cSettings_EventHandler(obj))
ClientSettings.Push This.S_Gui.Add("Edit", "xs y+15 w220 h180 vDont_Minimize_Clients -Wrap", This.Dont_Minimize_List())
This.S_Gui["Dont_Minimize_Clients"].OnEvent("Change", (obj, *) => cSettings_EventHandler(obj))
This.S_Gui.Controls.Profile_Settings.PsDDL["Client Settings"] := ClientSettings
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL["Client Settings"]
v.Visible := 0
cSettings_EventHandler(obj) {
if (obj.name = "MinimizeInactiveClients") {
This.MinimizeInactiveClients := obj.value
}
else if (obj.name = "AlwaysMaximize") {
This.AlwaysMaximize := obj.value
}
else if (obj.name = "TrackClientPossitions") {
This.TrackClientPossitions := obj.value
}
else if (obj.name = "Dont_Minimize_Clients") {
This.Dont_Minimize_Clients := obj.value
}
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
}
Custom_ColorsCtrl() {
This.S_Gui.Controls.Profile_Settings.PsDDL["Custom Colors"] := [], CustomColors := []
CustomColors.Push This.S_Gui.Add("GroupBox", "x20 y80 h480 w565 Section", "")
CustomColors.Push This.S_Gui.Add("Text", " xp+25 yp+140 Section ", "Custom Colors Active - On/Off")
CustomColors.Push This.S_Gui.Add("Text", " x35 yp+40  ", "Character Name:")
CustomColors.Push This.S_Gui.Add("Text", " xp+155 yp ", "Active Border Color:")
CustomColors.Push This.S_Gui.Add("Text", " xp+135 yp ", "Text Color:")
CustomColors.Push This.S_Gui.Add("Text", " xp+125 yp ", "Inactive Border Color:")
CustomColors.Push This.S_Gui.Add("CheckBox", " xs+200 ys vCcoloractive Checked" This.CustomColorsActive, " ON / Off")
This.S_Gui["Ccoloractive"].OnEvent("Click", (obj, *) => Cclors_Eventhandler(obj))
CustomColors.Push This.S_Gui.Add("Edit", " x30 yp+60 w150 h250 -Wrap vCchars", This.CustomColors_AllCharNames)
This.S_Gui["Cchars"].OnEvent("Change", (obj, *) => Cclors_Eventhandler(obj))
CustomColors.Push This.S_Gui.Add("Edit", " x+10 yp w120 hp -Wrap vCBorderColor", This.CustomColors_AllBColors)
This.S_Gui["CBorderColor"].OnEvent("Change", (obj, *) => Cclors_Eventhandler(obj))
CustomColors.Push This.S_Gui.Add("Edit", " x+10 yp wp hp -Wrap vCTextColor", This.CustomColors_AllTColors)
This.S_Gui["CTextColor"].OnEvent("Change", (obj, *) => Cclors_Eventhandler(obj))
CustomColors.Push This.S_Gui.Add("Edit", " x+10 yp wp hp -Wrap vIABorderColor", This.CustomColors_IABorder_Colors)
This.S_Gui["IABorderColor"].OnEvent("Change", (obj, *) => Cclors_Eventhandler(obj))
This.S_Gui.Controls.Profile_Settings.PsDDL["Custom Colors"] := CustomColors
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL["Custom Colors"]
v.Visible := 0
Cclors_Eventhandler(obj) {
if (obj.Name = "Ccoloractive") {
This.CustomColorsActive := obj.value
}
else if (obj.Name = "Cchars") {
indexOld := This.IndexcChars
This.CustomColors_AllCharNames := obj.value
if (indexOld < This.IndexcChars) {
obj.value := This.CustomColors_AllCharNames
ControlSend("^{End}", obj.Hwnd)
}
This.NeedRestart := 1
}
else if (obj.Name = "CBorderColor") {
indexOld := This.IndexcBorder
This.CustomColors_AllBColors := obj.value
if (indexOld < This.IndexcBorder) {
obj.value := This.CustomColors_AllBColors
ControlSend("^{End}", obj.Hwnd)
}
This.NeedRestart := 1
}
else if (obj.Name = "CTextColor") {
indexOld := This.IndexcText
This.CustomColors_AllTColors := obj.value
if (indexOld < This.IndexcText) {
obj.value := This.CustomColors_AllTColors
ControlSend("^{End}", obj.Hwnd)
}
This.NeedRestart := 1
}
else if (obj.Name = "IABorderColor") {
indexOld := This.IndexcText
This.CustomColors_IABorder_Colors := obj.value
if (indexOld < This.IndexcText) {
obj.value := This.CustomColors_IABorder_Colors
ControlSend("^{End}", obj.Hwnd)
}
This.NeedRestart := 1
}
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
}
Hotkey_GroupsCtrl() {
This.S_Gui.Controls.Profile_Settings.PsDDL["Hotkey Groups"] := [], Hotkey_Groups := []
Hotkey_Groups.Push This.S_Gui.Add("GroupBox", "x20 y80 h440 w500 Section", "")
Hotkey_Groups.Push This.S_Gui.Add("Text", "x58 yp+130", "Select Group:")
ddl := This.S_Gui.Add("DropDownList", " xp-30 yp+18 w180 vHotkeyGroupDDL", This.GetGroupList())
Hotkey_Groups.Push ddl
This.S_Gui["HotkeyGroupDDL"].OnEvent("Change", (*) => SetEditText(ddl, EditBox, HKForwards, HKBackwards))
DeleteButton := This.S_Gui.Add("Button", "xs+370 yp-1 w60", "Delete")
NewButton := This.S_Gui.Add("Button", "x+5 yp w60", "New")
DeleteButton.OnEvent("Click", (*) => Delete_Group(ddl, HKForwards, HKBackwards, EditBox))
NewButton.OnEvent("Click", (*) => CreateNewGroup(ddl, HKForwards, HKBackwards, EditBox))
Hotkey_Groups.Push DeleteButton
Hotkey_Groups.Push NewButton
EditBox := This.S_Gui.Add("Edit", "xs+8 y275 w250 h225 -Wrap +HScroll Disabled vHKCharlist")
Hotkey_Groups.Push EditBox
This.S_Gui["HKCharlist"].OnEvent("Change", (obj, *) => SaveHKGroupList(obj))
Hotkey_Groups.Push This.S_Gui.Add("Text", "xs300 yp20", "Forwards Hotkey:")
HKForwards := This.S_Gui.Add("Edit", "xp yp+20 w150 Disabled vForwardsKey")
Hotkey_Groups.Push HKForwards
This.S_Gui["ForwardsKey"].OnEvent("Change", (obj, *) => SaveHKGroupList(obj))
Hotkey_Groups.Push This.S_Gui.Add("Text", "xp yp50", "Backwards Hotkey:")
HKBackwards := This.S_Gui.Add("Edit", "xp yp+20 w150 Disabled vBackwardsdKey")
Hotkey_Groups.Push HKBackwards
This.S_Gui["BackwardsdKey"].OnEvent("Change", (obj, *) => SaveHKGroupList(obj))
This.S_Gui.Controls.Profile_Settings.PsDDL["Hotkey Groups"] := Hotkey_Groups
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL["Hotkey Groups"]
v.Visible := 0
CreateNewGroup(ddlObj, ForwardHKObj, BackwardHKObj, EditObj) {
ArrayIndex := 0
Obj := InputBox("Enter a Groupname", "Create New Group", "w200 h90")
if (Obj.Result != "OK")
return
This.Hotkey_Groups[Obj.value] := []
ddlObj.Delete()
ddlObj.Add(This.GetGroupList())
for k in This.Hotkey_Groups {
if k = Obj.value {
ArrayIndex := A_Index
break
}
}
EditObj.value := "", ForwardHKObj.value := "", BackwardHKObj.value := ""
ForwardHKObj.Enabled := 1, BackwardHKObj.Enabled := 1, EditObj.Enabled := 1
ddlObj.Choose(ArrayIndex)
This.NeedRestart := 1
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
Delete_Group(ddlObj, ForwardHKObj, BackwardHKObj, EditObj) {
if (ddlObj.Text != "" && This.Hotkey_Groups.Has(ddlObj.Text))
This.Hotkey_Groups.Delete(ddlObj.Text)
ddlObj.Delete()
ddlObj.Add(This.GetGroupList())
ForwardHKObj.value := "", BackwardHKObj.value := "", EditObj.value := ""
ForwardHKObj.Enabled := 0, BackwardHKObj.Enabled := 0, EditObj.Enabled := 0
This.NeedRestart := 1
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
SetEditText(ddlObj, EditObj, ForwardHKObj?, BackwardHKObj?) {
text := ""
if (ddlObj.Text != "" && This.Hotkey_Groups.Has(ddlObj.Text)) {
for index, Names in This.Hotkey_Groups[ddlObj.Text]["Characters"] {
text .= Names "`n"
}
EditObj.value := text, EditObj.Enabled := 1
ForwardHKObj.value := This.Hotkey_Groups[ddlObj.Text]["ForwardsHotkey"], ForwardHKObj.Enabled := 1
BackwardHKObj.value := This.Hotkey_Groups[ddlObj.Text]["BackwardsHotkey"], BackwardHKObj.Enabled := 1
}
}
SaveHKGroupList(obj) {
if (obj.Name = "HKCharlist" && ddl.Text != "") {
Arr := []
for k, v in StrSplit(obj.value, "`n") {
Chars := Trim(v, "`n ")
if (Chars = "")
continue
Arr.Push(Chars)
}
This.Hotkey_Groups[ddl.Text]["Characters"] := Arr
}
else if (obj.Name = "ForwardsKey" && ddl.Text != "") {
This.Hotkey_Groups[ddl.Text]["ForwardsHotkey"] := Trim(obj.value, "`n ")
}
else if (obj.Name = "BackwardsdKey" && ddl.Text != "") {
This.Hotkey_Groups[ddl.Text]["BackwardsHotkey"] := Trim(obj.value, "`n ")
}
This.NeedRestart := 1
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
}
HotkeysCtrl() {
This.S_Gui.Controls.Profile_Settings.PsDDL["Hotkeys"] := [], Hotkeys := []
Hotkeys.Push This.S_Gui.Add("GroupBox", "x20 y80 h530 w500 Section", "")
Charlist := "", Hklist := ""
for index, value in This._Hotkeys {
for name, hotkey in value {
Charlist .= name "`n"
Hklist .= hotkey "`n"
}
}
Hotkeys.Push This.S_Gui.Add("Text", " x115 yp+130 section", "Character Name:")
HKCharList := This.S_Gui.Add("Edit", " xp-30 yp20 w180 h350 -Wrap vHotkeyCharList", Charlist)
Hotkeys.Push HKCharList
HKCharList.OnEvent("Change", (obj, *) => EventHandler(obj))
Hotkeys.Push This.S_Gui.Add("Text", " xs+210 ys", "Hotkeys:")
HKKeylist := This.S_Gui.Add("Edit", " xp-50 yp20 w180 h350 -Wrap vHotkeyList", Hklist)
Hotkeys.Push HKKeylist
HKKeylist.OnEvent("Change", (obj, *) => EventHandler(obj))
This.S_Gui.Controls.Profile_Settings.PsDDL["Hotkeys"] := Hotkeys
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL["Hotkeys"]
v.Visible := 0
EventHandler(obj) {
tempvar := []
ListChars := StrSplit(This.S_Gui["HotkeyCharList"].value, "`n"), ListHotkeys := StrSplit(This.S_Gui["HotkeyList"].value, "`n")
for k, v in ListChars {
chars := "", keys := ""
if (A_Index <= ListChars.Length) {
chars := Trim(ListChars[A_Index], "`n ")
}
if (A_Index <= ListHotkeys.Length) {
keys := Trim(ListHotkeys[A_Index], "`n ")
}
if (A_Index > ListHotkeys.Length) {
keys := ""
}
if (chars = "")
continue
tempvar.Push Map(chars, keys)
}
this._Hotkeys := tempvar
This.NeedRestart := 1
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
}
ThumbnailSettings_Ctrl() {
This.S_Gui.Controls.Profile_Settings.PsDDL["Thumbnail Settings"] := [], ThumbnailSettings := []
ThumbnailSettings.Push This.S_Gui.Add("GroupBox", "x20 y80 h580 w500 Section", "")
ThumbnailSettings.Push This.S_Gui.Add("Text", "xp+15 yp+140 Section", "Show Thumbnail Text Overlay:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Thumbnail Text Color:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Thumbnail Text Size:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Thumbnail Text Font:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Thumbnail Text Margins:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Client Highligt Color:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Client Highligt Border Thickness:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Show Client Highlight Border:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Hide Thumbnails On Lost Focus:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Thumbnail Opacity:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "Show Thumbnails AlwaysOnTop:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15", "Show All Borders:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15", "Inactive Client Border Thickness:")
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15", "Inactive Client Border Color:")
ThumbnailSettings.Push This.S_Gui.Add("CheckBox", "xs+230 ys Section vShowThumbnailTextOverlay Checked" This.ShowThumbnailTextOverlay, "On/Off")
This.S_Gui["ShowThumbnailTextOverlay"].OnEvent("Click", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Edit", "xs y+11  w120 vThumbnailTextColor -Wrap", This.ThumbnailTextColor)
ThumbnailSettings.Push This.S_Gui.Add("Text", " x+5 yp+3 ", "Hex or RGB")
This.S_Gui["ThumbnailTextColor"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Edit", "xs y+10 w30 vThumbnailTextSize -Wrap", This.ThumbnailTextSize)
This.S_Gui["ThumbnailTextSize"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Edit", "xs y+8 w120 vThumbnailTextFont -Wrap", This.ThumbnailTextFont)
This.S_Gui["ThumbnailTextFont"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+12", "width px:")
ThumbnailSettings.Push This.S_Gui.Add("Edit", "x+5 yp-4  w40 vThumbnailTextMarginsx -Wrap", This.ThumbnailTextMargins["x"])
This.S_Gui["ThumbnailTextMarginsx"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs+100 yp+4 ", "height px:")
ThumbnailSettings.Push This.S_Gui.Add("Edit", "xp+60 yp-4  w40 vThumbnailTextMarginsy -Wrap", This.ThumbnailTextMargins["y"])
This.S_Gui["ThumbnailTextMarginsy"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Edit", "xs y+7 w120 vClientHighligtColor -Wrap", This.ClientHighligtColor)
ThumbnailSettings.Push This.S_Gui.Add("Text", " x+5 yp+3 ", "Hex or RGB")
This.S_Gui["ClientHighligtColor"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "px:")
ThumbnailSettings.Push This.S_Gui.Add("Edit", "x+5 yp-3  w30 vClientHighligtBorderthickness -Wrap", This.ClientHighligtBorderthickness)
This.S_Gui["ClientHighligtBorderthickness"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("CheckBox", "xs y+10 vShowClientHighlightBorder Checked" This.ShowClientHighlightBorder, "On/Off")
This.S_Gui["ShowClientHighlightBorder"].OnEvent("Click", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("CheckBox", "xs y+16 vHideThumbnailsOnLostFocus Checked" This.HideThumbnailsOnLostFocus, "On/Off")
This.S_Gui["HideThumbnailsOnLostFocus"].OnEvent("Click", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+15 ", "%")
ThumbnailSettings.Push This.S_Gui.Add("Edit", "x+4 yp-4  w40 vThumbnailOpacity -Wrap", IntegerToPercentage(This.ThumbnailOpacity))
This.S_Gui["ThumbnailOpacity"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("CheckBox", "xs y+12 vShowThumbnailsAlwaysOnTop Checked" This.ShowThumbnailsAlwaysOnTop, "On/Off")
This.S_Gui["ShowThumbnailsAlwaysOnTop"].OnEvent("Click", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("CheckBox", "xs y+15 vShowAllBorders Checked" This.ShowAllColoredBorders, "On/Off")
This.S_Gui["ShowAllBorders"].OnEvent("Click", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Text", " xs y+12 ", "px:")
ThumbnailSettings.Push This.S_Gui.Add("Edit", "x+5 yp-3  w30 vInactiveClientBorderthickness -Wrap", This.InactiveClientBorderthickness)
This.S_Gui["InactiveClientBorderthickness"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
ThumbnailSettings.Push This.S_Gui.Add("Edit", "xs y+5 w120 vInactiveClientBorderColor -Wrap", This.InactiveClientBorderColor)
ThumbnailSettings.Push This.S_Gui.Add("Text", " x+5 yp+3 ", "Hex or RGB")
This.S_Gui["InactiveClientBorderColor"].OnEvent("Change", (obj, *) => ThumbnailSettings_EventHandler(obj))
This.S_Gui.Controls.Profile_Settings.PsDDL["Thumbnail Settings"] := ThumbnailSettings
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL["Thumbnail Settings"] {
v.Visible := 0
}
ThumbnailSettings_EventHandler(obj) {
if (obj.name = "ShowThumbnailTextOverlay") {
This.ShowThumbnailTextOverlay := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ThumbnailTextColor") {
This.ThumbnailTextColor := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ThumbnailTextSize") {
This.ThumbnailTextSize := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ThumbnailTextFont") {
This.ThumbnailTextFont := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ThumbnailTextMarginsx") {
This.ThumbnailTextMargins["x"] := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ThumbnailTextMarginsy") {
This.ThumbnailTextMargins["y"] := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ClientHighligtColor") {
This.ClientHighligtColor := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ClientHighligtBorderthickness") {
This.ClientHighligtBorderthickness := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ShowClientHighlightBorder") {
This.ShowClientHighlightBorder := obj.value
}
else if (obj.name = "HideThumbnailsOnLostFocus") {
This.HideThumbnailsOnLostFocus := obj.value
}
else if (obj.name = "ThumbnailOpacity") {
This.ThumbnailOpacity := obj.value
This.NeedRestart := 1
}
else if (obj.name = "ShowThumbnailsAlwaysOnTop") {
This.ShowThumbnailsAlwaysOnTop := obj.value
This.NeedRestart := 1
}
else if (obj.Name = "ShowAllBorders") {
This.ShowAllColoredBorders := obj.value
This.S_Gui["InactiveClientBorderthickness"].Enabled := This.ShowAllColoredBorders
This.S_Gui["InactiveClientBorderColor"].Enabled := This.ShowAllColoredBorders
This.NeedRestart := 1
}
else if (obj.Name = "InactiveClientBorderColor") {
This.InactiveClientBorderColor := obj.value
This.NeedRestart := 1
}
else if (obj.Name = "InactiveClientBorderthickness") {
This.InactiveClientBorderthickness := obj.value
This.NeedRestart := 1
}
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
}
Thumbnail_visibilityCtrl() {
This.S_Gui.Controls.Profile_Settings.PsDDL["Thumbnail Visibility"] := [], Thumbnail_visibility := []
Thumbnail_visibility.Push This.S_Gui.Add("GroupBox", "x20 y80 h610 w500 Section", "")
Thumbnail_visibility.Push This.S_Gui.Add("Text", "xp+140 yp+130 w250", "Select any Client to hide the Thumbnail")
This.Tv_LV := This.S_Gui.Add("ListView", "xp+15 yp+30 w210 Checked -LV0x10 -Multi r20 -Sort vVisibility_List", ["Client Name       "])
Thumbnail_visibility.Push This.Tv_LV
for k, v in This.compare_openclients_with_list() {
if (k != "EVE" || v != "") {
if This.Thumbnail_visibility.Has(v)
This.Tv_LV.Add("Check", v,)
else
This.Tv_LV.Add("", v,)
}
}
This.Tv_LV.ModifyCol(1, 150), This.Tv_LV.ModifyCol(2, 115)
This.Tv_LV.OnEvent("ItemCheck", ObjBindMethod(This, "_Tv_LVSelectedRow"))
This.S_Gui.Controls.Profile_Settings.PsDDL["Thumbnail Visibility"] := Thumbnail_visibility
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL["Thumbnail Visibility"]
v.Visible := 0
}
On_WM_MOUSEMOVE(wParam, lParam, msg, Hwnd) {
static PrevHwnd := 0
if (Hwnd != PrevHwnd) {
Text := "", ToolTip()
CurrControl := GuiCtrlFromHwnd(Hwnd)
if CurrControl {
if !CurrControl.HasProp("ToolTip")
return
Text := CurrControl.ToolTip
SetTimer () => ToolTip(Text), -1000
SetTimer () => ToolTip(), -4000
}
PrevHwnd := Hwnd
}
}
Profiles_to_Array() {
ll := []
for k, v in This.Profiles
ll.Push(k)
return ll
}
Dont_Minimize_List() {
list := ""
for k in This.Dont_Minimize_Clients {
list .= k "`n"
}
return list
}
_Button_Load(obj?,*) {
if (IsSet(obj))
This.NeedRestart := 1
This.LastUsedProfile := This.S_Gui["SelectedProfile"].Text
This.Refresh_ControlValues()
if (This.S_Gui["SelectedProfile"].Text = "Default") {
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL {
for _, ob in v {
ob.Enabled := 0
}
}
}
SetTimer(This.Save_Settings_Delay_Timer, -200)
}
Refresh_ControlValues() {
This.S_Gui["Suspend_Hotkeys_Hotkey"].value := This.Suspend_Hotkeys_Hotkey
This.S_Gui["Hotkey_Scoope"].value := (This.Global_Hotkeys ? 1 : 2)
This.S_Gui["ThumbnailBackgroundColor"].value := This.ThumbnailBackgroundColor
This.S_Gui["ThumbnailStartLocationx"].value := This.ThumbnailStartLocation["x"]
This.S_Gui["ThumbnailStartLocationy"].value := This.ThumbnailStartLocation["y"]
This.S_Gui["ThumbnailStartLocationwidth"].value := This.ThumbnailStartLocation["width"]
This.S_Gui["ThumbnailStartLocationheight"].value := This.ThumbnailStartLocation["height"]
This.S_Gui["ThumbnailMinimumSizewidth"].value := This.ThumbnailMinimumSize["width"]
This.S_Gui["ThumbnailMinimumSizeheight"].value := This.ThumbnailMinimumSize["height"]
This.S_Gui["ThumbnailSnapOn"].value := This.ThumbnailSnap
This.S_Gui["ThumbnailSnapOff"].value := (This.ThumbnailSnap ? 0 : 1)
This.S_Gui["ThumbnailSnap_Distance"].value := This.ThumbnailSnap_Distance
This.S_Gui["MinimizeInactiveClients"].value := This.MinimizeInactiveClients
This.S_Gui["Minimizeclients_Delay"].value := This.Minimizeclients_Delay
This.S_Gui["AlwaysMaximize"].value := This.AlwaysMaximize
This.S_Gui["Dont_Minimize_Clients"].value := This.Dont_Minimize_List()
This.S_Gui["Ccoloractive"].value := This.CustomColorsActive
This.S_Gui["Cchars"].value := This.CustomColors_AllCharNames
This.S_Gui["CBorderColor"].value := This.CustomColors_AllBColors
This.S_Gui["CTextColor"].value := This.CustomColors_AllTColors
This.S_Gui["IABorderColor"].value := This.CustomColors_IABorder_Colors
This.S_Gui["HotkeyGroupDDL"].Delete()
This.S_Gui["HotkeyGroupDDL"].Add(This.GetGroupList())
This.S_Gui["ForwardsKey"].value := "", This.S_Gui["ForwardsKey"].Enabled := 0
This.S_Gui["BackwardsdKey"].value := "", This.S_Gui["BackwardsdKey"].Enabled := 0
This.S_Gui["HKCharlist"].value := "", This.S_Gui["HKCharlist"].Enabled := 0
Charlist := "", Hklist := ""
for index, value in This._Hotkeys {
for name, hotkey in value {
Charlist .= name "`n"
Hklist .= hotkey "`n"
}
}
This.S_Gui["HotkeyCharList"].value := Charlist
This.S_Gui["HotkeyList"].value := Hklist
This.S_Gui["ShowThumbnailTextOverlay"].value := This.ShowThumbnailTextOverlay
This.S_Gui["ThumbnailTextColor"].value := This.ThumbnailTextColor
This.S_Gui["ThumbnailTextSize"].value := This.ThumbnailTextSize
This.S_Gui["ThumbnailTextFont"].value := This.ThumbnailTextFont
This.S_Gui["ThumbnailTextMarginsx"].value := This.ThumbnailTextMargins["x"]
This.S_Gui["ThumbnailTextMarginsy"].value := This.ThumbnailTextMargins["y"]
This.S_Gui["ClientHighligtColor"].value := This.ClientHighligtColor
This.S_Gui["ClientHighligtBorderthickness"].value := This.ClientHighligtBorderthickness
This.S_Gui["ShowClientHighlightBorder"].value := This.ShowClientHighlightBorder
This.S_Gui["HideThumbnailsOnLostFocus"].value := This.HideThumbnailsOnLostFocus
This.S_Gui["ThumbnailOpacity"].value := IntegerToPercentage(This.ThumbnailOpacity)
This.S_Gui["ShowThumbnailsAlwaysOnTop"].value := This.ShowThumbnailsAlwaysOnTop
This.S_Gui["ShowAllBorders"].value := This.ShowAllColoredBorders
This.S_Gui["InactiveClientBorderthickness"].value := This.InactiveClientBorderthickness
This.S_Gui["InactiveClientBorderColor"].value := This.InactiveClientBorderColor
This.S_Gui["Visibility_List"].Delete()
for k, v in This.compare_openclients_with_list() {
if (k != "EVE" || v != "") {
if This.Thumbnail_visibility.Has(v)
This.Tv_LV.Add("Check", v,)
else
This.Tv_LV.Add("", v,)
}
}
for k, v in This.S_Gui.Controls.Profile_Settings.PsDDL {
for _, ob in v {
ob.Enabled := 1
}
This.S_Gui["HKCharlist"].Enabled := 0
This.S_Gui["ForwardsKey"].Enabled := 0
This.S_Gui["BackwardsdKey"].Enabled := 0
}
This.S_Gui["InactiveClientBorderthickness"].Enabled := This.ShowAllColoredBorders
This.S_Gui["InactiveClientBorderColor"].Enabled := This.ShowAllColoredBorders
}
compare_openclients_with_list() {
EvENameList := []
for EveHwnd in This.ThumbWindows.OwnProps() {
try {
if title := This.CleanTitle(WinGetTitle("Ahk_Id " EveHwnd) = "") {
continue
}
EvENameList.Push This.CleanTitle(WinGetTitle("Ahk_Id " EveHwnd))
}
}
return EvENameList
}
GetGroupList() {
List := []
if (IsObject(This.Hotkey_Groups)) {
for k in This.Hotkey_Groups {
List.Push(k)
}
return List
}
else
return []
}
}
IntegerToPercentage(integerValue) {
percentage := (integerValue < 0 ? 0 : integerValue > 255 ? 100 : Round(integerValue * 100 / 255))
return percentage
}
CompareArrays(arr1, arr2) {
commonValues := {}
for _, value in arr1 {
if (IsInArray(value, arr2))
commonValues.%value% := 1
else
commonValues.%value% := 0
}
for _, value in arr2 {
if (!IsInArray(value, arr1))
commonValues.%value% := 0
}
return commonValues
}
IsInArray(value, arr) {
for _, item in arr {
if (item = value)
return true
}
return false
}
#SingleInstance Force
Persistent
ListLines False
KeyHistory 0
CoordMode "Mouse", "Screen"
SetWinDelay -1
FileEncoding("UTF-8")
SetTitleMatchMode 3
A_MaxHotKeysPerInterval := 10000
; High process priority in Windows
ProcessSetPriority("High")
if !(A_IsCompiled)
TraySetIcon("icon.ico",,true)
OnError(Error_Handler)
Call := Main_Class()
Load_JSON() {
DJSON := JSON.Load(default_JSON)
if !(FileExist("EVE-X-Preview.json")) {
FileAppend(JSON.Dump(DJSON,,"    " ), "EVE-X-Preview.json")
_JSON :=  JSON.Load(FileRead("EVE-X-Preview.json"))
return _JSON
}
else {
Try {
if (FileExist("EVE-X-Preview.json")) {
MergeJson()
}
_JSON := JsonMergeNoOverwrite(
DJSON,
JSON.Load(FileRead("EVE-X-Preview.json"))
)
FileDelete("EVE-X-Preview.json")
FileAppend(JSON.Dump(_JSON,,"    " ), "EVE-X-Preview.json")
}
catch as e  {
value := MsgBox("The settings file is corrupted. Do you want to create a new one?",,"OKCancel")
if (value = "Cancel")
ExitApp()
FileDelete("EVE-X-Preview.json")
FileAppend(JSON.Dump(DJSON,, "    "), "EVE-X-Preview.json")
_JSON :=  JSON.Load(FileRead("EVE-X-Preview.json"))
}
}
return _JSON
}
JsonMergeNoOverwrite(obj1, obj2) {
for key, value in obj1 {
if (obj2.Has(key)) {
if (IsObject(value) && IsObject(obj2[key]))
obj2[key] := JsonMergeNoOverwrite(value, obj2[key])
} else {
obj2[key] := value
}
}
return obj2
}
MergeJson(Settingsfile := "EVE-X-Preview.json", dJson := JSON.Load(default_JSON)) {
fileObj := FileOpen(Settingsfile,"r", "Utf-8")
JsonRaw := fileObj.Read(), fileObj.Close()
OldJson := JSON.Load(JsonRaw)
savetofile := 0
for Profiles, settings in OldJson["_Profiles"] {
if (Profiles = "Default") {
continue
}
dJson["_Profiles"][Profiles] := Map()
for k, v in settings {
if (OldJson["_Profiles"][Profiles].Has("ClientPossitions")) {
savetofile := 1
if (k = "ClientPossitions")
dJson["_Profiles"][Profiles]["Client Possitions"] := v
else if (k = "ClientSettings")
dJson["_Profiles"][Profiles]["Client Settings"] :=  v
else if (k = "ThumbnailSettings")
dJson["_Profiles"][Profiles]["Thumbnail Settings"] := v
else if (k = "ThumbnailPositions")
dJson["_Profiles"][Profiles]["Thumbnail Positions"] :=  v
else if (k = "Thumbnail_visibility")
dJson["_Profiles"][Profiles]["Thumbnail Visibility"] := v
else if (k = "Custom_Colors")
dJson["_Profiles"][Profiles]["Custom Colors"] := dJson["_Profiles"]["Default"]["Custom Colors"]
else if (k = "Hotkey_Groups")
dJson["_Profiles"][Profiles]["Hotkey Groups"] := v
else if (k = "Hotkeys") {
if (Type(v) = "Map") {
Arr := []
for char, hotkey in v
Arr.Push(Map(char, hotkey))
dJson["_Profiles"][Profiles]["Hotkeys"] := Arr
}
}
}
}
}
if savetofile {
dJson["global_Settings"] := OldJson["global_Settings"]
fileObj := FileOpen(Settingsfile,"w", "Utf-8")
fileObj.Write(JSON.Dump(dJson,, "    ")), fileObj.Close()
}
}
Error_Handler(Thrown, Mode) {
return -1
}