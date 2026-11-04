import sys, io, struct, shutil, colorsys, ctypes, pefile
from ctypes import wintypes
from PIL import Image
SRC, OUT, HUE, CLS = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]

def recolor(im, keep_hue):
    im=im.convert('RGBA'); px=im.load(); W,H=im.size
    for y in range(H):
        for x in range(W):
            r,g,b,a=px[x,y]
            if a==0: continue
            h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
            if s>0.35:
                if keep_hue: r2,g2,b2=r/255,g/255,b/255
                else: r2,g2,b2=colorsys.hsv_to_rgb(HUE,min(1,s*0.95),min(1,v*1.08))
            elif v>0.38:
                t=(v-0.38)/0.62
                r2,g2,b2=colorsys.hsv_to_rgb(HUE,0.15,0.03+0.11*t)
            else:
                r2,g2,b2=colorsys.hsv_to_rgb(0.62 if keep_hue else HUE,0.45,0.18+v*0.55)
            px[x,y]=(int(r2*255),int(g2*255),int(b2*255),a)
    return im

pe=pefile.PE(SRC)
icons={}; groups={}; script=None
for t in pe.DIRECTORY_ENTRY_RESOURCE.entries:
    for n in t.directory.entries:
        for l in n.directory.entries:
            d=pe.get_data(l.data.struct.OffsetToData,l.data.struct.Size)
            if t.id==3: icons[n.id]=d
            elif t.id==14: groups[n.id]=d
            elif t.id==10 and n.id==1: script=d
pe.close()

def patch(s, old, new):
    assert s.count(old)==1, old
    return s.replace(old, new)
# 1) high priority
s=patch(script, b'if !(A_IsCompiled)\nTraySetIcon("icon.ico",,true)\n',
        b'; Wysoki priorytet procesu w Windows\nProcessSetPriority("High")\nif !(A_IsCompiled)\nTraySetIcon("icon.ico",,true)\n')
# 2) second line with the system under the character name
s=patch(s, b'ThumbTitle.Opt("+Background040101")\n',
        b'ThumbTitle.Opt("+Background040101")\n'
        b'ThumbObj["TextOverlay"].SetFont("s" Max(6, This.ThumbnailTextSize - 2))\n'
        b'SysText := ThumbObj["TextOverlay"].Add("Text", "vSystemText y+0 w" This.ThumbnailStartLocation["width"], "")\n'
        b'SysText.Opt("+Background040101")\n')
# 3) a character name change only overwrites the name line, not the system
s=patch(s, b'cobj.Value := newtext\n', b'if (cobj.Name = "OverlayText")\ncobj.Value := newtext\n')
# 4) timer refreshing the system
s=patch(s, b'SetTimer(ObjBindMethod(This, "HandleMainTimer"), 50)\n',
        b'SetTimer(ObjBindMethod(This, "HandleMainTimer"), 50)\nSetTimer(ObjBindMethod(This, "UpdateSystemNames"), 1000)\n')
s=patch(s, b'HandleMainTimer() {\n',
        b'UpdateSystemNames() {\n'
        b'static lastScan := 0\n'
        b'if (!lastScan || A_TickCount - lastScan > 5000) {\n'
        b'lastScan := A_TickCount\n'
        b'EVE_LocalSystem.Scan()\n'
        b'}\n'
        b'for hwnd, obj in This.ThumbWindows.OwnProps() {\n'
        b'try {\n'
        b'name := obj["Window"].Title\n'
        b'sys := (name != "") ? EVE_LocalSystem.Get(name) : ""\n'
        b'ctrl := obj["TextOverlay"]["SystemText"]\n'
        b'if (ctrl.Value != sys)\n'
        b'ctrl.Value := sys\n'
        b'}\n'
        b'}\n'
        b'}\n'
        b'HandleMainTimer() {\n')

