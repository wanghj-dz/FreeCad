# FreeCAD 立方体示例

这个文件夹包含两个可以在 FreeCAD 中创建立方体的脚本：

- `create_cube.py`：命令行脚本，使用 FreeCADCmd（无界面）运行；支持参数并可输出 `.FCStd` 和 `.stl`。
- `create_cube.FCMacro`：GUI 宏，直接在 FreeCAD 图形界面中执行，创建一个 10x10x10 mm 的立方体。

## 一、用命令行创建立方体（推荐）

前提：安装了 FreeCAD，并能找到 `FreeCADCmd.exe`。常见位置：

- Scoop 安装：`C:\\Users\\<你的用户名>\\scoop\\apps\\freecad\\current\\bin\\freecadcmd.exe`
- 安装包：`C:\\Program Files\\FreeCAD 1.0\\bin\\FreeCADCmd.exe` 或 `C:\\Program Files\\FreeCAD 0.21\\bin\\FreeCADCmd.exe`

在 PowerShell 中运行（注意把路径按你的安装位置调整）：

```powershell
# 推荐：如果你是 Scoop 安装 FreeCAD：
& "C:\\Users\\admin\\scoop\\apps\\freecad\\current\\bin\\freecadcmd.exe" "d:\\FreeCad\\create_cube.py"

# 或者使用安装包路径（按版本调整）：
& "C:\\Program Files\\FreeCAD 1.0\\bin\\FreeCADCmd.exe" "d:\\FreeCad\\create_cube.py"
```

注意：FreeCAD 自身会解析命令行参数，直接在命令末尾加 `--length` 之类参数可能被 FreeCAD 截获，导致你的脚本收不到。为避免干扰，我已在脚本中支持用环境变量传参，并提供了包装脚本（见下节）。

### 用包装脚本传参（避免路径与参数问题）

我们提供了 `d:\\FreeCad\\run_create_cube.ps1`，它会：

- 自动在 Scoop/Program Files 中寻找 `freecadcmd.exe`
- 用环境变量将参数安全传给脚本

示例：

```powershell
# 生成 22x18x12 mm 的立方体，并保存为 d:\\FreeCad\\cube_env.FCStd
& "d:\\FreeCad\\run_create_cube.ps1" -Length 22 -Width 18 -Height 12 -Fcstd "d:\\FreeCad\\cube_env.FCStd"
```

还可以指定位置、旋转，以及在立方体中心打贯通孔：

```powershell
# 把立方体移动到 (5, 0, 2) mm，绕 X/Y/Z 依次旋转 (0, 0, 30) 度；
# 在 Z 方向打半径 3 mm 的贯通孔；并导出 STL
& "d:\\FreeCad\\run_create_cube.ps1" -Length 20 -Width 16 -Height 10 `
  -Pos "5,0,2" -Rot "0,0,30" -HoleRadius 3 -HoleAxis Z `
  -Fcstd "d:\\FreeCad\\cube_posrot.FCStd" -Stl "d:\\FreeCad\\cube_posrot.stl"
```

可用参数：

- `--length <mm>`：长度，默认 10
- `--width <mm>`：宽度，默认 10
- `--height <mm>`：高度，默认 10
- `--fcstd <path>`：FCStd 输出路径（不指定则自动生成时间戳文件）
- `--stl <path>`：可选，若提供则同时导出 STL
- `--name <str>`：立方体对象名，默认 `MyCube`

位置/旋转/打孔（通过包装脚本或环境变量更稳）：

- `--pos x,y,z`：位移（毫米），示例 `--pos 0,0,0`
- `--rot rx,ry,rz`：依次绕 X/Y/Z 旋转角度（度），示例 `--rot 0,0,0`
- `--holeRadius <mm>`：在立方体中心打贯通孔的半径（毫米）；0 表示不打孔
- `--holeAxis <X|Y|Z>`：孔的方向轴，默认 `Z`

或者使用环境变量（当通过 `run_create_cube.ps1` 时已自动设置）：

- `FC_LENGTH`、`FC_WIDTH`、`FC_HEIGHT`
- `FC_FCSTD`：FCStd 输出路径
- `FC_STL`：STL 路径
- `FC_NAME`：对象名
- `FC_POS`：`x,y,z`
- `FC_ROT`：`rx,ry,rz`（度）
- `FC_HOLE_RADIUS`：孔半径（毫米），>0 生效
- `FC_HOLE_AXIS`：`X|Y|Z`

运行成功后，终端会打印生成结果路径。可用 FreeCAD 打开 `.FCStd` 文件查看模型。

