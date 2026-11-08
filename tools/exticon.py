import sys, struct, pefile, io
from PIL import Image
pe=pefile.PE(sys.argv[1]); out=sys.argv[2]
icons={}; groups=[]
for t in pe.DIRECTORY_ENTRY_RESOURCE.entries:
    for n in t.directory.entries:
        for l in n.directory.entries:
            d=pe.get_data(l.data.struct.OffsetToData,l.data.struct.Size)
            if t.id==3: icons[n.id]=d
            if t.id==14: groups.append((str(n.name) if n.name else n.id,d))
print('groups',[g[0] for g in groups],'icons',len(icons))
for gname,g in groups:
    _,_,cnt=struct.unpack('<HHH',g[:6])
    for i in range(cnt):
        w,h,c,r,pl,bc,sz,iid=struct.unpack('<BBBBHHIH',g[6+i*14:20+i*14])
        d=icons[iid]
        print(gname,i,w or 256,h or 256,bc,len(d),'png' if d[:4]==b'\x89PNG' else 'bmp')
        # write single-image ico for PIL
        ico=struct.pack('<HHH',0,1,1)+struct.pack('<BBBBHHII',w,h,c,r,pl,bc,len(d),22)+d
        try:
            im=Image.open(io.BytesIO(ico)); im.load(); im=im.convert('RGBA')
            im.save(f'{out}/g{gname}_{w or 256}_{bc}.png')
        except Exception as e: print('fail',e)
