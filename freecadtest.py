#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
此脚本位置已调整：
- 无界面脚本请使用 FreecadNoGUIPys/freecadtest_headless.py
- GUI 控制台脚本请使用 FreecadGUIPys/freecadtest.py

本文件作为兼容层，将导入并调用 FreecadGUIPys/freecadtest.py 的实现。
"""
import os
import sys

# 将 FreecadGUIPys 加入导入路径
REPO_ROOT = os.path.dirname(os.path.abspath(__file__))
GUI_DIR = os.path.join(REPO_ROOT, 'FreecadGUIPys')
if GUI_DIR not in sys.path:
    sys.path.insert(0, GUI_DIR)

import freecadtest as fc  # type: ignore

if __name__ == '__main__':
    # 尽量复用 GUI 脚本的主体流程以保持行为一致
    print('=' * 60)
    print('FreeCAD Python API 核心功能测试开始...（通过兼容层）')
    print('=' * 60)

    doc = fc.init_env()
    fc.test_core_operations(doc)
    fc.test_part_workbench(doc)
    fc.test_sketcher_workbench(doc)
    try:
        fc.test_techdraw_workbench(doc)
    except Exception:
        print('【跳过 TechDraw】当前为无界面模式或模块不可用')
    fc.test_mesh_workbench(doc)

    # 保存文档（带时间戳）
    doc.saveAs(fc.build_out('api_test_result', 'FCStd'))
    print('\n' + '=' * 60)
    print('测试完成！结果位置：')
    print(f"- FreeCAD文档：{fc.build_out('api_test_result', 'FCStd')}")
    print('- 导出文件：STEP/STL/PDF（按类型分类子目录，PDF 视 GUI 可用性）')
    print('=' * 60)