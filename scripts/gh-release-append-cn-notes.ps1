param(
  [Parameter(Mandatory=$true)][string]$Tag,
  [string[]]$Lines,
  [string]$LinesText
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

if ($LinesText) {
  $Lines = $LinesText -split '\|\|'
}

if (-not $Lines -or $Lines.Count -eq 0) {
  Warn 'No Chinese lines provided; using placeholder.'
  $Lines = @('此版本中文要点占位。')
}

$orig = gh release view $Tag --json body --jq .body
if ($LASTEXITCODE -ne 0) { throw "Failed to get existing release body for $Tag" }

$cn = "## 中文要点`n" + ($Lines | ForEach-Object { "- $_" } | Out-String).TrimEnd()
$newBody = $cn + "`n`n---`n`n" + $orig

$tmp = Join-Path $env:TEMP ("notes-" + $Tag + ".md")
[IO.File]::WriteAllText($tmp, $newBody, [Text.Encoding]::UTF8)

gh release edit $Tag --notes-file "$tmp"
if ($LASTEXITCODE -ne 0) { throw "Failed to update release notes for $Tag" }

Info "Updated release notes for $Tag with Chinese highlights."
