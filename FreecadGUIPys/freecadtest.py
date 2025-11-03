#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FreeCAD API测试脚本（GUI 控制台友好）：覆盖核心工作台常用功能
在 GUI 中可直接粘贴运行；也可被 headless runner 导入复用
"""

import FreeCAD
import Part
import os
from datetime import datetime

# 可选模块（在无界面/精简环境可能不可用）
try:
    import TechDraw  # type: ignore
    TECHDRAW_AVAILABLE = True
except Exception:
    TECHDRAW_AVAILABLE = False

try:
    import Sketcher  # type: ignore
    SKETCHER_AVAILABLE = True
except Exception:
    SKETCHER_AVAILABLE = False

try:
    import Mesh  # type: ignore
    MESH_AVAILABLE = True
except Exception:
    MESH_AVAILABLE = False

try:
    import MeshPart  # type: ignore
    MESHPART_AVAILABLE = True
except Exception:
    MESHPART_AVAILABLE = False

GUI_AVAILABLE = getattr(FreeCAD, 'GuiUp', False)

# -------------------------- 配置参数（可修改输出路径）--------------------------
# 基础输出目录：优先使用环境变量 FREECAD_OUTPUT；否则使用仓库内 FreeCadTest
_env_out = os.environ.get("FREECAD_OUTPUT")
if _env_out:
    OUTPUT_PATH = _env_out
else:
    _repo_root = os.path.dirname(os.path.abspath(os.path.join(__file__, os.pardir)))
    OUTPUT_PATH = os.path.join(_repo_root, "FreeCadTest")

# -------------------------- 工具函数 --------------------------
# 统一时间戳与路径构造（一次运行保持一致）
TIMESTAMP = datetime.now().strftime('%Y%m%d-%H%M%S')

def _ext_folder(ext: str) -> str:
    e = ext.lower()
    if e == 'fcstd':
        return 'FCStd'
    if e == 'step':
        return 'STEP'
    if e == 'stl':
        return 'STL'
    if e == 'pdf':
        return 'PDF'
    return 'Other'

def build_out(name: str, ext: str) -> str:
    """构造带时间戳的输出路径，并按文件类型分类到子文件夹。
    例如：<OUTPUT_PATH>/STEP/part_export_YYYYMMDD-HHMMSS.step
    """
    preferred = _ext_folder(ext)
    # 尝试复用已存在的同名（不区分大小写）文件夹，避免重复创建不同大小写的目录
    folder = None
    try:
        for entry in os.listdir(OUTPUT_PATH):
            p = os.path.join(OUTPUT_PATH, entry)
            if os.path.isdir(p) and entry.lower() == preferred.lower():
                folder = p
                break
    except Exception:
        folder = None
    if folder is None:
        folder = os.path.join(OUTPUT_PATH, preferred)
    os.makedirs(folder, exist_ok=True)
    return os.path.join(folder, f"{name}_{TIMESTAMP}.{ext}")

def _ensure_output_path():
    """确保基础输出目录可用；若不可用则回退到仓库同级 FreeCadTest。"""
    global OUTPUT_PATH
    try:
        os.makedirs(OUTPUT_PATH, exist_ok=True)
        testfile = os.path.join(OUTPUT_PATH, ".write_test")
        with open(testfile, "w", encoding="utf-8") as f:
            f.write("ok")
        os.remove(testfile)
    except Exception:
        repo_root = os.path.dirname(os.path.abspath(os.path.join(__file__, os.pardir)))
        # 放到仓库同级目录（非隐藏，便于用户查找）
        OUTPUT_PATH = os.path.join(os.path.dirname(repo_root), "FreeCadTest")
        os.makedirs(OUTPUT_PATH, exist_ok=True)
    # 预创建标准类型子目录，便于用户直观看见（即使本次未导出该类型）
    try:
        for sub in ("FCStd", "STEP", "STL", "PDF", "Other"):
            os.makedirs(os.path.join(OUTPUT_PATH, sub), exist_ok=True)
    except Exception:
        # 创建子目录失败不影响主流程
        pass


def init_env():
    """初始化环境：创建输出文件夹+清空旧文档"""
    _ensure_output_path()
    # 关闭所有打开的文档
    for doc in FreeCAD.listDocuments().values():
        FreeCAD.closeDocument(doc.Name)
    print("环境初始化完成！")
    return FreeCAD.newDocument("API_Test_Doc")

# -------------------------- 1. 核心基础操作 --------------------------
def test_core_operations(doc):
    print("\n【1. 核心基础操作】")
    # 查看文档名称
    print(f"当前文档：{doc.Name}")
    # 创建空对象并查看属性
    test_obj = doc.addObject("Part::Box", "TestBox")
    print(f"对象属性列表（前5个）：{test_obj.PropertiesList[:5]}")
    doc.recompute()
    print("基础操作测试完成！")
# -------------------------- 2. Part工作台（3D建模+几何操作）--------------------------
def test_part_workbench(doc):
    print("\n【2. Part工作台测试】")
    # 2.1 创建立方体
    cube = doc.addObject("Part::Box", "Cube")
    cube.Length, cube.Width, cube.Height = 10, 8, 5
    # 2.2 创建圆柱体
    cyl = doc.addObject("Part::Cylinder", "Cylinder")
    cyl.Radius, cyl.Height = 3, 12
    cyl.Placement.Base = FreeCAD.Vector(15, 0, 0)  # 移动位置
    # 2.3 布尔求和（注意：MultiFuse.Shapes 需要 DocumentObjects）
    fuse = doc.addObject("Part::MultiFuse", "FusedObject")
    fuse.Shapes = [cube, cyl]
    doc.recompute()
    # 2.4 导出STEP（导出 DocumentObjects 更稳妥）
    step_path = build_out("part_export", "step")
    try:
        Part.export([fuse], step_path)
    except Exception:
        # 回退：导出融合体的形状
        Part.export([fuse.Shape], step_path)
    print(f"立方体+圆柱体求和完成，STEP导出至：{step_path}")

# -------------------------- 3. Sketcher工作台（草图绘制）--------------------------
def test_sketcher_workbench(doc):
    print("\n【3. Sketcher工作台测试】")
    if not SKETCHER_AVAILABLE:
        print("【跳过 Sketcher】模块不可用")
        return
    # 3.1 创建草图（绑定XY平面）
    sketch = doc.addObject("Sketcher::SketchObject", "TestSketch")
    # 在无界面环境下，避免显式设置 Support（某些版本属性不可用）
    if GUI_AVAILABLE:
        try:
            sketch.Support = (doc.getObject("XY_Plane"), [""])
        except Exception:
            pass
    # 3.2 画圆（圆心(0,0,0)，半径5）
    sketch.addGeometry(Part.Circle(FreeCAD.Vector(0,0,0), FreeCAD.Vector(0,0,1), 5))
    # 3.3 画直线（从(0,5,0)到(10,5,0)）
    sketch.addGeometry(Part.LineSegment(FreeCAD.Vector(0,5,0), FreeCAD.Vector(10,5,0)))
    # 3.4 约束：仅在 GUI 环境尝试添加，headless 下易出错
    if GUI_AVAILABLE:
        try:
            sketch.addConstraint(Sketcher.Constraint("Coincident", 0, 1, 1, 1))
            print("草图（圆+直线+约束）创建完成！")
        except Exception as e:
            print(f"【跳过约束】原因: {e}")
            print("草图（圆+直线）创建完成！（无约束）")
    else:
        print("草图（圆+直线）创建完成！（无约束）")
    doc.recompute()

# -------------------------- 4. TechDraw工作台（2D工程图）--------------------------
def test_techdraw_workbench(doc):
    print("\n【4. TechDraw工作台测试】")
    if not (TECHDRAW_AVAILABLE and GUI_AVAILABLE):
        print("【跳过 TechDraw】当前为无界面模式或模块不可用")
        return
    # 4.1 创建A4图纸页
    page = TechDraw.newPage("A4_Drawing", "Template_A4.svg")
    doc.addObject(page)
    # 4.2 生成立方体的投影组（顶+前+右视图）
    cube = doc.getObject("Cube")
    proj_group = TechDraw.makeProjectionGroup(page, [cube], "Top", 1.0)
    proj_group.addProjection("Front")
    proj_group.addProjection("Right")
    proj_group.ShowHiddenLines = True  # 显示隐藏线
    # 4.3 导出PDF
    pdf_path = build_out("techdraw_export", "pdf")
    TechDraw.exportPageAsPDF(page, pdf_path)
    doc.recompute()
    print(f"2D工程图导出至：{pdf_path}")

# -------------------------- 5. Mesh工作台（网格操作）--------------------------
def test_mesh_workbench(doc):
    print("\n【5. Mesh工作台测试】")
    # 5.1 立方体转网格
    cube = doc.getObject("Cube")
    stl_path = build_out("mesh_export", "stl")
    ok = False
    if MESHPART_AVAILABLE:
        try:
            mesh_data = MeshPart.meshFromShape(Shape=cube.Shape, LinearDeflection=0.5, AngularDeflection=0.5)
            mesh_obj = doc.addObject("Mesh::Feature", "CubeMesh")
            mesh_obj.Mesh = mesh_data
            doc.recompute()
            if MESH_AVAILABLE:
                Mesh.export([mesh_obj], stl_path)
            ok = True
        except Exception as e:
            print(f"【MeshPart 失败】原因: {e}")
    if not ok and MESH_AVAILABLE:
        try:
            mesh_obj = doc.addObject("Mesh::Feature", "CubeMesh")
            mesh_obj.Mesh = Mesh.Mesh(cube.Shape)
            doc.recompute()
            Mesh.export([mesh_obj], stl_path)
            ok = True
        except Exception as e:
            print(f"【Mesh 失败】原因: {e}")
    if ok:
        print(f"立方体转网格完成，STL导出至：{stl_path}")
    else:
        print("【跳过 Mesh】未检测到 Mesh/MeshPart 或转换失败")

# -------------------------- 主程序 --------------------------
if __name__ == "__main__":
    print("="*60)
    print("FreeCAD Python API 核心功能测试开始...")
    print("="*60)
    
    # 初始化环境
    doc = init_env()
    
    # 执行所有测试
    test_core_operations(doc)
    test_part_workbench(doc)
    test_sketcher_workbench(doc)
    # TechDraw 仅在 GUI + 模块可用时执行
    if TECHDRAW_AVAILABLE and GUI_AVAILABLE:
        test_techdraw_workbench(doc)
    else:
        print("【跳过 TechDraw】当前为无界面模式或模块不可用")
    test_mesh_workbench(doc)
    
    # 保存文档（带时间戳）
    doc.saveAs(build_out("api_test_result", "FCStd"))
    
    print("\n" + "="*60)
    print("测试完成！结果位置：")
    print(f"- FreeCAD文档：{build_out('api_test_result', 'FCStd')}")
    if TECHDRAW_AVAILABLE and GUI_AVAILABLE:
        print(f"- 导出文件：STEP/PDF/STL 保存在同一文件夹")
    else:
        print(f"- 导出文件：STEP/STL 保存在同一文件夹（PDF 在无界面模式下跳过）")
    print("="*60)
