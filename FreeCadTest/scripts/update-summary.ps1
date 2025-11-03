param(
  [string]$BasePath
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

# Resolve BasePath to FreeCadTest
if (-not $BasePath -or $BasePath.Trim() -eq '') {
  $BasePath = (Split-Path -Parent $PSCommandPath) | Split-Path -Parent
}
$BasePath = (Resolve-Path -LiteralPath $BasePath).Path

$types = @(
  @{ Name = 'FCStd'; Folder = 'FCStd'; Exts = @('.FCStd') },
  @{ Name = 'STEP';  Folder = 'STEP'; Exts = @('.step','.stp') },
  @{ Name = 'STL';   Folder = 'STL';  Exts = @('.stl') },
  @{ Name = 'PDF';   Folder = 'PDF';  Exts = @('.pdf') }
)

$tsRegex = '_\d{8}-\d{6}$'
$all = @()
foreach ($t in $types) {
  $dir = Join-Path $BasePath $t.Folder
  if (-not (Test-Path -LiteralPath $dir)) { continue }
  $files = Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    if (-not ($t.Exts -contains $f.Extension)) { continue }
    $nameNoExt = [IO.Path]::GetFileNameWithoutExtension($f.Name)
    $m = [Text.RegularExpressions.Regex]::Match($nameNoExt, $tsRegex)
    if ($m.Success) {
      $ts = $m.Value.TrimStart('_')
      $all += [pscustomobject]@{ Type=$t.Name; Rel=(Resolve-Path -Relative $f.FullName); Ts=$ts; Full=$f.FullName }
    }
  }
}

if ($all.Count -eq 0) { Warn 'No timestamped files found under FCStd/STEP/STL/PDF.'; exit 0 }

# Find latest timestamp
$latestTs = ($all | Sort-Object Ts | Select-Object -Last 1).Ts
$grouped = $types | ForEach-Object {
  $typeName = $_.Name
  $items = $all | Where-Object { $_.Ts -eq $latestTs -and $_.Type -eq $typeName } | Sort-Object Rel
  [pscustomobject]@{ Type=$typeName; Items=$items }
}

# Build markdown summary
$lines = @()
$lines += '## 最近一次运行摘要'
$lines += ''
$lines += "生成时间戳：$latestTs"
$lines += ''
foreach ($g in $grouped) {
  $lines += "- $($g.Type):"
  if ($g.Items.Count -gt 0) {
    foreach ($it in $g.Items) {
      $rel = [IO.Path]::GetRelativePath($BasePath, $it.Full)
      $rel = $rel -replace '\\','/'
      $lines += "  - $rel"
    }
  } else {
    $lines += '  - <无>'
  }
}
$lines += ''

# Insert or replace block in README.md
$readme = Join-Path $BasePath 'README.md'
if (-not (Test-Path -LiteralPath $readme)) {
  Warn "README.md not found at $BasePath. Creating a minimal one."
  @(
    '# FreeCadTest 输出目录说明',
    '',
    '<!-- RUN-SUMMARY-START -->',
    ($lines -join "`n"),
    '<!-- RUN-SUMMARY-END -->',
    ''
  ) | Set-Content -LiteralPath $readme -Encoding UTF8
  Info "Created README with summary."
  exit 0
}

$content = Get-Content -LiteralPath $readme -Raw -Encoding UTF8
$startTag = '<!-- RUN-SUMMARY-START -->'
$endTag = '<!-- RUN-SUMMARY-END -->'
$newBlock = "$startTag`n$($lines -join "`n")`n$endTag"

if ($content -like "*${startTag}*") {
  if ($content -like "*${endTag}*") {
    $pattern = [regex]::Escape($startTag) + '.*?' + [regex]::Escape($endTag)
    $updated = [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newBlock }, 'Singleline')
  } else {
    $updated = $content + "`n" + $newBlock + "`n"
  }
} else {
  $updated = $content.TrimEnd() + "`n`n" + $newBlock + "`n"
}

Set-Content -LiteralPath $readme -Value $updated -Encoding UTF8
Info "Updated summary for $latestTs"