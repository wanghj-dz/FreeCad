param()
$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "GitHub CLI (gh) 未找到。请先安装: https://cli.github.com/"
  exit 127
}

$token = Read-Host -Prompt 'Paste your GitHub token' -MaskInput
if ([string]::IsNullOrWhiteSpace($token)) {
  Write-Host '已取消。'
  exit 0
}

[Console]::Out.Write($token) | gh auth login --with-token
$exit = $LASTEXITCODE

if ($exit -eq 0) {
  Write-Host 'gh auth login 成功。'
} else {
  Write-Error "gh auth login 失败，退出码 $exit"
}

# 清理内存中的令牌变量
try { Clear-Variable token -ErrorAction SilentlyContinue } catch {}
$token = $null

exit $exit
