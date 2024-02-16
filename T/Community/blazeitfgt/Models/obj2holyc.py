#!/bin/env python3

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("file")
parser.add_argument("name")
parser.add_argument('mode', help='obj parsing mode', nargs='?', choices=('line', 'face', 'obj'), default='line')
args = parser.parse_args()

objFile = open(args.file)
obj = objFile.read()
objFile.close()

verts = []
lines = []
objs = []
faces = []
obj = obj.splitlines()
for line in obj:
    if line[0:2] == 'v ':
        sl = line[2:].split()
        verts.append((int(round(float(sl[0]))), int(round(float(sl[1]))), int(round(float(sl[2])))))
    elif line[0:2] == 'l ':
        sl = line[2:].split()
        lines.append((int(sl[0])-1, int(sl[1])-1))
    elif line[0:2] == 'f ':
        sl = line[2:].split()
        faces.append((int(sl[0])-1, int(sl[1])-1, int(sl[2])-1))

output = f"#ifndef {args.name}_HC\n#define {args.name}_HC\n\n"

if args.mode == 'obj':
    for li,line in enumerate(obj):
        if line[0:2] == 'o ':
            if (len(objs) > 0):
                objs[len(objs)-1]["e"] = li
            objs.append({"n": line[2:], "s": li})
    objs[len(objs)-1]["e"] = len(obj);
    for o in objs:
      o["v"] = []
      o["l"] = []
      for i in range(o["s"]+1, o["e"]):
          if obj[i][0:2] == 'v ':
              sl = obj[i][2:].split()
              o["v"].append((int(float(sl[0])), int(float(sl[1])), int(float(sl[2]))))
          elif obj[i][0:2] == 'l ':
              sl = obj[i][2:].split()
              o["l"].append((int(sl[0])-1, int(sl[1])-1))

    output = f"#define {args.name}_parts {len(objs)}\nI64 {args.name}_cnts[{len(objs)}];\nCD3I32 *{args.name}[{len(objs)}];\n"
    for oi, o in enumerate(objs):
        output += f"CD3I32 {args.name}_{oi}[{len(o['l'])*2}];\n"
        i = 0
        for li, line in enumerate(o['l']):
            output += f"{args.name}_{oi}[{i}].x={o['v'][lines[li][0]][0]};{args.name}_{oi}[{i}].y={o['v'][lines[li][0]][1]};{args.name}_{oi}[{i}].z={o['v'][lines[li][0]][2]};\n"
            i += 1
            output += f"{args.name}_{oi}[{i}].x={o['v'][lines[li][1]][0]};{args.name}_{oi}[{i}].y={o['v'][lines[li][1]][1]};{args.name}_{oi}[{i}].z={o['v'][lines[li][1]][2]};\n"
            i += 1
        output += f"{args.name}_cnts[{oi}] = {len(o['l'])*2};\n{args.name}[{oi}] = {args.name}_{oi};\n"
elif args.mode == 'face':
    output += f"#define {args.name}_tris {len(faces)}\nCD3I32 {args.name}[{args.name}_tris][3];\n"
    for ti, tri in enumerate(faces):
        output += f"{args.name}[{ti}][0].x={verts[tri[0]][0]};{args.name}[{ti}][0].y={verts[tri[0]][1]};{args.name}[{ti}][0].z={verts[tri[0]][2]};\n";
        output += f"{args.name}[{ti}][1].x={verts[tri[1]][0]};{args.name}[{ti}][1].y={verts[tri[1]][1]};{args.name}[{ti}][1].z={verts[tri[1]][2]};\n";
        output += f"{args.name}[{ti}][2].x={verts[tri[2]][0]};{args.name}[{ti}][2].y={verts[tri[2]][1]};{args.name}[{ti}][2].z={verts[tri[2]][2]};\n";
        #output += f"{args.name}[{ti}][1].x={verts[tri[1]]};{args.name}[{ti}][1].y={verts[tri[0][1]]};{args.name}[{ti}][1].z={verts[tri[1][2]]};\n";
        #output += f"{args.name}[{ti}][2].x={verts[tri[2]]};{args.name}[{ti}][2].y={verts[tri[0][1]]};{args.name}[{ti}][2].z={verts[tri[2][2]]};\n";
else:
    output += f"#define {args.name}_cnt {len(lines)*2}\nCD3I32 {args.name}[{args.name}_cnt];\n"
    i = 0
    for li,line in enumerate(lines):
        output += f"{args.name}[{i}].x={verts[lines[li][0]][0]};{args.name}[{i}].y={verts[lines[li][0]][1]};{args.name}[{i}].z={verts[lines[li][0]][2]};\n"
        i += 1
        output += f"{args.name}[{i}].x={verts[lines[li][1]][0]};{args.name}[{i}].y={verts[lines[li][1]][1]};{args.name}[{i}].z={verts[lines[li][1]][2]};\n"
        i += 1


output += "\n#endif\n"

out = open(f"{args.name}.HC", 'w')
out.write(output)
out.close()
