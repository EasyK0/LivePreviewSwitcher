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
