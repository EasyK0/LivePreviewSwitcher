; --- Current solar system of a character, read from Local channel logs (Documents\EVE\logs\Chatlogs) ---
Class EVE_LocalSystem {
static Dir := EVE_LocalSystem.FindDir()
static Chars := Map()
static Seen := Map()
static FindDir() {
for p in [A_MyDocuments "\EVE\logs\Chatlogs", EnvGet("USERPROFILE") "\Documents\EVE\logs\Chatlogs"]
if DirExist(p)
return p
return ""
}
static Scan() {
if (This.Dir = "")
return
for day in [FormatTime(DateAdd(A_NowUTC, -1, "Days"), "yyyyMMdd"), FormatTime(A_NowUTC, "yyyyMMdd")] {
Loop Files This.Dir "\Local_" day "_*.txt" {
path := A_LoopFileFullPath
if This.Seen.Has(path)
continue
listener := This.ReadListener(path)
if (listener = "")
continue
This.Seen[path] := listener
stamp := RegExReplace(A_LoopFileName, "^Local_(\d{8})_(\d{6})_.*$", "$1$2")
if (!This.Chars.Has(listener) || This.Chars[listener].stamp < stamp) {
if (This.Chars.Has(listener) && This.Chars[listener].f)
try This.Chars[listener].f.Close()
This.Chars[listener] := {path: path, stamp: stamp, pos: 0, system: "", f: 0}
}
}
}
}
static ReadListener(path) {
try {
f := FileOpen(path, "r", "UTF-16")
txt := f.Read(1000)
f.Close()
}
catch
return ""
return RegExMatch(txt, "Listener:\s*([^\r\n]+)", &m) ? Trim(m[1]) : ""
}
static Get(name) {
if !This.Chars.Has(name)
return ""
c := This.Chars[name]
try {
; the log file stays open (does not block EVE), no open/close every second
if !c.f {
c.f := FileOpen(c.path, "r", "UTF-16")
if !c.pos
c.pos := c.f.Pos
}
if (c.f.Length > c.pos) {
c.f.Pos := c.pos
txt := c.f.Read()
if (nl := InStr(txt, "`n", , -1)) {
chunk := SubStr(txt, 1, nl)
c.pos += nl * 2
p := 1
while (p := RegExMatch(chunk, "Channel changed to Local\s*:\s*([^\r\n*]+)", &m, p)) {
c.system := Trim(m[1])
p += m.Len
}
}
}
}
catch {
try c.f.Close()
c.f := 0
}
return c.system
}
}
