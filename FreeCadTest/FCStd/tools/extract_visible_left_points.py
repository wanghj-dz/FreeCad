#!/usr/bin/env python3
"""
提取 Document.xml 中的 GeomPoint，并计算左视图可见点（按 Y,Z 分组，取最小 X）。
输出 JSON: left_view_points.json
"""
import xml.etree.ElementTree as ET
import json
import os

xml_path = r"d:\FreeCad\FreeCadTest\FCStd\123_extracted\Document.xml"
out_json = r"d:\FreeCad\FreeCadTest\FCStd\left_view_points.json"

if not os.path.exists(xml_path):
    print('Document.xml 未找到：', xml_path)
    raise SystemExit(1)

tree = ET.parse(xml_path)
root = tree.getroot()

points = []
# 查找所有 GeomPoint 子元素
for gp in root.findall('.//GeomPoint'):
    x = gp.get('X') or gp.get('x')
    y = gp.get('Y') or gp.get('y')
    z = gp.get('Z') or gp.get('z')
    try:
        xf = float(x)
        yf = float(y)
        zf = float(z)
        points.append((xf,yf,zf))
    except Exception:
        continue

# 也查找 Geometry elements that may have GeomPoint as child under Geometry nodes
for geom in root.findall('.//Geometry'):
    for child in geom:
        if child.tag == 'GeomPoint':
            x = child.get('X') or child.get('x')
            y = child.get('Y') or child.get('y')
            z = child.get('Z') or child.get('z')
            try:
                xf = float(x); yf = float(y); zf = float(z)
                points.append((xf,yf,zf))
            except Exception:
                pass

# Deduplicate
uniq = {}
for p in points:
    key = (round(p[0],6), round(p[1],6), round(p[2],6))
    uniq[key] = p
points = list(uniq.values())

# Compute visible in left view: group by Y,Z (rounded to 3 decimals), select minimal X
groups = {}
for p in points:
    key = (round(p[1],3), round(p[2],3))
    if key not in groups or p[0] < groups[key][0]:
        groups[key] = p

visible = list(groups.values())
# sort by label-ish order: by Y desc then Z desc
visible.sort(key=lambda p: (-p[1], -p[2]))

out = []
for i,p in enumerate(visible, start=1):
    out.append({'index':i, 'X':round(p[0],6), 'Y':round(p[1],6), 'Z':round(p[2],6)})

with open(out_json,'w',encoding='utf-8') as f:
    json.dump(out,f,ensure_ascii=False,indent=2)

print('Wrote', out_json, 'with', len(out), 'visible points')
