#Requires AutoHotkey v2.0
; --- Character DPS read from the combat logs (Documents\EVE\logs\Gamelogs) ---
Class EVE_GameLog {
static Dir := EVE_GameLog.FindDir()
static Chars := Map()
static Seen := Map()
; average over the whole fight; a gap between hits longer than FightGap (s) = new fight
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
; log kept open; CP28591 = 1 byte per character, so the byte position = the character count
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
; offset between the PC clock and EVE time (lines can be late, never early)
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
; fight time = first to last volley + one average cycle (from the log timestamps, so EVE's write delay has no effect)
; cycle counted from the number of distinct seconds with hits (several lines in the same second = one volley of several weapon groups)
span := c.lastHit - c.fightStart
interval := span / (c.ticks - 1)
return Round(c.total / Max(1, span + interval)) " DPS"
}
}
; Usage: replay.ahk <source gamelog> <out dir> <delay s> <label>
src := A_Args[1], dir := A_Args[2], delay := Integer(A_Args[3]), label := A_Args[4]
EVE_GameLog.Dir := dir
txt := FileRead(src, "UTF-8")
lines := [], t0 := 0
for srcLine in StrSplit(txt, "`n", "`r") {
    if !InStr(srcLine, "Amarr Control Tower")
        continue
    if !RegExMatch(srcLine, "^\[ (\d{4})\.(\d\d)\.(\d\d) (\d\d):(\d\d):(\d\d) \] (.*)$", &m)
        continue
    s := DateDiff(m[1] m[2] m[3] m[4] m[5] m[6], "20000101", "Seconds")
    if !t0
        t0 := s
    lines.Push({off: s - t0, rest: m[7]})
}
startUTC := A_NowUTC
w := FileOpen(dir "\" FormatTime(A_NowUTC, "yyyyMMdd") "_120000_1.txt", "w", "UTF-8-RAW")
w.Write("------------------------------------------------------------`r`n  Gamelog`r`n  Listener: Pilot A`r`n  Session Started: x`r`n------------------------------------------------------------`r`n")
w.Read(0)
EVE_GameLog.Scan()
EVE_GameLog.Get("Pilot A")
t := A_TickCount, next := 1, vals := [], trace := ""
lastOff := lines[lines.Length].off
Loop {
    el := (A_TickCount - t) / 1000
    while (next <= lines.Length && lines[next].off + delay <= el) {
        ts := FormatTime(DateAdd(startUTC, lines[next].off, "Seconds"), "yyyy.MM.dd HH:mm:ss")
        w.Write("[ " ts " ] " lines[next].rest "`r`n")
        next++
    }
    w.Read(0)
    if (Mod(A_Index, 10) = 0) {          ; read once per second, like the program
        v := EVE_GameLog.Get("Pilot A")
        n := v = "" ? 0 : Integer(StrReplace(v, " DPS"))
        vals.Push(n)
        trace .= n " "
    }
    if (el > lastOff + delay + 3)
        break
    Sleep 100
}
w.Close()
sum := 0, cnt := 0
Loop 30 {
    i := vals.Length - 3 - A_Index + 1
    if (i >= 1 && vals[i] > 0)
        sum += vals[i], cnt++
}
out := Format("[{}] delay {} s | volleys {} | final {} | avg of last 30 s {:.0f}`n  per second: {}`n", label, delay, lines.Length, vals[vals.Length - 3], cnt ? sum / cnt : 0, trace)
FileAppend(out, dir "\replay.txt", "UTF-8")
ExitApp
