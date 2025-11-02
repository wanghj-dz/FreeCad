<#
.SYNOPSIS
  根据 Git 提交生成“中文要点”并可自动更新指定 Release 的说明。

.PARAMETER Tag
  要更新的 Release 标签（例如 v0.1.2）。若未指定，将尝试取最新标签。

.PARAMETER FromTag
  统计范围起点标签（不含）。若未指定，则尝试取 Tag 的上一个标签；若不存在则从仓库初始开始。

.PARAMETER ToRef
  统计范围终点（含）。默认使用 Tag 对应的提交；若未指定 Tag 则使用 HEAD。

.PARAMETER MaxItems
  输出的中文要点条数上限（默认 5）。

.PARAMETER UpdateRelease
  写回 GitHub Release（在“中文要点”分节顶部追加，保留原说明）。

.PARAMETER Preview
  仅在控制台输出生成内容，不更新 Release。

.EXAMPLE
  pwsh -File generate-cn-highlights.ps1 -Tag v0.1.2 -UpdateRelease

#>
param(
  [string]$Tag,
  [string]$FromTag,
  [string]$ToRef,
  [int]$MaxItems = 5,
  [switch]$UpdateRelease,
  [switch]$Preview
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

function Exec($cmd, [string[]]$args){
  $p = Start-Process -FilePath $cmd -ArgumentList $args -NoNewWindow -PassThru -RedirectStandardOutput ([IO.Path]::GetTempFileName()) -RedirectStandardError ([IO.Path]::GetTempFileName())
  $p.WaitForExit()
  $out = Get-Content -Raw -LiteralPath $p.RedirectStandardOutput
  $err = Get-Content -Raw -LiteralPath $p.RedirectStandardError
  if ($p.ExitCode -ne 0) { throw "${cmd} ${args -join ' '} failed ($($p.ExitCode)): $err" }
  return $out
}

# Ensure git is available
try { git --version | Out-Null } catch { throw 'git not found in PATH' }

# Resolve Tag and ToRef
if (-not $Tag) {
  try { $Tag = (Exec 'git' @('describe','--abbrev=0','--tags')).Trim() } catch { Warn 'No tags found; treating ToRef=HEAD'; $Tag = $null }
}
if (-not $ToRef) {
  $ToRef = if ($Tag) { $Tag } else { 'HEAD' }
}

# Determine FromTag if not given
if (-not $FromTag -and $Tag) {
  $allTags = (Exec 'git' @('tag','--sort=creatordate')).Trim().Split("`n") | Where-Object { $_ }
  $idx = $allTags.IndexOf($Tag)
  if ($idx -gt 0) { $FromTag = $allTags[$idx-1] } else { $FromTag = $null }
}

$range = if ($FromTag) { "$FromTag..$ToRef" } else { $ToRef }
Info "Collecting commits in range: $range"

# Collect commit subjects
$logFmt = '%H%x09%s'
$args = @('log', $range, "--pretty=format:$logFmt")
$raw = Exec 'git' $args
$lines = @()
if ($raw) { $lines = $raw.Trim().Split("`n") }

if (-not $lines -or $lines.Count -eq 0) {
  Warn 'No commits found in range.'
}

# Parse Conventional Commits type and subject
$mapCn = @{ feat='新功能'; fix='修复'; docs='文档'; chore='杂项'; refactor='重构'; perf='性能'; test='测试'; build='构建'; ci='CI'; style='风格'; revert='回滚' }
$items = @()
foreach ($l in $lines) {
  $parts = $l.Split("`t",2)
  if ($parts.Count -lt 2) { continue }
  $subject = $parts[1]
  # Extract type
  $type = $null
  if ($subject -match '^(?<t>[a-zA-Z]+)(\([^\)]*\))?(!)?:\s*(?<msg>.+)$') {
    $type = $Matches['t'].ToLower()
    $msg = $Matches['msg']
  } else {
    $msg = $subject
  }
  $cnType = if ($type -and $mapCn.ContainsKey($type)) { $mapCn[$type] } else { '更新' }
  $msg = $msg.Trim()
  # Trim long
  if ($msg.Length -gt 80) { $msg = $msg.Substring(0,77) + '…' }
  $items += [PSCustomObject]@{ Type=$type; CnType=$cnType; Msg=$msg }
}

# Choose up to MaxItems, prefer feat/fix first
$prio = @{ feat=1; fix=2; perf=3; refactor=4; docs=5; test=6; build=7; ci=8; style=9; chore=10; revert=11 }
$sorted = $items | Sort-Object @{Expression={ if ($_.Type -and $prio.ContainsKey($_.Type)) { $prio[$_.Type] } else { 99 } }}, @{Expression={$_.Msg}} | Select-Object -First $MaxItems

# Build Chinese bullets
$bullets = $sorted | ForEach-Object { "- $($_.CnType)：$($_.Msg)" }
$cnHeader = "## 中文要点"
$cnBody = if ($bullets.Count -gt 0) { ($cnHeader + "`n" + ($bullets -join "`n")) } else { ($cnHeader + "`n- 本次变更包含维护性更新") }

if ($Preview -or -not $UpdateRelease) {
  Write-Output $cnBody
  return
}

if (-not $Tag) { throw 'UpdateRelease 需要提供 -Tag 或仓库存在最新标签' }

# Fetch existing release notes
try { $orig = (Exec 'gh' @('release','view',$Tag,'--json','body','--jq','.body')).Trim() } catch { throw "Failed to fetch release body for $Tag: $_" }

$newBody = $cnBody + "`n`n---`n`n" + $orig
$tmp = Join-Path $env:TEMP ("cn-highlights-" + $Tag + ".md")
[IO.File]::WriteAllText($tmp, $newBody, [Text.Encoding]::UTF8)
Exec 'gh' @('release','edit',$Tag,'--notes-file', $tmp) | Out-Null
Info "Release $Tag updated with Chinese highlights ($($bullets.Count) items)."
