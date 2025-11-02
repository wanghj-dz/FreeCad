param(
  [ValidateSet('private','public','internal')]
  [string]$Visibility = 'private',
  [switch]$NoPrompt,
  [switch]$UseHttps
)
$ErrorActionPreference = 'Stop'

function Test-Command {
  param([Parameter(Mandatory=$true)][string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Convert-ToHttpsUrl {
  param([string]$RemoteUrl, [string]$Login, [string]$Repo)
  # Prefer parsing existing remote to preserve owner; fallback to login/repo
  if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
    # SSH: git@github.com:owner/repo.git
    if ($RemoteUrl -match 'git@github.com:(?<owner>[^/]+)/(?<name>[^\.]+)(\.git)?$') {
      $owner = $Matches['owner']; $name = $Matches['name']
      return "https://github.com/$owner/$name.git"
    }
    # HTTPS: https://github.com/owner/repo.git
    if ($RemoteUrl -match 'https://github.com/(?<owner>[^/]+)/(?<name>[^\.]+)(\.git)?$') {
      $owner = $Matches['owner']; $name = $Matches['name']
      return "https://github.com/$owner/$name.git"
    }
  }
  if (-not [string]::IsNullOrWhiteSpace($Login) -and -not [string]::IsNullOrWhiteSpace($Repo)) {
    return "https://github.com/$Login/$Repo.git"
  }
  return ''
}

if (-not (Test-Command -Name 'git')) {
  Write-Error "未检测到 git，请先安装 Git for Windows: https://git-scm.com/download/win"
  exit 127
}
if (-not (Test-Command -Name 'gh')) {
  Write-Error "未检测到 GitHub CLI (gh)。请先运行 VS Code 任务：gh: Bootstrap (check/install) 或手动安装 https://cli.github.com/"
  exit 127
}

# Debug info
Write-Host "[DEBUG] PSScriptRoot = $PSScriptRoot"
Write-Host "[DEBUG] CurrentLocation = $(Get-Location)"

# 计算工作区根目录与仓库名（脚本原先假定位于仓库的 scripts/ 下）
# 若脚本被安装到 PowerShell Modules（作为模块的一部分），则应以当前工作目录为工作区
$modulePathPattern = '[\\/]+Modules[\\/]'
if ($PSScriptRoot -and ($PSScriptRoot -match $modulePathPattern -or $PSScriptRoot -like '*:/Program Files/*')) {
  # likely running from an installed module or global location -> use current directory
  $workspace = (Get-Location).Path
} else {
  $workspace = Resolve-Path (Join-Path $PSScriptRoot '..')
}
$repoName = Split-Path -Path $workspace -Leaf

Write-Host "工作区: $workspace" -ForegroundColor Cyan
Write-Host "仓库名: $repoName" -ForegroundColor Cyan
Write-Host "可见性: $Visibility" -ForegroundColor Cyan

Push-Location $workspace
try {
  # 检查 gh 登录
  try {
    gh auth status | Out-Null
  } catch {
    Write-Error "gh 未登录。请先运行 VS Code 任务：gh: Login (browser) 或 gh: Login with token (masked)"
    exit 1
  }

  # 获取当前登录用户，用于定位远程 URL
  $login = ""
  try { $login = gh api user -q .login } catch {}

  # 初始化 git 仓库（如需要）
  $inside = $false
  try { $inside = (git rev-parse --is-inside-work-tree) -eq 'true' } catch {}
  if (-not $inside) {
    git init | Out-Null
  }

  # 选择默认分支 main（稳健：无提交时使用 orphan）
  $curBranch = ''
  try { $curBranch = (git rev-parse --abbrev-ref HEAD).Trim() } catch {}
  if ([string]::IsNullOrWhiteSpace($curBranch) -or $curBranch -eq 'HEAD') {
    # 尚无提交，创建 orphan 分支 main
    try { git checkout --orphan main | Out-Null } catch {}
  } elseif ($curBranch -ne 'main') {
    try { git branch -M main | Out-Null } catch {}
  }

  # 首次提交（如无提交）
  $hasCommit = $false
  try { git rev-parse --verify HEAD | Out-Null; $hasCommit = $true } catch {}
  if (-not $hasCommit) {
    # 尝试暂存当前所有文件
    git add -A | Out-Null
    # 检查是否已有暂存内容
    $staged = ""
    try { $staged = git diff --cached --name-only } catch {}
    if ([string]::IsNullOrWhiteSpace($staged)) {
      # 没有可提交的文件，创建一个 README 保障首个提交
      $readme = Join-Path $workspace 'README.md'
      if (-not (Test-Path -LiteralPath $readme)) {
        Set-Content -LiteralPath $readme -Encoding UTF8 -Value "# $repoName`r`n`r`nInitial commit."
      }
      git add -A | Out-Null
      try { $staged = git diff --cached --name-only } catch {}
    }
    # 确保存在提交身份（如未配置则为当前仓库设置临时身份）
    $cfgName = ''
    $cfgEmail = ''
    try { $cfgName = git config user.name } catch {}
    try { $cfgEmail = git config user.email } catch {}
    if ([string]::IsNullOrWhiteSpace($cfgName)) {
      if (-not [string]::IsNullOrWhiteSpace($login)) { git config user.name $login | Out-Null } else { git config user.name "Auto Commit" | Out-Null }
    }
    if ([string]::IsNullOrWhiteSpace($cfgEmail)) {
      $fallbackEmail = if (-not [string]::IsNullOrWhiteSpace($login)) { "$login@users.noreply.github.com" } else { "auto@noreply.local" }
      git config user.email $fallbackEmail | Out-Null
    }

    if ([string]::IsNullOrWhiteSpace($staged)) {
      # 仍然为空，使用允许空提交保障建立 HEAD
      git commit --allow-empty -m "Initial commit" | Out-Null
    } else {
      git commit -m "Initial commit" | Out-Null
    }
    if ($LASTEXITCODE -ne 0) {
      Write-Error "git commit 失败（退出码 $LASTEXITCODE）。请检查 git 配置或文件状态。可运行任务：gh: Setup Git。"
      exit $LASTEXITCODE
    }

    # 验证 HEAD 是否存在
    $headOk = $false
    try { git rev-parse --verify HEAD | Out-Null; $headOk = $true } catch {}
    if (-not $headOk) {
      Write-Error "未能建立首个提交（HEAD 不存在）。请检查上述输出，或手动执行：git add -A; git commit -m 'Initial commit'。"
      exit 1
    }
  }

  # 确保当前指向 main 分支（不论此前分支名为何，统一切到 main）
  try { git checkout -B main | Out-Null } catch {}

  # 检查是否已存在 origin
  $originUrl = ''
  try { $originUrl = git remote get-url origin } catch {}

  if (-not $originUrl) {
    # 创建 GitHub 仓库并设置 remote/push
    Write-Host "正在创建 GitHub 仓库..." -ForegroundColor Green
    $visibilityFlag = @{
      'private' = '--private'
      'public'  = '--public'
      'internal'= '--internal'
    }[$Visibility]

    $createExit = 0
    try {
      gh repo create $repoName $visibilityFlag --source "$workspace" --remote origin
      $createExit = $LASTEXITCODE
    } catch {
      $createExit = 1
    }

    if ($createExit -ne 0) {
      # 检测仓库是否真实存在
      $exists = $false
      try { gh repo view "$login/$repoName" --json name -q .name | Out-Null; if ($LASTEXITCODE -eq 0) { $exists = $true } } catch {}
      if (-not $exists) {
        Write-Error "GitHub 仓库创建失败且远端不存在：$login/$repoName。请检查 gh 权限或网络，然后重试。"
        exit 1
      }

      # 仓库已存在：设置 origin 并推送
      if (-not $login) {
        $login = Read-Host '请输入你的 GitHub 用户名（或 org 名称）'
      }
      if (-not $login) { throw "无法确定登录名，用于构建远程 URL。" }
      $url = "https://github.com/$login/$repoName.git"
      git remote add origin $url
      git push -u origin HEAD:refs/heads/main
    }
    else {
      # 创建成功后手动推送，避免 gh --push 在无提交时失败
      if ($UseHttps) {
        $httpsUrl = Convert-ToHttpsUrl (git remote get-url origin) $login $repoName
        if (-not [string]::IsNullOrWhiteSpace($httpsUrl)) { git remote set-url origin $httpsUrl | Out-Null }
      }
      git push -u origin HEAD:refs/heads/main
    }
  } else {
    Write-Host "已存在 origin: $originUrl" -ForegroundColor Yellow
    if ($UseHttps) {
      $httpsUrl = Convert-ToHttpsUrl $originUrl $login $repoName
      if (-not [string]::IsNullOrWhiteSpace($httpsUrl)) {
        Write-Host "切换远程为 HTTPS: $httpsUrl" -ForegroundColor Yellow
        git remote set-url origin $httpsUrl | Out-Null
      }
    }
    git push -u origin HEAD:refs/heads/main
  }
  $pushExit = $LASTEXITCODE
  if ($pushExit -eq 0) {
    Write-Host "完成：已将 $repoName 推送到 GitHub。" -ForegroundColor Green
  } else {
    Write-Error "推送失败（退出码 $pushExit）。请检查上方输出或运行任务：gh: Diagnostics (log)。"
    exit $pushExit
  }
} finally {
  Pop-Location
}
