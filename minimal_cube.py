import FreeCAD
import Part
import os

# 基本信息输出
print("Starting minimal FreeCAD script")

# 使用当前目录
output_dir = os.path.dirname(os.path.abspath(__file__))
print(f"Output directory: {output_dir}")

# 创建文档
doc = FreeCAD.newDocument("MinimalDoc")
print("Document created")

# 创建立方体
cube = doc.addObject("Part::Box", "Cube")
cube.Length = 10
cube.Width = 10
cube.Height = 10
doc.recompute()
print("Cube created and recomputed")

# 保存文档
doc_path = os.path.join(output_dir, "minimal_cube.FCStd")
doc.saveAs(doc_path)
print(f"Document saved to: {doc_path}")

# 清理
FreeCAD.closeDocument("MinimalDoc")
print("Script completed successfully")