# ===== OPTIMIZATIONS =====
# 1) fast search for EVE windows
s=patch(s, b'try\nWinList := WinGetList(This.EVEExe)\nCatch\nreturn\n',
        b'try\nWinList := This.GetEVEWindows()\nCatch\nreturn\n')
# 3) title: regex only when the title changed
s=patch(s, b'WinList.%hwnd% := { Title: This.CleanTitle(WinGetTitle(hwnd)) }\n',
        b'WinList.%hwnd% := { Title: This.FastTitle(hwnd) }\n')
# 2) active window without checking the process every 50 ms
s=patch(s, b'ActiveProcessName := WinGetProcessName("A")\n'
           b'if ((DllCall("IsIconic","UInt", WinActive("ahk_exe exefile.exe")) || ActiveProcessName != "exefile.exe") && !HideShowToggle && This.HideThumbnailsOnLostFocus) {\n',
        b'EVEActive := This.ForegroundEVE()\n'
        b'ActiveProcessName := EVEActive ? "exefile.exe" : ""\n'
        b'if ((DllCall("IsIconic","Ptr", EVEActive) || ActiveProcessName != "exefile.exe") && !HideShowToggle && This.HideThumbnailsOnLostFocus) {\n')
s=patch(s, b'else if ( ActiveProcessName = "exefile.exe" && !DllCall("IsIconic","UInt", WinActive("ahk_exe exefile.exe"))) {\nAhwnd := WinExist("A")\n',
        b'else if ( ActiveProcessName = "exefile.exe" && !DllCall("IsIconic","Ptr", EVEActive)) {\nAhwnd := EVEActive\n')
# 4) no copying of the thumbnail list every 50 ms
s=patch(s, b'for k, v in This.ThumbWindows.Clone().OwnProps() {\nif !Winlist.HasProp(k) {\nSetTimer(This.DestroyThumbnails, -500)\nThis.DestroyThumbnailsToggle := 0\n}\n}\n',
        b'for k, v in This.ThumbWindows.OwnProps() {\nif !Winlist.HasProp(k) {\nSetTimer(This.DestroyThumbnails, -500)\nThis.DestroyThumbnailsToggle := 0\nbreak\n}\n}\n')
# helper methods
s=patch(s, b'UpdateSystemNames() {\n',
        b'GetEVEWindows() {\n'
        b'static cache := Map()\n'
        b'list := [], hwnd := 0\n'
        b'if (cache.Count > 500)\n'
        b'cache.Clear()\n'
        b'while (hwnd := DllCall("FindWindowExW", "Ptr", 0, "Ptr", hwnd, "Str", "trinityWindow", "Ptr", 0, "Ptr")) {\n'
        b'if !DllCall("IsWindowVisible", "Ptr", hwnd)\n'
        b'continue\n'
        b'if !cache.Has(hwnd) {\n'
        b'try\n'
        b'cache[hwnd] := (WinGetProcessName(hwnd) = "exefile.exe")\n'
        b'catch\n'
        b'continue\n'
        b'}\n'
        b'if cache[hwnd]\n'
        b'list.Push(hwnd)\n'
        b'}\n'
        b'return list\n'
        b'}\n'
        b'ForegroundEVE() {\n'
        b'static lastFg := 0, lastIsEVE := 0\n'
        b'fg := DllCall("GetForegroundWindow", "Ptr")\n'
        b'if (!fg || !DllCall("IsWindowVisible", "Ptr", fg))\n'
        b'throw Error("no active window")\n'
        b'if (fg != lastFg) {\n'
        b'lastIsEVE := (WinGetProcessName(fg) = "exefile.exe")\n'
        b'lastFg := fg\n'
        b'}\n'
        b'return lastIsEVE ? fg : 0\n'
        b'}\n'
        b'FastTitle(hwnd) {\n'
        b'static cache := Map()\n'
        b'raw := WinGetTitle(hwnd)\n'
        b'if (cache.Has(hwnd) && cache[hwnd][1] == raw)\n'
        b'return cache[hwnd][2]\n'
        b'if (cache.Count > 500)\n'
        b'cache.Clear()\n'
        b'clean := This.CleanTitle(raw)\n'
        b'cache[hwnd] := [raw, clean]\n'
        b'return clean\n'
        b'}\n'
        b'UpdateSystemNames() {\n')
