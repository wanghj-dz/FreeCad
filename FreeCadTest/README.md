# FreeCadTest 输出目录说明

此目录用于存放本仓库 FreeCAD 脚本的运行产物（自动生成）。所有输出文件统一按“类型子目录 + 时间戳文件名”的规范保存，便于批次管理与追溯。

## 子目录约定

- FCStd — FreeCAD 文档（.FCStd）
- STEP — 三维交换格式（.step/.stp）
- STL — 网格文件（.stl）
- PDF — 工程图导出（需要 GUI + TechDraw 可用时才会生成）
- Other — 其它类型文件（无法归类时）

提示：脚本会在首次运行时预创建以上子目录，即使本次未导出该类型文件，目录也会存在。

## 文件命名规范

- 统一时间戳：YYYYMMDD-HHMMSS
- 示例：
  - STEP: `FreeCadTest/STEP/part_export_20251103-130756.step`
  - STL: `FreeCadTest/STL/mesh_export_20251103-130756.stl`
  - FCStd: `FreeCadTest/FCStd/api_test_result_20251103-130756.FCStd`
  - PDF: `FreeCadTest/PDF/techdraw_export_20251103-130756.pdf`（GUI 可用时）

同一轮运行会复用相同的时间戳，便于将同批次的 FCStd/STEP/STL/PDF 对应起来。

## 如何生成这些文件

- VS Code 任务（推荐）
  - 无界面：Tasks -> “freecad: Run NoGUI (headless test)”
  - 启动 GUI：Tasks -> “freecad: Launch GUI (open app)”（在 GUI Python 控制台执行 `FreecadGUIPys/freecadtest.py` 可生成 PDF）
- 直接脚本
  - `scripts/run-freecad.ps1 -ScriptPath FreecadNoGUIPys/freecadtest_headless.py`

## 输出目录位置（可重定向）

- 默认：仓库根下的 `FreeCadTest/`
- 可通过环境变量或参数重定向：
  - 环境变量：`FREECAD_OUTPUT="D:\\your\\path"`
  - 运行器参数：`-OutputPath D:\\your\\path`

无论设置到哪里，脚本都会自动在其下按类型建立子目录，并使用时间戳命名。

## 常见问题

- 看不到 PDF：无界面（headless）模式会跳过 TechDraw，因此不会导出 PDF；在 GUI 中运行 `FreecadGUIPys/freecadtest.py` 可生成。
- 旧文件清理：可按时间戳批量删除过期文件；如需自动清理，可告知在脚本中加入开关（例如 `CLEAN_OLD_OUTPUT=1`）。
- 目录规范迁移：若历史有散落文件，可使用 `scripts/unify-freecad-names.ps1` 一键按扩展迁移到对应子目录（FCStd/STEP/STL/PDF）。

## 相关脚本/入口

- 无界面主脚本：`FreecadNoGUIPys/freecadtest_headless.py`
- GUI 复用脚本：`FreecadGUIPys/freecadtest.py`
- 运行器（自动寻找 FreeCAD/记录日志）：`scripts/run-freecad.ps1`、`scripts/run-freecad-gui.ps1`
- 目录统一与迁移：`scripts/unify-freecad-names.ps1`
- 运行摘要更新（本目录）：`FreeCadTest/scripts/update-summary.ps1`（将“最近一次运行摘要”写入本 README）

如需变更目录结构或文件命名，请在提 Issue 中说明诉求；本目录 README 仅用于解释当前输出规范。

<!-- RUN-SUMMARY-START -->
## 最近一次运行摘要

生成时间戳：20251103-130756

- FCStd:
  - FCStd/api_test_result_20251103-130756.FCStd
- STEP:
  - STEP/part_export_20251103-130756.step
- STL:
  - STL/mesh_export_20251103-130756.stl
- PDF:
  - <无>

<!-- RUN-SUMMARY-END -->