## 二、在 FreeCAD GUI 中运行宏

1. 启动 FreeCAD（图形界面）。
2. 菜单 `Macro` -> `Macros...` -> `...`（选择文件） -> 打开 `d:\\FreeCad\\create_cube.FCMacro`。
3. 选择该宏并点击 `Execute`。
4. 会在当前文档（或新建文档）中生成一个名为 `MyCube` 的立方体，大小为 10x10x10 mm，可在属性面板调整。

若需要在 GUI 中保存，可用 `File` -> `Save As...` 手动选择保存位置。

### 看不到模型？用一键显示宏

如果打开 `.FCStd` 但视图里看不到模型，通常是没有自动对焦或者最终实体被隐藏。可以使用我们提供的 GUI 宏 `d:\\FreeCad\\ShowBodyFit.FCMacro`：

1. 打开你的 `.FCStd` 文件。
2. 菜单 `Macro` -> `Macros...` -> 选择 `ShowBodyFit.FCMacro` -> `Execute`。
3. 宏会：

- 自动定位“最终实体对象”（如 `Body`），
- 隐藏中间体（如 `MyCube`、`Hole`），
- 选择目标对象，切换等轴测，并执行“Fit all”。

仍然不可见时：试试切换工作台为 Part / Part Design，再点一次“Fit all”，或者在树里手动切换目标对象可见性（选中对象按空格）。

### 倒角/圆角、显示模式与颜色宏

我们还提供了以下宏（放在 `d:\\FreeCad`）：

- `FilletEdges.FCMacro`：先在 GUI 中选中一个或多条边，运行后输入半径，生成圆角（Part::Fillet）。
- `ChamferEdges.FCMacro`：选中边，运行后输入距离，生成倒角（Part::Chamfer）。
- `ToggleBaseVisibility.FCMacro`：一键隐藏/显示中间体（如 `MyCube`、`Hole`），保留最终体可见。
- `ToggleDisplayMode.FCMacro`：在着色/平面线条/Wireframe 模式间切换（对选中对象或当前可见对象）。
- `SetColor.FCMacro`：弹出颜色选择器，设置选中或可见对象颜色。
- `SaveExportFit.FCMacro`：自动定位最终体、对焦视图，并保存为 FCStd；可选同时导出 STL。

### 把宏做成工具栏按钮（当次会话）

如果想把这些宏变成工具栏按钮，可在 FreeCAD GUI Python 控制台运行：

```python
path = r'd:\\FreeCad\\register_toolbar.py'
ns = {'__file__': path, '__name__': '__main__'}
exec(compile(open(path,'rb').read(), path, 'exec'), ns)
```

若仍报找不到路径，可在运行前设置环境变量，脚本会以此作为宏目录：

```python
import os
os.environ['FC_MACRO_ROOT'] = r'd:\\FreeCad'
```

或者，直接运行我们提供的 `LoadMyToolbar.FCMacro`：

1. 菜单 `Macro` -> `Macros...` -> 选择 `d:\\FreeCad\\LoadMyToolbar.FCMacro` -> `Execute`
2. 宏会自动执行 `register_toolbar.py` 并创建 “MyFreeCADMacros” 工具栏。

运行后会出现一个名为 “MyFreeCADMacros” 的工具栏，包含上述按钮（仅对本次会话生效）。想长期使用，可通过 Tools -> Customize 把这些宏添加到自定义工具栏。

### 将宏安装到用户宏目录（推荐）

为让这些宏在 FreeCAD 的“宏管理器”中默认可见，建议把宏安装到用户宏目录：

