#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简化的FreeCAD测试脚本
用于测试命令行模式下的基本功能
"""

import FreeCAD
import Part
import os

print("="*50)
print("FreeCAD简化测试脚本")
print(f"FreeCAD版本: {FreeCAD.Version()}")
print("="*50)

# 使用当前目录作为输出路径
output_dir = os.path.dirname(os.path.abspath(__file__))
print(f"输出目录: {output_dir}")

# 测试1: 创建简单立方体
print("\n测试1: 创建简单立方体...")
try:
    doc = FreeCAD.newDocument("TestDoc")
    print("文档创建成功")
    
    # 创建立方体
    cube = doc.addObject("Part::Box", "TestCube")
    cube.Length = 10
    cube.Width = 10
    cube.Height = 10
    doc.recompute()
    print("立方体创建成功")
    
    # 保存文档
    doc_path = os.path.join(output_dir, "test_cube.FCStd")
    doc.saveAs(doc_path)
    print(f"文档已保存至: {doc_path}")
    
    # 清理
    FreeCAD.closeDocument("TestDoc")
    print("文档已关闭")

except Exception as e:
    print(f"测试1失败: {str(e)}")
    import traceback
    traceback.print_exc()

# 测试2: 简单形状操作
print("\n测试2: 简单形状操作...")
try:
    # 创建球体
    sphere = Part.makeSphere(5)
    print("球体创建成功")
    
    # 创建圆柱体
    cylinder = Part.makeCylinder(3, 10)
    print("圆柱体创建成功")
    
    # 布尔运算
    result = sphere.fuse(cylinder)
    print("布尔运算成功")
    
    # 保存为STEP文件
    step_path = os.path.join(output_dir, "test_shape.step")
    result.exportStep(step_path)
    print(f"STEP文件已保存至: {step_path}")

except Exception as e:
    print(f"测试2失败: {str(e)}")
    import traceback
    traceback.print_exc()

print("\n" + "="*50)
print("测试脚本执行完成！")
print("="*50)