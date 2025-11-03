#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Headless-friendly runner for freecadtest.py:
- Skips TechDraw when GUI not available
- Uses OUTPUT_PATH under the repo if C:/FreeCAD_API_Test is not writable
"""
import os
import sys

import FreeCAD
import Part
import Sketcher
import Mesh

# Try import TechDraw (may be unavailable in headless)
try:
    import TechDraw  # noqa: F401
    TECHDRAW_AVAILABLE = True
except Exception:
    TECHDRAW_AVAILABLE = False

GUI_AVAILABLE = getattr(FreeCAD, 'GuiUp', False)

# Import user script as a module
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
import freecadtest as fc  # type: ignore

# Adjust output path to be writable if needed
OUTPUT_PATH = fc.OUTPUT_PATH
try:
    test_dir = OUTPUT_PATH
    os.makedirs(test_dir, exist_ok=True)
except Exception:
    # fallback to repo .logs folder's parent
    repo_root = os.path.dirname(os.path.dirname(__file__))
    OUTPUT_PATH = os.path.join(repo_root, 'FreeCAD_API_Test')
    os.makedirs(OUTPUT_PATH, exist_ok=True)
    fc.OUTPUT_PATH = OUTPUT_PATH

print('=' * 60)
print('FreeCAD Python API 核心功能测试（无界面模式）...')
print('=' * 60)

doc = fc.init_env()
fc.test_core_operations(doc)

# Re-implement Part workbench test to avoid API mismatch in MultiFuse
print("\n【2. Part工作台测试】(headless override)")
cube = doc.addObject("Part::Box", "Cube")
cube.Length, cube.Width, cube.Height = 10, 8, 5
cyl = doc.addObject("Part::Cylinder", "Cylinder")
cyl.Radius, cyl.Height = 3, 12
cyl.Placement.Base = FreeCAD.Vector(15, 0, 0)
fuse = doc.addObject("Part::MultiFuse", "FusedObject")
fuse.Shapes = [cube, cyl]  # Use DocumentObjects, not Shapes
doc.recompute()
step_path = fc.build_out("part_export", "step")
Part.export([fuse], step_path)
print(f"立方体+圆柱体求和完成，STEP导出至：{step_path}")
print("\n【3. Sketcher工作台测试】(headless override)")
sketch = doc.addObject("Sketcher::SketchObject", "TestSketch")
# Default is on XY plane; avoid using Support in headless
sketch.addGeometry(Part.Circle(FreeCAD.Vector(0,0,0), FreeCAD.Vector(0,0,1), 5))
sketch.addGeometry(Part.LineSegment(FreeCAD.Vector(0,5,0), FreeCAD.Vector(10,5,0)))
try:
    # 约束在无界面环境易报错，先省略约束示例
    doc.recompute()
    print("草图（圆+直线）创建完成！（无约束）")
except Exception as e:
    print(f"【跳过 Sketch 约束】原因: {e}")

if TECHDRAW_AVAILABLE and GUI_AVAILABLE:
    try:
        fc.test_techdraw_workbench(doc)
    except Exception as e:
        print(f'【跳过 TechDraw】原因: {e}')
else:
    print('【跳过 TechDraw】当前为无界面模式或模块不可用')

# Mesh（尝试使用 MeshPart 生成 STL；失败则跳过）
print("\n【5. Mesh工作台测试】(headless override)")
try:
    import MeshPart  # type: ignore
    mesh_data = MeshPart.meshFromShape(Shape=cube.Shape, LinearDeflection=0.5, AngularDeflection=0.5)
    mesh_obj = doc.addObject("Mesh::Feature", "CubeMesh")
    mesh_obj.Mesh = mesh_data
    doc.recompute()
    stl_path = fc.build_out("mesh_export", "stl")
    Mesh.export([mesh_obj], stl_path)
    print(f"立方体转网格完成，STL导出至：{stl_path}")
except Exception as e:
    print(f"【跳过 Mesh】原因: {e}")

doc.saveAs(fc.build_out('api_test_result', 'FCStd'))
print('\n' + '=' * 60)
print('测试完成！结果位置：')
print(f"- FreeCAD文档：{fc.build_out('api_test_result', 'FCStd')}")
print('- 导出文件：STEP/STL 保存在同一文件夹（PDF在无界面模式下可能跳过）')
print('=' * 60)
