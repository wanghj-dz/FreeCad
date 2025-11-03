#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FreeCAD投影自动化脚本：3D→2D工程投影 + 曲线→曲面投影
运行方式：1.打开FreeCAD → 2.切换到Python控制台 → 3.粘贴完整脚本运行
         2.使用命令行：freecadcmd.exe script.py
"""

import FreeCAD
import Part
import os
import sys

# 检查FreeCAD版本和运行模式
print("="*50)
print(f"FreeCAD版本: {FreeCAD.Version()}")
print(f"运行模式: {'命令行' if sys.stdout.isatty() else '图形界面'}")
print("="*50)

# -------------------------- 全局配置参数（可按需修改）--------------------------
# 1. 输出路径（使用当前目录，避免路径问题）
OUTPUT_PATH = os.path.dirname(os.path.abspath(__file__))
print(f"配置的输出路径: {OUTPUT_PATH}")

# 2. 3D模型参数（立方体）
CUBE_LENGTH = 15  # 长度(mm)
CUBE_WIDTH = 10   # 宽度(mm)
CUBE_HEIGHT = 8   # 高度(mm)

# 3. 曲线投影参数
SPHERE_RADIUS = 12  # 目标球面半径(mm)
PROJECT_CURVE_RADIUS = 4  # 投影圆半径(mm)
PROJECT_DIRECTION = FreeCAD.Vector(0, 0, -1)  # 投影方向（Z轴负方向）

# 4. 2D工程图参数
DRAWING_SCALE = 1.0  # 图纸比例
DRAWING_TEMPLATE = "Template_A4_Landscape.svg"  # A4横向模板

# 2. 3D模型参数（立方体）
CUBE_LENGTH = 15  # 长度(mm)
CUBE_WIDTH = 10   # 宽度(mm)
CUBE_HEIGHT = 8   # 高度(mm)

# 3. 曲线投影参数
SPHERE_RADIUS = 12  # 目标球面半径(mm)
PROJECT_CURVE_RADIUS = 4  # 投影圆半径(mm)
PROJECT_DIRECTION = FreeCAD.Vector(0, 0, -1)  # 投影方向（Z轴负方向）

# 4. 2D工程图参数
DRAWING_SCALE = 1.0  # 图纸比例
DRAWING_TEMPLATE = "Template_A4_Landscape.svg"  # A4横向模板

# -------------------------- 工具函数（无需修改）--------------------------
def create_output_folder():
    """创建输出文件夹，避免路径不存在报错"""
    if not os.path.exists(OUTPUT_PATH):
        try:
            os.makedirs(OUTPUT_PATH)
            print(f"输出文件夹已创建：{OUTPUT_PATH}")
        except Exception as e:
            print(f"创建输出文件夹失败: {str(e)}")
    else:
        print(f"输出文件夹已确认：{OUTPUT_PATH}")

# -------------------------- 功能1：3D模型转2D工程投影（TechDraw）--------------------------
def create_3d_cube():
    """创建3D立方体模型（命令行模式的简化版本）"""
    print("\n开始创建3D立方体模型...")
    try:
        # 1. 创建新文档
        doc_3d = FreeCAD.newDocument("Cube_Doc")
        print("3D文档创建成功")

        # 2. 创建3D立方体模型
        cube = doc_3d.addObject("Part::Box", "Test_Cube")
        cube.Length = CUBE_LENGTH
        cube.Width = CUBE_WIDTH
        cube.Height = CUBE_HEIGHT
        doc_3d.recompute()
        print("3D立方体模型创建成功")

        # 3. 保存文档
        doc_path = os.path.join(OUTPUT_PATH, "Cube_Model.FCStd")
        doc_3d.saveAs(doc_path)
        print(f"3D模型文档已保存至：{doc_path}")
        
        # 4. 导出为STEP文件
        step_path = os.path.join(OUTPUT_PATH, "Cube_Model.step")
        cube.Shape.exportStep(step_path)
        print(f"3D模型已导出为STEP格式：{step_path}")

        # 清理
        FreeCAD.closeDocument("Cube_Doc")
        print("3D文档已关闭")
        
        return True

    except Exception as e:
        print(f"3D立方体创建失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def create_curve_projection():
    """创建圆形曲线到球面的投影"""
    print("\n开始创建曲线投影...")
    try:
        # 1. 创建新文档
        doc_curve = FreeCAD.newDocument("Curve_Projection_Doc")
        print("曲线投影文档创建成功")

        # 2. 创建目标曲面（球体）
        sphere = doc_curve.addObject("Part::Sphere", "Target_Sphere")
        sphere.Radius = SPHERE_RADIUS
        doc_curve.recompute()
        print("目标球面创建成功")

        # 3. 创建待投影曲线（直接创建圆形，避免使用Sketcher模块）
        circle = Part.makeCircle(PROJECT_CURVE_RADIUS, FreeCAD.Vector(0, 0, 5), FreeCAD.Vector(0, 0, 1))
        wire = Part.Wire(circle)
        curve_obj = doc_curve.addObject("Part::Feature", "Project_Curve")
        curve_obj.Shape = wire
        doc_curve.recompute()
        print("待投影圆形曲线创建成功")

        # 4. 执行曲线到曲面的投影
        print("开始执行曲线到曲面投影...")
        # 获取曲线和曲面的Shape对象
        curve_shape = wire
        surface_shape = sphere.Shape
        # 执行投影（最短距离模式，指定方向）
        projected_shape = Part.makeProjectionOnSurface(curve_shape, surface_shape, PROJECT_DIRECTION)
        # 创建投影结果对象
        proj_obj = doc_curve.addObject("Part::Feature", "Projected_Curve_Result")
        proj_obj.Shape = projected_shape
        doc_curve.recompute()
        print("曲线到曲面投影执行成功")
        
        # 5. 保存文档
        doc_path = os.path.join(OUTPUT_PATH, "Curve_Projection_Doc.FCStd")
        print(f"准备保存曲线投影文档至: {doc_path}")
        doc_curve.saveAs(doc_path)
        print(f"曲线投影文档已保存至：{doc_path}")
        
        # 清理
        FreeCAD.closeDocument("Curve_Projection_Doc")
        print("曲线投影文档已关闭")

        return True

    except Exception as e:
        print(f"曲线投影创建失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

# -------------------------- 功能2：曲线到曲面投影（Part）--------------------------
def create_curve_projection():
    """创建圆形曲线到球面的投影"""
    print("\n开始创建曲线投影...")
    try:
        # 1. 创建新文档
        doc_curve = FreeCAD.newDocument("Curve_Projection_Doc")
        print("曲线投影文档创建成功")

        # 2. 创建目标曲面（球体）
        sphere = doc_curve.addObject("Part::Sphere", "Target_Sphere")
        sphere.Radius = SPHERE_RADIUS
        doc_curve.recompute()
        print("目标球面创建成功")

        # 3. 创建待投影曲线（在XY平面绘制圆形）
        sketch = doc_curve.addObject("Sketcher::SketchObject", "Project_Curve")
        sketch.Support = (doc_curve.getObject("XY_Plane"), [""])  # 绑定XY平面
        # 绘制圆形：圆心(0,0,5)，法向量(0,0,1)（XY平面），半径PROJECT_CURVE_RADIUS
        circle = Part.Circle(FreeCAD.Vector(0, 0, 5), FreeCAD.Vector(0, 0, 1), PROJECT_CURVE_RADIUS)
        sketch.addGeometry(circle)
        doc_curve.recompute()
        print("待投影圆形曲线创建成功")

        # 4. 执行曲线到曲面的投影
        # 获取曲线和曲面的Shape对象
        curve_shape = sketch.Shape
        surface_shape = sphere.Shape
        print("开始执行曲线到曲面投影...")
        # 执行投影（最短距离模式，指定方向）
        projected_shape = Part.makeProjectionOnSurface(curve_shape, surface_shape, PROJECT_DIRECTION)
        # 创建投影结果对象
        proj_obj = doc_curve.addObject("Part::Feature", "Projected_Curve_Result")
        proj_obj.Shape = projected_shape
        doc_curve.recompute()
        print("曲线到曲面投影执行成功")
        
        # 5. 保存文档
        doc_path = os.path.join(OUTPUT_PATH, "Curve_Projection_Doc.FCStd")
        print(f"准备保存曲线投影文档至: {doc_path}")
        doc_curve.saveAs(doc_path)
        print(f"曲线投影文档已保存至：{doc_path}")

        return doc_curve

    except Exception as e:
        print(f"曲线投影创建失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return None

# 尝试导入TechDraw模块，但不依赖它
TechDraw = None
try:
    import TechDraw
    print("TechDraw模块已导入")
except ImportError:
    print("警告: TechDraw模块不可用，2D工程图功能将被跳过")

# -------------------------- 主程序（执行所有功能）--------------------------
if __name__ == "__main__":
    print("FreeCAD投影自动化脚本开始执行...")

    # 1. 创建输出文件夹
    print("\n步骤1: 确保输出文件夹存在")
    create_output_folder()

    # 2. 创建3D立方体模型（简化的命令行版本）
    print("\n步骤2: 创建3D立方体模型")
    create_3d_cube()

    # 3. 执行曲线到曲面投影
    print("\n步骤3: 执行曲线到曲面投影")
    create_curve_projection()
    
    # 4. 尝试TechDraw功能（如果可用）
    if TechDraw and hasattr(TechDraw, 'newPage'):
        print("\n步骤4: 尝试2D工程图创建（可能在命令行模式下受限）")
        try:
            # 创建新文档
            doc_2d = FreeCAD.newDocument("2D_Doc")
            cube = doc_2d.addObject("Part::Box", "Projection_Cube")
            cube.Length = CUBE_LENGTH
            cube.Width = CUBE_WIDTH
            cube.Height = CUBE_HEIGHT
            doc_2d.recompute()
            
            print("创建TechDraw图纸页...")
            page = TechDraw.newPage("A4_2D_Drawing")
            doc_2d.addObject(page)
            
            print("生成投影视图...")
            proj_group = TechDraw.makeProjectionGroup(page, [cube], "Top", DRAWING_SCALE)
            proj_group.addProjection("Front")
            proj_group.addProjection("Right")
            doc_2d.recompute()
            
            # 保存文档
            doc_2d_path = os.path.join(OUTPUT_PATH, "2D_Drawing_Doc.FCStd")
            doc_2d.saveAs(doc_2d_path)
            print(f"2D工程图文档已保存至: {doc_2d_path}")
            
            FreeCAD.closeDocument("2D_Doc")
        except Exception as e:
            print(f"TechDraw操作失败: {str(e)}")
    else:
        print("\n步骤4: 跳过2D工程图创建（TechDraw模块不可用或在命令行模式下受限）")

    print("\n" + "="*50)
    print("脚本执行完成！")
    print(f"提示：所有生成的文件都保存在: {OUTPUT_PATH}")
    print("="*50)