# ===== FAST SWITCHING OPTIMIZATIONS =====
# A) activation without the 10 ms SendEvent delays
s=patch(s, b'SendEvent("{Blind}{" Main_Class.virtualKey "}")\n',
        b'SetKeyDelay(-1, -1)\nSendEvent("{Blind}{" Main_Class.virtualKey "}")\n')
# B) immediate reaction to an active window change (instead of waiting for the timer)
s=patch(s, b'SetTimer(ObjBindMethod(This, "UpdateSystemNames"), 1000)\n',
        b'SetTimer(ObjBindMethod(This, "UpdateSystemNames"), 1000)\n'
        b'This.FgNow := ObjBindMethod(This, "HandleMainTimer")\n'
        b'This.FgHookCB := CallbackCreate(ObjBindMethod(This, "OnForegroundEvent"), , 7)\n'
        b'This.FgHook := DllCall("SetWinEventHook", "UInt", 3, "UInt", 3, "Ptr", 0, "Ptr", This.FgHookCB, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr")\n')
s=patch(s, b'HandleMainTimer() {\n',
        b'OnForegroundEvent(*) {\n'
        b'This.HandleMainTimer()\n'
        b'}\n'
        b'HandleMainTimer() {\n'
        b'static busy := 0\n'
        b'if busy\n'
        b'return\n'
        b'busy := 1\n'
        b'try {\n'
        b'This.HandleMainTimer_Body()\n'
        b'}\n'
        b'finally {\n'
        b'busy := 0\n'
        b'}\n'
        b'}\n'
        b'HandleMainTimer_Body() {\n')
# C) minimizing: skip windows already minimized, active window computed once
s=patch(s, b'EVEMinimize() {\nfor EveHwnd, GuiObj in This.ThumbWindows.OwnProps() {\nThumbHwnd := GuiObj["Window"].Hwnd\n',
        b'EVEMinimize() {\nActiveNow := WinExist("A")\nfor EveHwnd, GuiObj in This.ThumbWindows.OwnProps() {\nThumbHwnd := GuiObj["Window"].Hwnd\nif DllCall("IsIconic", "Ptr", EveHwnd)\ncontinue\n')
s=patch(s, b'if !(EveHwnd = WinExist("A")) {\nThis.ShowWindowAsync(EveHwnd, 11)\n',
        b'if !(EveHwnd = ActiveNow) {\nThis.ShowWindowAsync(EveHwnd, 11)\n')

# D) reliable activation: if a late minimize "took" the client, bring it back
s=patch(s, b'This.FgNow := ObjBindMethod(This, "HandleMainTimer")\n',
        b'This.FgNow := ObjBindMethod(This, "HandleMainTimer")\n'
        b'This.EnsureTimer := ObjBindMethod(This, "EnsureActivation")\n'
        b'This.EnsureTarget := 0, This.EnsureTries := 0\n')
s=patch(s, b'if (This.MinimizeInactiveClients) {\nThis.wHwnd := hwnd\nSetTimer(This.timer, -This.MinimizeDelay)\n}\n}\n',
        b'if (This.MinimizeInactiveClients) {\nThis.wHwnd := hwnd\nSetTimer(This.timer, -This.MinimizeDelay)\n}\n'
        b'This.EnsureTarget := hwnd, This.EnsureTries := 0\n'
        b'SetTimer(This.EnsureTimer, -60)\n'
        b'}\n')
