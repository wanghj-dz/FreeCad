param()
$ErrorActionPreference = 'Stop'

function Test-Command {
  param([Parameter(Mandatory=$true)][string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Print-NextSteps {
  Write-Host "\n下一步："
  Write-Host "- 在 VS Code 中运行任务：gh: Login (browser)（推荐）或 gh: Login with token (masked)"
  Write-Host "- 运行完成后可用 gh: Status 查看登录状态"
}

if (Test-Command -Name 'gh') {
  try {
    gh --version
  } catch {
    Write-Warning "gh 已安装，但无法执行 gh --version：$($_.Exception.Message)"
  }

  try {
    gh auth status
  } catch {
    Write-Host "尚未登录（或登录信息不可用）。"
  }
  Print-NextSteps
  exit 0
}

Write-Host "未检测到 GitHub CLI (gh)。"
$hasScoop = Test-Command -Name 'scoop'
$hasWinget = Test-Command -Name 'winget'

$default = if ($hasScoop) { 'S' } elseif ($hasWinget) { 'W' } else { 'O' }
Write-Host "可用安装方式："
if ($hasScoop) { Write-Host "  [S] 使用 Scoop 安装 (scoop install gh)" }
if ($hasWinget) { Write-Host "  [W] 使用 winget 安装 (winget install GitHub.cli)" }
Write-Host "  [O] 打开浏览器到下载页面"
Write-Host "  [Q] 退出"

$choice = Read-Host "请选择 (默认 $default)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = $default }
$choice = $choice.ToUpperInvariant()

switch ($choice) {
  'S' {
    if (-not $hasScoop) { Write-Error '未检测到 Scoop。请选择 winget 或打开下载页面。'; exit 1 }
    Write-Host '正在通过 Scoop 安装 gh...'
    scoop install gh
    if ($LASTEXITCODE -ne 0) { Write-Error "Scoop 安装失败，退出码 $LASTEXITCODE"; exit $LASTEXITCODE }
  }
  'W' {
    if (-not $hasWinget) { Write-Error '未检测到 winget。请选择 Scoop 或打开下载页面。'; exit 1 }
    Write-Host '正在通过 winget 安装 gh...（可能需要确认权限）'
    winget install --id GitHub.cli -e
    if ($LASTEXITCODE -ne 0) { Write-Error "winget 安装失败，退出码 $LASTEXITCODE"; exit $LASTEXITCODE }
  }
  'O' {
    Write-Host '正在打开浏览器：https://cli.github.com/'
    Start-Process 'https://cli.github.com/' | Out-Null
    exit 0
  }
  'Q' {
    Write-Host '已取消。'
    exit 0
  }
  default {
    Write-Error '无效选择。'
    exit 1
  }
}

# 安装完成后，复检并提示下一步
if (Test-Command -Name 'gh') {
  Write-Host 'gh 安装完成。'
  try { gh --version } catch {}
  Print-NextSteps
  exit 0
} else {
  Write-Error '安装完成后仍未检测到 gh。请重启终端或手动检查 PATH。'
  exit 1
}
