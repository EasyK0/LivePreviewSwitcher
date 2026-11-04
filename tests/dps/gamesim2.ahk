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
dir := A_Args[1]
EVE_GameLog.Dir := dir
day := FormatTime(A_NowUTC, "yyyyMMdd")
TS(off := 0) => FormatTime(DateAdd(A_NowUTC, off, "Seconds"), "yyyy.MM.dd HH:mm:ss")
Hit(dmg, off := 0) => "[ " TS(off) " ] (combat) <color=0xff00ffff><b>" dmg "</b> <color=0x77ffffff><font size=10>to</font> <b><color=0xffffffff>Amarr Control Tower Small</b><font size=10><color=0x77ffffff> - Scourge Rage Heavy Assault Missile - Hits`r`n"
Hdr(name) => "------------------------------------------------------------`r`n  Gamelog`r`n  Listener: " name "`r`n  Session Started: x`r`n------------------------------------------------------------`r`n"
Open(name, id) {
    global dir, day
    w := FileOpen(dir "\" day "_120000_" id ".txt", "w", "UTF-8-RAW")
    w.Write(Hdr(name))
    w.Read(0)
    return w
}
Flush(w) => w.Read(0)
out := "", pass := 0, fail := 0
Check(label, got, want) {
    global out, pass, fail
    ok := got == want
    ok ? pass++ : fail++
    out .= Format("{} {:-44} got [{}] expected [{}]`n", ok ? "PASS" : "FAIL", label, got, want)
}
a := Open("Pilot A", 1)
a.Write(Hit(9999, -3) Hit(9999, -1)), Flush(a)          ; history from before the program started
EVE_GameLog.Scan()
Check("1 history skipped", EVE_GameLog.Get("Pilot A"), "")
a.Write(Hit(1490, -12)), Flush(a)
Check("2 single volley -> nothing yet", EVE_GameLog.Get("Pilot A"), "")
a.Write(Hit(1490, -10) Hit(1490, -8) Hit(1490, -6) Hit(1490, -4)), Flush(a)
Check("3 five volleys 1490 every 2 s", EVE_GameLog.Get("Pilot A"), "745 DPS")
a.Write("[ " TS(-3) " ] (combat) <color=0xffcc0000><b>400</b> <color=0x77ffffff><font size=10>from</font> <b>Rat</b> - Hits`r`n")
a.Write("[ " TS(-3) " ] (combat) Your Heavy Assault Missile misses Rat completely`r`n"), Flush(a)
Check("4 incoming damage + miss ignored", EVE_GameLog.Get("Pilot A"), "745 DPS")
half := Hit(1490, -2)
a.Write(SubStr(half, 1, 60)), Flush(a)
Check("5 half-written line ignored", EVE_GameLog.Get("Pilot A"), "745 DPS")
a.Write(SubStr(half, 61)), Flush(a)
Check("6 line completed (6 volleys, steady)", EVE_GameLog.Get("Pilot A"), "745 DPS")
a.Write(Hit(50000, -40)), Flush(a)
Check("7 out-of-order old hit ignored", EVE_GameLog.Get("Pilot A"), "745 DPS")
a.Write(Hit(745, 0)), Flush(a)
Check("8 weaker volley lowers average", EVE_GameLog.Get("Pilot A"), Round((1490 * 6 + 745) / 14) " DPS")
b := Open("Pilot B", 2)
EVE_GameLog.Scan()
EVE_GameLog.Get("Pilot B")
b.Write(Hit(5000, -60) Hit(5000, -58) Hit(1000, -15) Hit(1000, -13) Hit(1000, -11)), Flush(b)
Check("9 gap > 20 s starts a new fight", EVE_GameLog.Get("Pilot B"), "500 DPS")
c := Open("Pilot C", 3)
EVE_GameLog.Scan()
EVE_GameLog.Get("Pilot C")
c.Write(Hit(3000, -40) Hit(3000, -38)), Flush(c)
Check("10 fight ended (silence > 20 s)", EVE_GameLog.Get("Pilot C"), "")
Check("11 unknown character", EVE_GameLog.Get("Nobody"), "")
d := Open("Pilot D", 4)
EVE_GameLog.Scan()
EVE_GameLog.Get("Pilot D")
d.Write(Hit(1000, -6) Hit(1000, -6) Hit(1000, -6)), Flush(d)
Check("12 several lines in the same second -> wait", EVE_GameLog.Get("Pilot D"), "")
d.Write(Hit(1000, -5) Hit(1000, -5) Hit(1000, -5) Hit(1000, -4) Hit(1000, -4) Hit(1000, -4) Hit(1000, -3) Hit(1000, -3) Hit(1000, -3)), Flush(d)
Check("13 3 groups x 1000 every second", EVE_GameLog.Get("Pilot D"), "3000 DPS")
a.Close(), b.Close(), c.Close(), d.Close()
out .= Format("`n{} passed, {} failed`n", pass, fail)
FileAppend(out, dir "\result.txt", "UTF-8")
ExitApp
