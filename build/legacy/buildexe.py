import sys, io, struct, shutil, colorsys, ctypes, pefile
from ctypes import wintypes
from PIL import Image
SRC, OUT = sys.argv[1], sys.argv[2]

def recolor(im, keep_hue):
    im=im.convert('RGBA'); px=im.load(); W,H=im.size
    for y in range(H):
        for x in range(W):
            r,g,b,a=px[x,y]
            if a==0: continue
            h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
            if s>0.35:                                   # X
                if keep_hue: r2,g2,b2=r/255,g/255,b/255
                else: r2,g2,b2=colorsys.hsv_to_rgb(0.78,min(1,s*0.95),min(1,v*1.08))
                tint=h if keep_hue else 0.78
            elif v>0.38:                                 # background -> black
                t=(v-0.38)/0.62
                r2,g2,b2=colorsys.hsv_to_rgb(0.78,0.15,0.03+0.11*t)
            else:                                        # X shadow
                r2,g2,b2=colorsys.hsv_to_rgb(0.62 if keep_hue else 0.78,0.45,0.18+v*0.55)
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

old=b'if !(A_IsCompiled)\nTraySetIcon("icon.ico",,true)\n'
assert script.count(old)==1
script=script.replace(old, b'; High process priority in Windows\nProcessSetPriority("High")\n'+old)

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
    keep = gid in (206, 208)   # blue suspend icons stay as they are
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
upd(10, 1, script)
assert k.EndUpdateResourceW(h, False), ctypes.get_last_error()
print('ok', OUT)
