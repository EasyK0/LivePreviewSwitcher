# One build script for all EVE-X-Preview variants (except the original).
#
#   python build\build.py                  -> builds High, Systems, Ultimate, Test into dist\ and copies them to ..\EVE-X
#   python build\build.py Test             -> only the named variants
#   python build\build.py --no-install     -> dist\ only, no copy to ..\EVE-X
#
# Each exe = the original EVE-X-Preview.exe + the AHK script from src\ (resource RCDATA #1) + recolored icons.
# Test = the Ultimate script + the diagnostic layer from build\diag_patches.py (the only variant with a log).
import sys, os, io, struct, shutil, colorsys, ctypes, hashlib, argparse
from ctypes import wintypes
import pefile
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'build'))
import diag_patches

# name: (source file in src\, icon hue 0-1 or 'mono', add the diagnostic log or not)
VARIANTS = {
    'High':     ('EVE-X-Preview-High.ahk',    0.78,   False),
    'Systems':  ('EVE-X-Preview-Systems.ahk', 0.34,   False),
    'Ultimate': ('EVE-X-Preview.ahk',         0.995,  False),
    'Test':     ('EVE-X-Preview.ahk',         'mono', True),
}
KEEP_GROUPS = (206, 208)    # blue "suspend" state icons; recolored in Test too


def recolor(im, hue, keep_hue):
    mono = hue == 'mono'
    im = im.convert('RGBA'); px = im.load(); W, H = im.size
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0: continue
            h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
            if mono:                                      # black X on a white background
                if s > 0.35: c = 0.04*v
                elif keep_hue or v > 0.38: c = 0.92 + 0.08*v
                else: c = 0.15 + v*0.35
                px[x, y] = (int(c*255),)*3 + (a,)
                continue
            if s > 0.35:                                  # X
                if keep_hue: r2, g2, b2 = r/255, g/255, b/255
                else: r2, g2, b2 = colorsys.hsv_to_rgb(hue, min(1, s*0.95), min(1, v*1.08))
            elif v > 0.38:                                # background -> dark
                t = (v - 0.38)/0.62
                r2, g2, b2 = colorsys.hsv_to_rgb(hue, 0.15, 0.03 + 0.11*t)
            else:                                         # X shadow
                r2, g2, b2 = colorsys.hsv_to_rgb(0.62 if keep_hue else hue, 0.45, 0.18 + v*0.55)
            px[x, y] = (int(r2*255), int(g2*255), int(b2*255), a)
    return im


def read_resources(exe):
    pe = pefile.PE(exe)
    icons, groups = {}, {}
    for t in pe.DIRECTORY_ENTRY_RESOURCE.entries:
        for n in t.directory.entries:
            for l in n.directory.entries:
                d = pe.get_data(l.data.struct.OffsetToData, l.data.struct.Size)
                if t.id == 3: icons[n.id] = d
                elif t.id == 14: groups[n.id] = d
    pe.close()
    return icons, groups


def load_script(name):
    src, _, diag = VARIANTS[name]
    s = open(os.path.join(ROOT, 'src', src), 'rb').read().replace(b'\r\n', b'\n')
    if diag:
        for old, new in diag_patches.PATCHES:
            assert s.count(old) == 1, old
            s = s.replace(old, new)
    return s


def build(name, base, out):
    hue = VARIANTS[name][1]
    script = load_script(name)
    icons, groups = read_resources(base)
    shutil.copyfile(base, out)
    k = ctypes.WinDLL('kernel32', use_last_error=True)
    k.BeginUpdateResourceW.restype = wintypes.HANDLE
    k.BeginUpdateResourceW.argtypes = [wintypes.LPCWSTR, wintypes.BOOL]
    k.UpdateResourceW.argtypes = [wintypes.HANDLE, ctypes.c_void_p, ctypes.c_void_p, wintypes.WORD, ctypes.c_char_p, wintypes.DWORD]
    k.EndUpdateResourceW.argtypes = [wintypes.HANDLE, wintypes.BOOL]
    h = k.BeginUpdateResourceW(out, False); assert h, ctypes.get_last_error()
    def upd(typ, rid, data):
        assert k.UpdateResourceW(h, typ, rid, 1033, data, len(data)), ctypes.get_last_error()
    for gid, g in groups.items():
        keep = gid in KEEP_GROUPS
        _, _, cnt = struct.unpack('<HHH', g[:6]); entries = []
        for i in range(cnt):
            w, hh, c, r, pl, bc, sz, iid = struct.unpack('<BBBBHHIH', g[6+i*14:20+i*14])
            d = icons[iid]
            ico = struct.pack('<HHH', 0, 1, 1) + struct.pack('<BBBBHHII', w, hh, c, r, pl, bc, len(d), 22) + d
            im = Image.open(io.BytesIO(ico)); im.load()
            buf = io.BytesIO(); recolor(im, hue, keep).save(buf, 'PNG'); png = buf.getvalue()
            upd(3, iid, png)
            entries.append(struct.pack('<BBBBHHIH', w, hh, 0, 0, 1, 32, len(png), iid))
        upd(14, gid, struct.pack('<HHH', 0, 1, cnt) + b''.join(entries))
    upd(10, 1, script)
    assert k.EndUpdateResourceW(h, False), ctypes.get_last_error()


def sha(path):
    return hashlib.sha256(open(path, 'rb').read()).hexdigest().upper()


def main():
    ap = argparse.ArgumentParser(description='Builds the EVE-X-Preview variants.')
    ap.add_argument('variants', nargs='*', help='High, Systems, Ultimate, Test (default: all)')
    ap.add_argument('--target', default=os.path.join(os.path.dirname(ROOT), 'EVE-X'), help='folder with the original EVE-X-Preview.exe, built exes are copied there (default: EVE-X next to this repo)')
    ap.add_argument('--no-install', action='store_true', help='do not copy the built exes to the target folder')
    a = ap.parse_args()
    names = a.variants or list(VARIANTS)
    for n in names:
        if n not in VARIANTS: ap.error(f'unknown variant {n}; available: {", ".join(VARIANTS)}')
    base = os.path.join(a.target, 'EVE-X-Preview.exe')      # original v1.0.4, read only
    dist = os.path.join(ROOT, 'dist'); os.makedirs(dist, exist_ok=True)
    failed = False
    for n in names:
        fname = f'EVE-X-Preview-{n}.exe'
        out = os.path.join(dist, fname)
        build(n, base, out)
        line = f'{fname:28} {sha(out)[:16]}'
        if not a.no_install:
            dst = os.path.join(a.target, fname)
            if os.path.exists(dst) and sha(dst) == sha(out):
                line += '  unchanged'
            else:
                try:
                    shutil.copyfile(out, dst); line += '  copied to ' + a.target
                except PermissionError:
                    line += '  NOT copied: the program is running, close it and build again'
                    failed = True
        print(line)
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
