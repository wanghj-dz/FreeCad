param(
  [string]$Tag,
  [string]$Title,
  [switch]$GenerateNotes,
  [switch]$Draft
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

if (-not $Tag) {
  $Tag = Read-Host "请输入发布版本标签 (例如 v0.1.1)"
}
if (-not $Tag) { throw "必须提供 Tag" }
if (-not $Title) { $Title = "$Tag – Release" }

$argsList = @('release','create', $Tag, '--title', $Title)
if ($GenerateNotes) { $argsList += '--generate-notes' }
if ($Draft) { $argsList += '--draft' }

Info "执行: gh $($argsList -join ' ')"
& gh @argsList | Tee-Object -Variable out | Out-Host
if ($LASTEXITCODE -ne 0) { throw "gh release create 失败 (exit $LASTEXITCODE)" }
if ($out -match '^https?://') { Info "发布已创建: $out" } else { Info "发布创建完成" }