- 用户宏目录路径（Windows）：`C:\Users\admin\AppData\Roaming\FreeCAD\Macro\`
- 建议拷贝的文件：
  - `ShowBodyFit.FCMacro`
  - `FilletEdges.FCMacro`
  - `ChamferEdges.FCMacro`
  - `ToggleBaseVisibility.FCMacro`
  - `ToggleDisplayMode.FCMacro`
  - `SetColor.FCMacro`
  - `SaveExportFit.FCMacro`
  - `create_cube.FCMacro`
  - `register_toolbar.py`
  - `LoadMyToolbar.FCMacro`

完成后：

1) 启动 FreeCAD，菜单 `Macro -> Macros...` 中会直接显示这些宏。
2) 运行 `LoadMyToolbar.FCMacro`，会执行 `register_toolbar.py` 并创建工具栏 “MyFreeCADMacros”。
3) 控制台会打印 FreeCAD 版本，如 `FreeCAD Version: ...`，用于确认版本检测正常。

提示：当宏位于用户宏目录时，无需再设置 `FC_MACRO_ROOT` 环境变量；`LoadMyToolbar.FCMacro` 会优先从该目录查找。

## 三、常见问题


- 提示找不到 FreeCAD 模块：请确保是用 `FreeCADCmd.exe` 运行脚本，而不是系统自带的 `python.exe`。
- 路径有空格：PowerShell 中使用双引号包裹路径；上面示例已示范。
- STL 导出失败：某些版本可能没有 `Mesh` 或 `MeshPart` 模块。脚本会尝试两种方式导出，但如果两者都不可用，将报错。可以只输出 `.FCStd`，再在 GUI 中通过 `File -> Export...` 导出 STL。

## 四、下一步

- 将脚本扩展为参数化模型（加倒角、圆角、孔、阵列等）。
- 批量生成多尺寸立方体并各自导出 STL。

## 五、GitHub CLI（VS Code 任务）

本仓库已添加 VS Code 任务，覆盖 gh 的安装检查、登录与常用操作，避免在命令历史中泄露令牌：

- 任务位置：`.vscode/tasks.json`
- 任务列表：
  - gh: Bootstrap (check/install) — 一键检查是否已安装 gh；若未安装支持用 Scoop 或 winget 引导安装。
  - gh: Login (browser) — 推荐。浏览器登录方式，不需要手动管理令牌。
  - gh: Login with token (masked) — 令牌输入会遮蔽，令牌通过内存管道传给 `gh auth login --with-token`，不落盘且不进入历史。
  - gh: Status — 查看当前登录状态。
  - gh: Logout — 登出当前主机（github.com）。
  - gh: PR Create (web) — 基于当前仓库与分支，在浏览器中创建 PR（自动填充）。
  - gh: PR Status — 查看当前仓库/分支的 PR 状态。
  - gh: PR View (web) — 打开当前分支关联的 PR 页面。
  - gh: Issue Create (web) — 在浏览器中创建 Issue。
  - gh: Repo View (web) — 打开当前仓库页面。
  - gh: Setup Git — 由 gh 自动配置 Git 凭据（适用于首次配置或切换账户）。
  - gh: Create Release (web) — 在浏览器中创建 Release（交互式表单）。
  - gh: Release Create (prompt, generate-notes) — 任务内交互输入 Tag（如 v0.1.1），自动生成 Release Notes 并创建发布。
  - gh: Releases View (web) — 在浏览器中查看 Release 页面。
  - gh: Diagnostics (log) — 采集 gh/git/环境信息并输出日志路径，便于排障。
  - gh: Install global toolkit (user tasks) — 一键将本仓库的脚本安装到用户目录（%USERPROFILE%\.vscode-gh-toolkit\scripts），并生成用户级 tasks 片段，实现在“任何路径/文件夹”中直接使用这些任务。
  - module: Install RepoToolkit (user scope) — 将轻量 PowerShell 模块 RepoToolkit 安装到用户模块目录（Documents\PowerShell\Modules），从而可直接调用函数而非脚本路径。
  - module: Repo Create & Push (public, HTTPS) — 示例：通过模块函数执行创建并推送。
  - repo: Create & Push (private/public) — 在 GitHub 上创建与文件夹同名的仓库并推送当前工作区内容。
  - repo: Create & Push (choose visibility) — 运行前交互选择 `private`/`public`/`internal` 后创建并推送（注：`internal` 仅适用于组织仓库）。
  - repo: Create & Push (public, HTTPS) / (private, HTTPS) — 使用 HTTPS 远程（适合未配置 SSH key 的环境）。

运行方式：

1) VS Code 菜单 Terminal -> Run Task…，选择上述任一任务
2) 或 Ctrl+Shift+P 输入 “Tasks: Run Task”，再选择需要的任务

注意事项：

- 如果你之前把令牌明文写在命令行里，请立即到 GitHub Settings -> Developer settings -> Tokens 页面撤销该令牌，并以最小权限重建。
- `gh: Login (browser)` 是最安全且最省心的方式；若必须使用令牌，建议仅授予必要 scope（例如：repo / workflow / gist 视你的需求）。
- 任务使用 PowerShell（pwsh）执行，已兼容你的默认 Shell。

若未安装 gh，可先运行 `gh: Bootstrap (check/install)`：

- 检测到 Scoop 时，优先提供 `scoop install gh`；
- 无 Scoop 但有 winget 时，提供 `winget install GitHub.cli -e`；
- 都没有时，会打开 gh 下载页面（<https://cli.github.com/>）。

常见问题：

- 任务如提示找不到 gh，安装完成后可能需要重启 VS Code 或终端使 PATH 生效。
- PR/Issue 相关任务需要当前工作区就是一个 git 仓库并已设置远程 `origin` 指向 GitHub。
- Release 相关任务需要当前仓库对 GitHub 有写权限；首次使用建议先运行 “gh: Setup Git”。
- 诊断日志会保存在工作区目录 `.logs/` 下，文件名形如 `gh-diagnostics-YYYYMMDD-HHMMSS.txt`。

提示：

- 若未配置 SSH key，推荐使用 HTTPS 任务或在交互式任务中勾选 HTTPS 变体（通过 -UseHttps）。
- 也可以后续在仓库中切换远程：`git remote set-url origin https://github.com/<owner>/<repo>.git`。