s=patch(s, b'ActivateForgroundWindow(*) {\n',
        b'EnsureActivation() {\n'
        b'hwnd := This.EnsureTarget\n'
        b'if (!hwnd || !WinExist("ahk_id " hwnd))\n'
        b'return\n'
        b'if (++This.EnsureTries > 6)\n'
        b'return\n'
        b'SetTimer(This.EnsureTimer, -60)\n'
        b'fg := DllCall("GetForegroundWindow", "Ptr")\n'
        b'iconic := DllCall("IsIconic", "Ptr", hwnd)\n'
        b'if (fg = hwnd && !iconic)\n'
        b'return\n'
        b'if (fg && !This.ThumbWindows.HasProp(fg)) {\n'
        b'This.EnsureTarget := 0\n'
        b'return\n'
        b'}\n'
        b'if iconic\n'
        b'This.ShowWindowAsync(hwnd, This.AlwaysMaximize ? 3 : 9)\n'
        b'else if (This.EnsureTries = 1) {\n'
        b'This.ActivateHwnd := hwnd\n'
        b'SetKeyDelay(-1, -1)\n'
        b'SendEvent("{Blind}{" Main_Class.virtualKey "}")\n'
        b'}\n'
        b'}\n'
        b'ActivateForgroundWindow(*) {\n')

# E) labels: name on top and system in the middle, scaled to full width, always white
s=patch(s, b'\nGetEVEWindows() {\n',
        b'\nLayoutAllOverlays() {\n'
        b'for hwnd, obj in This.ThumbWindows.OwnProps() {\n'
        b'try This.LayoutOverlay(obj)\n'
        b'}\n'
        b'}\n'
        b'LayoutOverlay(obj) {\n'
        b'static cache := Map()\n'
        b'ov := obj["TextOverlay"]\n'
        b'WinGetClientPos(, , &W, &H, ov.Hwnd)\n'
        b'nameCtrl := ov["OverlayText"], sysCtrl := ov["SystemText"]\n'
        b'name := nameCtrl.Value, sys := sysCtrl.Value, font := This.ThumbnailTextFont\n'
        b'sig := W "|" H "|" name "|" sys "|" font\n'
        b'if (cache.Has(ov.Hwnd) && cache[ov.Hwnd] == sig)\n'
        b'return\n'
        b'cache[ov.Hwnd] := sig\n'
        b'pad := Max(2, Round(W * 0.04))\n'
        b'availW := W - 2 * pad\n'
        b'ov.Opt("-DPIScale")\n'
        b'n := FitOverlayText(name, font, availW, H * 0.30)\n'
        b'nameCtrl.SetFont("s" n.pt " q6 w700 cFFFFFF", font)\n'
        b'nameCtrl.Opt("+Center")\n'
        b'nameCtrl.Move(pad, Max(1, Round(H * 0.02)), availW, n.h + 2)\n'
        b'm := FitOverlayText(sys, font, availW, Max(8, H - 2 * (Max(1, Round(H * 0.02)) + Round(H * 0.30) + 2)))\n'
        b'sysCtrl.SetFont("s" m.pt " q6 w700 cFFFFFF", font)\n'
        b'sysCtrl.Opt("+Center")\n'
        b'sysCtrl.Move(pad, Round((H - m.h) / 2), availW, m.h + 2)\n'
        b'}\n'
        b'GetEVEWindows() {\n')
# recalculate after a thumbnail is created (new characters)
s=patch(s, b'This.RegisterHotkeys(Win_Title, Win_Hwnd)\n}\n}\nEvEWindowDestroy(',
        b'This.LayoutAllOverlays()\nThis.RegisterHotkeys(Win_Title, Win_Hwnd)\n}\n}\nEvEWindowDestroy(')
# recalculate while thumbnails are being resized
s=patch(s, b'This.Update_Thumb()\n}\n}\n}\nWindow_Snap(hwnd',
        b'This.Update_Thumb()\n}\nThis.LayoutAllOverlays()\n}\n}\nWindow_Snap(hwnd')
# every second (character / system / size change)
s=patch(s, b'if (ctrl.Value != sys)\nctrl.Value := sys\n}\n}\n}\n',
        b'if (ctrl.Value != sys)\nctrl.Value := sys\n}\n}\nThis.LayoutAllOverlays()\n}\n')
