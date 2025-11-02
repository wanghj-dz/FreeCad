#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简化的FreeCAD立方体创建脚本
专为命令行模式设计，确保兼容性
"""

# 导入必要的模块
import sys
import os

# 先打印一些信息，确保脚本开始执行
print("="*50)
print("简化的FreeCAD脚本开始执行")
print(f"Python版本: {sys.version}")
print(f"当前工作目录: {os.getcwd()}")
print("="*50)

# 尝试导入FreeCAD模块
try:
    import FreeCAD
    import Part
    print(f"成功导入FreeCAD模块，版本: {FreeCAD.Version()}")
except ImportError as e:
    print(f"导入FreeCAD模块失败: {str(e)}")
    sys.exit(1)

# 定义输出路径（使用脚本所在目录）
output_dir = os.path.dirname(os.path.abspath(__file__))
print(f"输出目录: {output_dir}")

# 创建立方体函数
def create_simple_cube():
    """创建一个简单的立方体并保存"""
    try:
        # 创建新文档
        doc = FreeCAD.newDocument("CubeDoc")
        print("创建FreeCAD文档成功")
        
        # 创建立方体
        cube = doc.addObject("Part::Box", "MyCube")
        cube.Length = 10
        cube.Width = 10
        cube.Height = 10
        print("创建Part::Box对象成功")
        
        # 重新计算
        doc.recompute()
        print("文档重新计算完成")
        
        # 保存文档
        fcstd_path = os.path.join(output_dir, "simple_cube.FCStd")
        doc.saveAs(fcstd_path)
        print(f"FreeCAD文档已保存至: {fcstd_path}")
        
        # 导出STEP文件
        step_path = os.path.join(output_dir, "simple_cube.step")
        cube.Shape.exportStep(step_path)
        print(f"STEP文件已导出至: {step_path}")
        
        # 清理
        FreeCAD.closeDocument("CubeDoc")
        print("文档已关闭")
        
        return True
        
    except Exception as e:
        print(f"创建立方体过程中出错: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

# 主函数
def main():
    print("开始执行主函数")
    success = create_simple_cube()
    
    if success:
        print("\n操作成功完成！")
    else:
        print("\n操作执行失败！")
    
    print("="*50)
    print("脚本执行结束")
    print("="*50)

# 执行主函数
if __name__ == "__main__":
    main()