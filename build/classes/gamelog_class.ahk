; --- Character DPS read from combat logs (Documents\EVE\logs\Gamelogs) ---
Class EVE_GameLog {
static Dir := EVE_GameLog.FindDir()
static Chars := Map()
static Seen := Map()
; average over the whole fight; a gap in hits longer than FightGap (s) = new fight
static FightGap := 20
static Skew := 0, SkewSet := false
static DayCache := Map()
static FindDir() {
for p in [A_MyDocuments "\EVE\logs\Gamelogs", EnvGet("USERPROFILE") "\Documents\EVE\logs\Gamelogs"]
if DirExist(p)
return p
return ""
}
static Scan() {
if (This.Dir = "")
return
for day in [FormatTime(DateAdd(A_NowUTC, -1, "Days"), "yyyyMMdd"), FormatTime(A_NowUTC, "yyyyMMdd")] {
Loop Files This.Dir "\" day "_*.txt" {
path := A_LoopFileFullPath
if This.Seen.Has(path)
continue
listener := This.ReadListener(path)
if (listener = "")
continue
This.Seen[path] := listener
stamp := RegExReplace(A_LoopFileName, "^(\d{8})_(\d{6})_.*$", "$1$2")
if (!This.Chars.Has(listener) || This.Chars[listener].stamp < stamp) {
if (This.Chars.Has(listener) && This.Chars[listener].f)
try This.Chars[listener].f.Close()
This.Chars[listener] := {path: path, stamp: stamp, pos: -1, f: 0, fightStart: 0, lastHit: 0, total: 0, count: 0, ticks: 0}
}
}
}
}
static ReadListener(path) {
try {
f := FileOpen(path, "r", "UTF-8")
txt := f.Read(400)
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
pcNow := DateDiff(A_NowUTC, "20000101", "Seconds")
try {
; log kept open; CP28591 = 1 byte per character, so byte position = character count
if !c.f {
c.f := FileOpen(c.path, "r", "CP28591")
if (c.pos < 0)
c.pos := c.f.Length
}
if (c.f.Length > c.pos) {
c.f.Pos := c.pos
txt := c.f.Read()
if (nl := InStr(txt, "`n", , -1)) {
chunk := SubStr(txt, 1, nl)
c.pos += nl
p := 1, ts := 0
while (p := RegExMatch(chunk, "\[ (\d{4})\.(\d\d)\.(\d\d) (\d\d):(\d\d):(\d\d) \] \(combat\) <color=0x[0-9a-fA-F]+><b>(\d+)</b> <color=0x77ffffff><font size=10>to</font>", &m, p)) {
dkey := m[1] m[2] m[3]
if !This.DayCache.Has(dkey)
This.DayCache[dkey] := DateDiff(dkey, "20000101", "Seconds")
ts := This.DayCache[dkey] + m[4] * 3600 + m[5] * 60 + m[6]
if (c.count && ts < c.fightStart) {
p += m.Len
continue
}
if (!c.count || ts - c.lastHit > This.FightGap)
c.fightStart := ts, c.lastHit := ts, c.total := 0, c.count := 0, c.ticks := 1
else if (ts > c.lastHit)
c.ticks += 1
c.total += Integer(m[7]), c.count += 1
if (ts > c.lastHit)
c.lastHit := ts
p += m.Len
}
; PC clock vs EVE time difference (lines can be late, never early)
if (ts && (!This.SkewSet || ts - pcNow > This.Skew))
This.Skew := ts - pcNow, This.SkewSet := true
}
}
}
catch {
try c.f.Close()
c.f := 0
}
; fight over or only one volley so far -> show nothing
if (c.ticks < 2 || pcNow + This.Skew - c.lastHit > This.FightGap)
return ""
; fight time = first to last volley + one average cycle (from log times, so EVE's write delay has no effect)
; cycle computed from the number of distinct seconds with hits (several lines in one second = one volley of several weapon groups)
span := c.lastHit - c.fightStart
interval := span / (c.ticks - 1)
return Round(c.total / Max(1, span + interval)) " DPS"
}
}
