# Diagnostic layer of the Test variant: applied on top of the Ultimate script (src/EVE-X-Preview.ahk).
# The EVE-X-diag.log log goes to the "EVE-X Build" folder next to the exe folder (or next to the exe when it is missing).
PATCHES = [
    (
        b'#Requires AutoHotkey v2.0\n',
        b'#Requires AutoHotkey v2.0\n'
        b'global DIAG := Map("switch", 0, "ensure_restore", 0, "slow", 0, "errors", 0)\n'
        b'global DIAGMAX := Map()\n'
        b'global DIAGBUF := ""\n'
        b'DiagLog(msg) {\n'
        b'global DIAGBUF\n'
        b'DIAGBUF .= FormatTime(, "yyyy-MM-dd HH:mm:ss") " " msg "`n"\n'
        b'}\n'
        b'DiagFlush() {\n'
        b'global DIAGBUF\n'
        b'if (DIAGBUF = "")\n'
        b'return\n'
        b'diagDir := A_ScriptDir "\\..\\EVE-X Build"\n'
        b'if !DirExist(diagDir)\n'
        b'diagDir := A_ScriptDir\n'
        b'try FileAppend(DIAGBUF, diagDir "\\EVE-X-diag.log", "UTF-8")\n'
        b'DIAGBUF := ""\n'
        b'}\n'
        b'DiagCount(k) {\n'
        b'global DIAG\n'
        b'DIAG[k] := (DIAG.Has(k) ? DIAG[k] : 0) + 1\n'
        b'}\n'
        b'DiagQPC() {\n'
        b'static f := 0\n'
        b'if !f\n'
        b'DllCall("QueryPerformanceFrequency", "Int64*", &f)\n'
        b'DllCall("QueryPerformanceCounter", "Int64*", &c := 0)\n'
        b'return c / f * 1000\n'
        b'}\n'
        b'DiagTime(name, ms) {\n'
        b'global DIAGMAX\n'
        b'if (!DIAGMAX.Has(name) || ms > DIAGMAX[name])\n'
        b'DIAGMAX[name] := ms\n'
        b'if (ms > 15) {\n'
        b'DiagCount("slow")\n'
        b'DiagLog(Format("SLOW {} took {:.1f} ms", name, ms))\n'
        b'}\n'
        b'}\n'
        b'DiagStats() {\n'
        b'global DIAG, DIAGMAX\n'
        b'static c0 := -1, m0 := 0\n'
        b'DllCall("GetProcessTimes", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "Int64*", &a := 0, "Int64*", &b := 0, "Int64*", &k := 0, "Int64*", &u := 0)\n'
        b'cpu := (k + u) / 10000\n'
        b'DllCall("GetThreadTimes", "Ptr", DllCall("GetCurrentThread", "Ptr"), "Int64*", &ta := 0, "Int64*", &tb := 0, "Int64*", &tk := 0, "Int64*", &tu := 0)\n'
        b'mcpu := (tk + tu) / 10000\n'
        b'pmc := Buffer(80, 0), NumPut("UInt", 80, pmc)\n'
        b'DllCall("psapi\\GetProcessMemoryInfo", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "Ptr", pmc, "UInt", 80)\n'
        b'mem := Round(NumGet(pmc, 16, "UPtr") / 1048576, 1)\n'
        b'thumbs := 0, withSys := 0, withDps := 0, dpsList := ""\n'
        b'try {\n'
        b'for hwnd, obj in Call.ThumbWindows.OwnProps() {\n'
        b'thumbs++\n'
        b'ov := obj["TextOverlay"]\n'
        b'if (ov["SystemText"].Value != "")\n'
        b'withSys++\n'
        b'if (ov["DpsText"].Value != "")\n'
        b'withDps++, dpsList .= " " ov["OverlayText"].Value "=" ov["DpsText"].Value\n'
        b'}\n'
        b'}\n'
        b'mx := ""\n'
        b'for n, v in DIAGMAX\n'
        b'mx .= Format(" {}={:.1f}ms", n, v)\n'
        b'if (c0 >= 0)\n'
        b'DiagLog(Format("STATS cpu {:.0f} ms/30s ({:.2f}% core; main thread {:.0f} ms, keyboard/mouse hook {:.0f} ms) | mem {} MB | thumbs {} | with system {} | with DPS {} | switches {} | restored-after-late-minimize {} | slow {} | errors {} | longest:{}{}", cpu - c0, (cpu - c0) / 300, mcpu - m0, (cpu - c0) - (mcpu - m0), mem, thumbs, withSys, withDps, DIAG["switch"], DIAG["ensure_restore"], DIAG["slow"], DIAG["errors"], mx, withDps ? " | DPS:" dpsList : ""))\n'
        b'c0 := cpu, m0 := mcpu\n'
        b'for key in ["switch", "ensure_restore", "slow", "errors"]\n'
        b'DIAG[key] := 0\n'
        b'DIAGMAX := Map()\n'
        b'DiagFlush()\n'
        b'}\n'
        b'DiagLog("=== EVE-X-Preview ultimate (diag) started, pid " DllCall("GetCurrentProcessId") " ===")\n'
        b'SetTimer(DiagStats, 30000)\n'
        b'OnExit((*) => DiagFlush())\n'
        b'SetTimer(DiagFlush, 5000)\n',
    ),
    (
        b'Error_Handler(Thrown, Mode) {\n'
        b'return -1\n'
        b'}',
        b'Error_Handler(Thrown, Mode) {\n'
        b'DiagCount("errors")\n'
        b'try DiagLog("ERROR " Thrown.Message " | what: " Thrown.What " | line " Thrown.Line " | extra: " Thrown.Extra " | mode: " Mode)\n'
        b'return -1\n'
        b'}',
    ),
    (
        b'\n'
        b'HandleMainTimer() {\n',
        b'\n'
        b'HandleMainTimer() {\n'
        b'DiagT0 := DiagQPC()\n'
        b'This.HandleMainTimer_Diag()\n'
        b'DiagTime("HandleMainTimer", DiagQPC() - DiagT0)\n'
        b'}\n'
        b'HandleMainTimer_Diag() {\n',
    ),
    (
        b'\n'
        b'UpdateSystemNames() {\n',
        b'\n'
        b'UpdateSystemNames() {\n'
        b'DiagT0 := DiagQPC()\n'
        b'This.UpdateSystemNames_Diag()\n'
        b'DiagTime("UpdateSystemNames", DiagQPC() - DiagT0)\n'
        b'}\n'
        b'UpdateSystemNames_Diag() {\n',
    ),
    (
        b'This.EnsureTarget := hwnd, This.EnsureTries := 0\n',
        b'DiagCount("switch")\n'
        b'This.EnsureTarget := hwnd, This.EnsureTries := 0\n',
    ),
    (
        b'if iconic\n'
        b'This.ShowWindowAsync(hwnd, This.AlwaysMaximize ? 3 : 9)\n',
        b'if iconic {\n'
        b'DiagCount("ensure_restore")\n'
        b'This.ShowWindowAsync(hwnd, This.AlwaysMaximize ? 3 : 9)\n'
        b'}\n',
    ),
    (
        b'DiagT0 := DiagQPC()\n'
        b'This.HandleMainTimer_Diag()\n'
        b'DiagTime("HandleMainTimer", DiagQPC() - DiagT0)\n',
        b'DiagT0 := DiagQPC(), DiagC0 := DiagCyc()\n'
        b'This.HandleMainTimer_Diag()\n'
        b'DiagTime("HandleMainTimer", DiagQPC() - DiagT0, DiagCyc() - DiagC0)\n',
    ),
    (
        b'DiagTime(name, ms) {\n',
        b'DiagCyc() {\n'
        b'DllCall("QueryThreadCycleTime", "Ptr", DllCall("GetCurrentThread", "Ptr"), "UInt64*", &c := 0)\n'
        b'return c / 3.8e6\n'
        b'}\n'
        b'DiagTime(name, ms, cpu := -1) {\n',
    ),
    (
        b'DiagLog(Format("SLOW {} took {:.1f} ms", name, ms))\n',
        b'DiagLog(Format("SLOW {} took {:.1f} ms{}", name, ms, cpu >= 0 ? Format(" (thread CPU ~{:.1f} ms)", cpu) : ""))\n',
    ),
    (
        b'if (ms > 15) {\n',
        b'if (ms > (InStr(name, ".") ? 2 : 15)) {\n',
    ),
    (
        b'WinList := This.GetEVEWindows()\n',
        b'DT := DiagQPC(), WinList := This.GetEVEWindows(), DiagTime("HMT.GetEVEWindows", DiagQPC() - DT)\n',
    ),
    (
        b'WinList.%hwnd% := { Title: This.FastTitle(hwnd) }\n',
        b'DT := DiagQPC(), WinList.%hwnd% := { Title: This.FastTitle(hwnd) }, DiagTime("HMT.FastTitle", DiagQPC() - DT)\n',
    ),
    (
        b'EVEActive := This.ForegroundEVE()\n',
        b'DT := DiagQPC(), EVEActive := This.ForegroundEVE(), DiagTime("HMT.ForegroundEVE", DiagQPC() - DT)\n',
    ),
    (
        b'WinSetAlwaysOnTop(1,This.ThumbWindows.%Ahwnd%["Window"].Hwnd )\n',
        b'DT := DiagQPC(), WinSetAlwaysOnTop(1,This.ThumbWindows.%Ahwnd%["Window"].Hwnd ), DiagTime("HMT.AlwaysOnTop", DiagQPC() - DT)\n',
    ),
    (
        b'This.ShowActiveBorder(Ahwnd)\n',
        b'DT := DiagQPC(), DC := DiagCyc(), This.ShowActiveBorder(Ahwnd), DiagTime("HMT.ShowActiveBorder", DiagQPC() - DT, DiagCyc() - DC)\n',
    ),
    (
        b'This.UpdateThumb_AfterActivation(, Ahwnd)\n',
        b'DT := DiagQPC(), DC := DiagCyc(), This.UpdateThumb_AfterActivation(, Ahwnd), DiagTime("HMT.UpdateThumb", DiagQPC() - DT, DiagCyc() - DC)\n',
    ),
    (
        b'if (WinList.Length) {\n'
        b'try {\n'
        b'for index, hwnd in WinList {\n',
        b'DTL := DiagQPC()\n'
        b'if (WinList.Length) {\n'
        b'try {\n'
        b'for index, hwnd in WinList {\n',
    ),
    (
        b'catch\n'
        b'return\n'
        b'try {\n'
        b'DT := DiagQPC(), EVEActive := This.ForegroundEVE()',
        b'catch\n'
        b'return\n'
        b'DiagTime("HMT.Loop", DiagQPC() - DTL)\n'
        b'DTA := DiagQPC()\n'
        b'try {\n'
        b'DT := DiagQPC(), EVEActive := This.ForegroundEVE()',
    ),
    (
        b'if ( This.DestroyThumbnailsToggle ) {\n',
        b'DiagTime("HMT.Active", DiagQPC() - DTA)\n'
        b'if ( This.DestroyThumbnailsToggle ) {\n',
    ),
]
