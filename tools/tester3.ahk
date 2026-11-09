#Requires AutoHotkey v2.0
; Rapid switching test. Usage: tester3.ahk <evex_pid> <out_file> <switches> <interval_ms> <label>
DetectHiddenWindows true
SetTitleMatchMode 3
DllCall("winmm\timeBeginPeriod", "UInt", 1)
pid := A_Args[1], outFile := A_Args[2], N := Integer(A_Args[3]), interval := Integer(A_Args[4]), label := A_Args[5]

qpc() {
    static f := 0
    if !f
        DllCall("QueryPerformanceFrequency", "Int64*", &f)
    DllCall("QueryPerformanceCounter", "Int64*", &c := 0)
    return c / f * 1000
}
; border counts as shown when visible AND its window region is not empty
BorderShown(h) {
    if !DllCall("IsWindowVisible", "Ptr", h)
        return false
    rc := Buffer(16, 0)
    r := DllCall("GetWindowRgnBox", "Ptr", h, "Ptr", rc)
    return r != 1   ; 1 = NULLREGION (empty), 0 = no region (whole window), 2/3 = has shape
}
; thumbnail + border per character
thumbs := Map(), byOwner := Map()
for h in WinGetList("ahk_pid " pid) {
    ex := WinGetExStyle(h), title := WinGetTitle(h)
    owner := DllCall("GetWindow", "Ptr", h, "UInt", 4, "Ptr")
    ctrls := []
    try ctrls := WinGetControls(h)
    if (ex & 0x08000000) && title != "" && !ctrls.Length
        thumbs[title] := {thumb: h, border: 0, eve: WinExist("EVE - " title " ahk_exe exefile.exe")}
    else if owner && !ctrls.Length
        byOwner[h] := owner
}
for name, t in thumbs
    for h, o in byOwner
        if o = t.thumb
            t.border := h
names := []
for name in thumbs
    names.Push(name)

fgT := [], brT := [], fail := 0, late := 0, missInfo := ""
prev := ""
Loop N {
    ; pseudo-random next client, never the same as previous
    Loop {
        name := names[Random(1, names.Length)]
    } until name != prev
    prev := name
    t := thumbs[name]
    wasIconic := DllCall("IsIconic", "Ptr", t.eve)
    t0 := qpc()
    PostMessage(0x201, 1, 0, , "ahk_id " t.thumb)
    PostMessage(0x202, 0, 0, , "ahk_id " t.thumb)
    gotFg := 0, gotBr := 0
    while ((now := qpc() - t0) < interval) {
        if !gotFg && DllCall("GetForegroundWindow", "Ptr") = t.eve
            gotFg := now
        if !gotBr && BorderShown(t.border)
            gotBr := now
        Sleep 1
    }
    if gotFg
        fgT.Push(gotFg)
    else {
        fail++
        ; diagnose: does it arrive later?
        fgNow := DllCall("GetForegroundWindow", "Ptr")
        fgName := ""
        for n2, t2 in thumbs
            if t2.eve = fgNow
                fgName := n2
        later := 0
        while ((now := qpc() - t0) < 1000) {
            if DllCall("GetForegroundWindow", "Ptr") = t.eve {
                later := now
                break
            }
            Sleep 1
        }
        missInfo .= Format("    MISS #{} -> {} (was {}), fg at deadline: {}, arrived later: {}`n", A_Index, name, wasIconic ? "minimized" : "not minimized", fgName = "" ? "non-EVE/none" : fgName, later ? Round(later) " ms" : "NEVER")
    }
    if gotBr
        brT.Push(gotBr)
    else
        late++
}
stats(a) {
    if !a.Length
        return "n/a"
    s := a.Clone(), sum := 0
    ; sort
    Loop s.Length - 1 {
        i := A_Index
        Loop s.Length - i
            if s[A_Index] > s[A_Index + 1]
                tmp := s[A_Index], s[A_Index] := s[A_Index + 1], s[A_Index + 1] := tmp
    }
    for v in s
        sum += v
    return Format("avg {:5.1f} ms | median {:5.1f} | p90 {:5.1f} | max {:5.1f}", sum / s.Length, s[Ceil(s.Length / 2)], s[Ceil(s.Length * 0.9)], s[s.Length])
}
out := Format("[{}] {} switches every {} ms ({:.1f}/s)`n", label, N, interval, 1000 / interval)
out .= "  client in front : " stats(fgT) "   missed: " fail "`n"
out .= "  border visible  : " stats(brT) "   missed: " late "`n"
out .= missInfo
FileAppend(out, outFile, "UTF-8")
DllCall("winmm\timeEndPeriod", "UInt", 1)
