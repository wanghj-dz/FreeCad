param()
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$user = Join-Path $env:APPDATA 'Code\User\tasks.json'
$snip = Join-Path $env:USERPROFILE '.vscode-gh-toolkit\tasks.user.json'
if (-not (Test-Path -LiteralPath $snip)) { throw "Snippet not found: $snip" }
if (-not (Test-Path -LiteralPath $user)) {
  Copy-Item -LiteralPath $snip -Destination $user
  Info "Installed user tasks from snippet -> $user"
  exit 0
}
$u = Get-Content -LiteralPath $user -Raw | ConvertFrom-Json
$s = Get-Content -LiteralPath $snip -Raw | ConvertFrom-Json
if (-not $u.PSObject.Properties.Name.Contains('tasks')) {
  $u | Add-Member -NotePropertyName tasks -NotePropertyValue @()
}
$labels = @{}
foreach ($t in ($u.tasks | Where-Object { $_ -and $_.label })) { $labels[$t.label] = $true }
$added = 0
foreach ($t in ($s.tasks | Where-Object { $_ -and $_.label })) {
  if (-not $labels.ContainsKey($t.label)) { $u.tasks += $t; $labels[$t.label] = $true; $added++ }
}
$u | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $user -Encoding UTF8
Info ("Merged user tasks. Added: {0}. File: {1}" -f $added, $user)
