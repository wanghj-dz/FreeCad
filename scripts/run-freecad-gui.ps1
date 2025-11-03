param(
  [string]$ScriptPath
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

# Candidate FreeCAD GUI paths
$candidates = @(
  'C:\\Users\\admin\\scoop\\apps\\freecad\\current\\bin\\freecad.exe',
  'C:\\Users\\admin\\scoop\\shims\\freecad.exe',
  'C:\\Program Files\\FreeCAD 1.0\\bin\\FreeCAD.exe',
  'C:\\Program Files\\FreeCAD 0.21\\bin\\FreeCAD.exe'
)
$fe = $null
foreach ($p in $candidates) { if (Test-Path -LiteralPath $p) { $fe = $p; break } }
if (-not $fe) { Err 'FreeCAD.exe not found. Please install FreeCAD or update paths.'; exit 1 }

Info "Using FreeCAD GUI: $fe"

# Note: Launching GUI with a Python script for auto-execution is version-specific.
# For reliability, we launch the GUI only and print guidance.
# If $ScriptPath is provided, we echo a tip to run it via GUI Python console.

Start-Process -FilePath $fe | Out-Null

if ($ScriptPath) {
  if (Test-Path -LiteralPath $ScriptPath) {
    $norm = (Resolve-Path -LiteralPath $ScriptPath).Path
    Info "GUI started. In FreeCAD GUI, open Python console and run:`n  exec(compile(open(r'$norm','rb').read(), r'$norm', 'exec'))"
  } else {
    Err "Script path not found: $ScriptPath"
  }
} else {
  Info 'GUI started. Open Python console to run scripts under FreecadGUIPys.'
}
