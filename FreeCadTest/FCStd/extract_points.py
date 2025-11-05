#!/usr/bin/env python3
"""
extract_points.py
从 FreeCAD 解压后的 Document.xml 中提取指定 Sketch 的 GeomPoint 坐标。
用法：
  python extract_points.py --xml Document.xml --sketch Sketch001
"""
import argparse
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description='Extract GeomPoint coordinates from Document.xml')
parser.add_argument('--xml', required=True, help='Path to Document.xml')
parser.add_argument('--sketch', required=True, help='Sketch object name (e.g., Sketch001)')
args = parser.parse_args()

tree = ET.parse(args.xml)
root = tree.getroot()

# 找到对应的 ObjectData 下 name==SketchXXX 节点
found = False
for obj in root.findall('.//ObjectData/Object'):
    name = obj.get('name')
    if name == args.sketch:
        found = True
        geom_list = obj.find('.//Property[@name="ExternalGeo"]/GeometryList')
        # Some files put GeomPoint under Property name="Geometry" or "ExternalGeo"; 检查多个位置
        if geom_list is None:
            geom_list = obj.find('.//Property[@name="Geometry"]/GeometryList')
        points = []
        if geom_list is not None:
            for geom in geom_list.findall('Geometry'):
                # 两种表示：GeomPoint 的标签名可能为 Geometry 元素下包含 GeomPoint 子元素
                # 或 Geometry 本身有 type="Part::GeomPoint" 并包含 GeomPoint 属性
                gtype = geom.get('type')
                if gtype and 'GeomPoint' in gtype:
                    gp = geom.find('GeomPoint')
                    if gp is None:
                        # 有时坐标直接作为属性在 Geometry 的子节点
                        gp = geom
                    x = gp.get('X') or gp.get('x')
                    y = gp.get('Y') or gp.get('y')
                    z = gp.get('Z') or gp.get('z')
                    if x and y and z:
                        points.append((float(x), float(y), float(z)))
                else:
                    # 查找直接的 GeomPoint 子元素
                    gp = geom.find('GeomPoint')
                    if gp is not None:
                        x = gp.get('X')
                        y = gp.get('Y')
                        z = gp.get('Z')
                        points.append((float(x), float(y), float(z)))
        # 备用：查找任意 GeomPoint 在该 Object 子树中
        if not points:
            for gp in obj.findall('.//GeomPoint'):
                x = gp.get('X')
                y = gp.get('Y')
                z = gp.get('Z')
                try:
                    points.append((float(x), float(y), float(z)))
                except Exception:
                    pass
        print(f"Found {len(points)} GeomPoint(s) in {args.sketch}:")
        for i,p in enumerate(points,1):
            print(f"  Point {i}: X={p[0]:.6f} Y={p[1]:.6f} Z={p[2]:.6f}")
        break

if not found:
    print(f"Sketch '{args.sketch}' not found in {args.xml}")
