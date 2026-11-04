import sys, colorsys
from PIL import Image
im=Image.open(sys.argv[1]).convert('RGBA'); px=im.load(); W,H=im.size
from collections import Counter
cats=Counter()
for y in range(H):
    for x in range(W):
        r,g,b,a=px[x,y]
        if a==0: continue
        h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
        if s>0.35 and (h<0.08 or h>0.9):      # red X
            cats['x']+=1
            nh=0.78                             # purple
            nv=min(1,v*1.08); ns=min(1,s*0.95)
            r2,g2,b2=colorsys.hsv_to_rgb(nh,ns,nv)
        elif v>0.38:                            # light background
            cats['bg']+=1
            t=(v-0.38)/0.62                     # keep the soft gradient
            nv=0.03+0.11*t
            r2,g2,b2=colorsys.hsv_to_rgb(0.78,0.15,nv)
        else:                                   # dark shadow/edge of the X and frame
            cats['dark']+=1
            nv=0.18+v*0.55
            r2,g2,b2=colorsys.hsv_to_rgb(0.78,0.45,nv)
        px[x,y]=(int(r2*255),int(g2*255),int(b2*255),a)
print(cats)
im.save(sys.argv[2])
