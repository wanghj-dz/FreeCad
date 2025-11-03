param(
  [Parameter(Mandatory=$true)][string]$ScriptPath,
  [string]$LogPath,
  [string]$OutputPath
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

if (-not (Test-Path -LiteralPath $ScriptPath)) { Err "Script not found: $ScriptPath"; exit 1 }

# Candidate FreeCADCmd paths
$candidates = @(
  'C:\\Users\\admin\\scoop\\apps\\freecad\\current\\bin\\freecadcmd.exe',
  'C:\\Users\\admin\\scoop\\shims\\freecadcmd.exe',
  'C:\\Program Files\\FreeCAD 1.0\\bin\\FreeCADCmd.exe',
  'C:\\Program Files\\FreeCAD 0.21\\bin\\FreeCADCmd.exe'
)
$fc = $null
foreach ($p in $candidates) { if (Test-Path -LiteralPath $p) { $fc = $p; break } }
if (-not $fc) { Err 'FreeCADCmd.exe not found. Please install FreeCAD or update paths.'; exit 1 }

if (-not $LogPath) {
  $logDir = Join-Path (Split-Path -Parent $ScriptPath) '..\\.logs'
  New-Item -ItemType Directory -Path $logDir -Force | Out-Null
  $base = [IO.Path]::GetFileNameWithoutExtension($ScriptPath)
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $LogPath = Join-Path $logDir ("$base-$ts.log")
}

Info "Using FreeCADCmd: $fc"
Info "Running: $ScriptPath"
Info "Log: $LogPath"

if ($OutputPath) {
  try {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
  } catch {
    Err "Failed to create output directory: $OutputPath - $($_.Exception.Message)"
    exit 1
  }
  $env:FREECAD_OUTPUT = $OutputPath
  Info "Set FREECAD_OUTPUT=$OutputPath"
}

& $fc $ScriptPath 2>&1 | Tee-Object -FilePath $LogPath

if ($LASTEXITCODE -ne 0) { Err "FreeCADCmd exited with code $LASTEXITCODE"; exit $LASTEXITCODE }
Info 'Done.'