### 在 HTTPS 与 SSH 之间切换

已内置两条 VS Code 任务，便于一键切换当前仓库的远程 `origin`：

- repo: Switch remote to HTTPS — 将 `origin` 设置为 `https://github.com/<owner>/<repo>.git`
- repo: Switch remote to SSH — 将 `origin` 设置为 `git@github.com:<owner>/<repo>.git`
- repo: Prefer HTTPS (no SSH key) — 取消可能存在的全局 URL 重写规则（把 https 改写成 ssh），将 gh 的 git_protocol 设为 https，并切换远程到 HTTPS
- repo: Prefer SSH — 将 gh 的 git_protocol 设为 ssh，并切换远程为 SSH（可选添加 URL 重写规则，见脚本注释）

使用方法：Terminal -> Run Task… -> 选择上面任一任务。脚本会优先通过 `gh repo view` 获取标准的 `<owner>/<repo>`，若不可用则从现有 `origin` 解析。

若选择 SSH，请确保本机已配置 SSH 公钥并已添加到 GitHub：

- 生成密钥（如尚未生成）：

```pwsh
ssh-keygen -t ed25519 -C "you@example.com"
```

- 复制公钥内容到剪贴板并粘贴到 GitHub Settings -> SSH and GPG keys：

```pwsh
Get-Content $HOME/.ssh/id_ed25519.pub | Set-Clipboard
```

- 验证连通：

```pwsh
ssh -T git@github.com
```

切换完成后，可用 `git remote -v` 查看当前远程是否已更新。

提示：若你看到 `git push` 到 https 仍然走 SSH 并报 “Permission denied (publickey)” 的情况，多半是全局配置里有一条 URL 重写规则：

```ini
[url "git@github.com:"]
  insteadof = https://github.com/
```

执行 “repo: Prefer HTTPS (no SSH key)” 任务会自动移除此规则，并将远程切回 HTTPS；随后再推送即可。

### 全局安装（任何路径/文件夹可用）

如果你希望在任意项目中都能直接使用这些任务，而不必复制 `.vscode` 和 `scripts`，可执行任务：

- gh: Install global toolkit (user tasks)

它会：

- 将本仓库的脚本复制到 `%USERPROFILE%\.vscode-gh-toolkit\scripts`
- 生成用户级任务文件片段：`%USERPROFILE%\.vscode-gh-toolkit\tasks.user.json`
- 如用户级任务尚未存在，会直接安装到 `%APPDATA%\Code\User\tasks.json`
- 若已存在，则保留现有文件，并提示你在 VS Code 中通过 “Tasks: Open User Tasks” 打开并合并（拷贝片段内容到你的 user tasks）

从此以后，即使新建一个空文件夹打开 VS Code，也可以通过 Terminal -> Run Task… 直接使用以 `global:` 前缀开头的任务（例如 `global: repo: Create & Push (private, HTTPS)`）。
另外还提供：`global: gh: Release Create (prompt, generate-notes)`，在任意仓库目录下交互创建发布。

## 六、PowerShell 模块：RepoToolkit（可选，更优雅）

为获得更优雅的命令式体验（无需硬编码脚本路径），我们提供轻量模块 `RepoToolkit`（当前版本：0.1.0）：

- 安装（VS Code 任务）：`module: Install RepoToolkit (user scope)`
- 安装（命令行）：

```pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File "${workspaceFolder}/scripts/install-module-RepoToolkit.ps1"
```

安装后可用的函数（示例）：

- `Invoke-RepoCreateAndPush -Visibility public -UseHttps -NoPrompt`
- `Set-RepoRemoteHttps` / `Set-RepoRemoteSsh`
- `Set-GitPreferenceHttps` / `Set-GitPreferenceSsh`
- `Install-RepoToolkitGlobalTasks`（安装用户级全局任务）
- `Invoke-GhBootstrap` / `Invoke-GhDiagnostics` / `Invoke-GhLoginToken`