# text measuring functions (global)
s=patch(s, b'Class LiveThumb',
        b'MeasureOverlayText(text, font, pt) {\n'
        b'hdc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")\n'
        b'hf := DllCall("CreateFontW", "Int", -Round(pt * A_ScreenDPI / 72), "Int", 0, "Int", 0, "Int", 0, "Int", 700, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 1, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0, "Str", font, "Ptr")\n'
        b'old := DllCall("SelectObject", "Ptr", hdc, "Ptr", hf, "Ptr")\n'
        b'sz := Buffer(8, 0)\n'
        b'DllCall("GetTextExtentPoint32W", "Ptr", hdc, "Str", text, "Int", StrLen(text), "Ptr", sz)\n'
        b'DllCall("SelectObject", "Ptr", hdc, "Ptr", old)\n'
        b'DllCall("DeleteObject", "Ptr", hf)\n'
        b'DllCall("DeleteDC", "Ptr", hdc)\n'
        b'return {w: NumGet(sz, 0, "Int"), h: NumGet(sz, 4, "Int")}\n'
        b'}\n'
        b'FitOverlayText(text, font, maxW, maxH) {\n'
        b'if (text = "" || maxW < 4)\n'
        b'return {pt: 6, h: 0}\n'
        b'm := MeasureOverlayText(text, font, 100)\n'
        b'pt := Max(4, Floor(Min(100 * maxW / Max(1, m.w), 100 * maxH / Max(1, m.h))))\n'
        b'Loop 6 {\n'
        b'm := MeasureOverlayText(text, font, pt)\n'
        b'if (m.w <= maxW || pt <= 4)\n'
        b'break\n'
        b'pt -= 1\n'
        b'}\n'
        b'return {pt: pt, h: m.h}\n'
        b'}\n'
        b'Class LiveThumb', )
cls=open(CLS,'rb').read().replace(b'\r\n',b'\n')
s=patch(s, b'Class LiveThumb', cls+b'Class LiveThumb')
open(OUT+'.ahk','wb').write(s)

shutil.copyfile(SRC, OUT)
k=ctypes.WinDLL('kernel32', use_last_error=True)
k.BeginUpdateResourceW.restype=wintypes.HANDLE
k.BeginUpdateResourceW.argtypes=[wintypes.LPCWSTR, wintypes.BOOL]
k.UpdateResourceW.argtypes=[wintypes.HANDLE, ctypes.c_void_p, ctypes.c_void_p, wintypes.WORD, ctypes.c_char_p, wintypes.DWORD]
k.EndUpdateResourceW.argtypes=[wintypes.HANDLE, wintypes.BOOL]
h=k.BeginUpdateResourceW(OUT, False); assert h, ctypes.get_last_error()
def upd(typ, rid, data):
    assert k.UpdateResourceW(h, typ, rid, 1033, data, len(data)), ctypes.get_last_error()
for gid, g in groups.items():
    keep = gid in (206, 208)
    _,_,cnt=struct.unpack('<HHH',g[:6]); entries=[]
    for i in range(cnt):
        w,hh,c,r,pl,bc,sz,iid=struct.unpack('<BBBBHHIH',g[6+i*14:20+i*14])
        d=icons[iid]
        ico=struct.pack('<HHH',0,1,1)+struct.pack('<BBBBHHII',w,hh,c,r,pl,bc,len(d),22)+d
        im=Image.open(io.BytesIO(ico)); im.load()
        buf=io.BytesIO(); recolor(im,keep).save(buf,'PNG'); png=buf.getvalue()
        upd(3, iid, png)
        entries.append(struct.pack('<BBBBHHIH',w,hh,0,0,1,32,len(png),iid))
    upd(14, gid, struct.pack('<HHH',0,1,cnt)+b''.join(entries))
upd(10, 1, s)
assert k.EndUpdateResourceW(h, False), ctypes.get_last_error()
print('ok')