你也可以将这些函数放入 VS Code 用户级任务中直接调用（无需引用脚本路径）。

### 自更新（覆盖安装）

- 工作区任务：`module: Self-update RepoToolkit`（重新复制并导入 0.1.x 版本模块）
- 全局任务片段也包含：`global: module: Self-update RepoToolkit`（前提：已运行一次 “gh: Install global toolkit (user tasks)”）

### 全局模块任务（依赖 RepoToolkit 已安装）

运行 `gh: Install global toolkit (user tasks)` 后，你将看到以 `global: module:` 开头的任务，例如：

- global: module: Repo Create & Push (public, HTTPS)
- global: module: Set Remote HTTPS / SSH
- global: module: Prefer HTTPS / SSH
- global: module: Self-update RepoToolkit

### 一键创建远程仓库并 Push（与文件夹同名）

1) 先确保已登录 gh（运行任务：`gh: Login (browser)`）并完成 Git 凭据配置（`gh: Setup Git`）。
2) 运行任务：

   - `repo: Create & Push (private)` — 创建私有仓库并推送
   - `repo: Create & Push (public)` — 创建公开仓库并推送

脚本会：

- 以工作区文件夹名作为 GitHub 仓库名（例如 `D:\FreeCad` -> `FreeCad`）
- 如未初始化 git，则自动 `git init`、首个提交并将默认分支统一为 `main`
- 使用 `gh repo create <name> --<visibility> --source . --remote origin --push` 创建远程并推送
- 若远程已存在，则直接 `git push -u origin HEAD`

可能的提示：

- 首次提交若失败，多半是 git 用户名/邮箱未配置；可运行 `gh: Setup Git` 或手动：

  ```pwsh
  git config user.name "Your Name"
  git config user.email you@example.com
  ```



 
## 七、重装后的备份/恢复与一键引导

为了在重装 VS Code 或换机后快速恢复你的用户配置（设置、快捷键、任务、代码片段与扩展列表），本仓库提供了三条开箱即用的任务与对应脚本：

- VS Code: Backup user (zip) — 备份用户配置为一个 zip
- VS Code: Restore user (latest, merge tasks) — 从最新备份恢复，并“合并”任务（避免覆盖你当前已有的用户任务）
- VS Code: Bootstrap after reinstall — 一键引导：安装全局工具任务、安装 RepoToolkit 模块、合并用户任务；可选同时自动安装扩展

你可以在当前工作区通过 Terminal -> Run Task… 直接运行上述三条任务；或者先运行“gh: Install global toolkit (user tasks)”，之后在任何目录都能看到以 global: 开头的同名任务：

- global: VS Code: Backup user (zip)
- global: VS Code: Restore user (latest, merge tasks)
- global: VS Code: Bootstrap after reinstall

备份 zip 默认保存到：`%USERPROFILE%\.vscode-gh-toolkit\backups\vscode-user-YYYYMMDD-HHMMSS.zip`

备份内容包含：

- `%APPDATA%\Code\User\settings.json`
- `%APPDATA%\Code\User\keybindings.json`
- `%APPDATA%\Code\User\tasks.json`
- `%APPDATA%\Code\User\snippets\` 下的全部文件
- 当前已安装扩展列表（extensions.txt）
- 如果存在，还会包含全局任务片段：`%USERPROFILE%\.vscode-gh-toolkit\tasks.user.json`

恢复说明：

- Restore 脚本默认取“最新”的备份 zip；也可通过 `-ZipPath` 指定某个备份文件。
- 带 `-MergeTasks` 时，会将备份中的用户任务与当前用户任务按 label 去重合并；不带此参数则直接覆盖用户任务。
- 带 `-InstallExtensions` 时，会按备份中的 extensions.txt 安装扩展（可选）。

一键引导（Bootstrap）说明：

- 重装 VS Code 后，先在任意文件夹打开 VS Code，运行任务“VS Code: Bootstrap after reinstall”。
- 它会：
  - 安装/更新全局工具任务（复制脚本到 `%USERPROFILE%\\.vscode-gh-toolkit\\scripts` 并生成用户级任务）
  - 安装/更新 PowerShell 模块 RepoToolkit（用户作用域）
  - 合并用户任务（避免覆盖现有）
  - 如果附带 `-InstallExtensions`，还会从你的最新备份中自动安装扩展
- 完成后重载 VS Code，即可在任何目录直接使用以 `global:` 开头的任务。

提示：如果你之前尚未创建任何备份，建议先在当前环境运行一次“VS Code: Backup user (zip)”。



