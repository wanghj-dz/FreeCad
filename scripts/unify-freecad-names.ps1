param(
  [string[]]$SourceDirs,
  [string]$BaseOut,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

# Defaults
if (-not $SourceDirs -or $SourceDirs.Count -eq 0) {
  $SourceDirs = @((Get-Location).Path)
}
if (-not $BaseOut) {
  $BaseOut = Join-Path (Split-Path -Parent $PSCommandPath) '..' | Resolve-Path | Select-Object -ExpandProperty Path
  $BaseOut = Join-Path $BaseOut 'FreeCadTest'
}

function Get-TypeFolder([string]$ext){
  $e = $ext.TrimStart('.').ToLowerInvariant()
  switch ($e) {
    'fcstd' { return 'FCStd' }
    'step'  { return 'STEP' }
    'stp'   { return 'STEP' }
  'stl'   { return 'STL' }
    'pdf'   { return 'PDF' }
    default { return 'Other' }
  }
}

# Try to reuse an existing folder name (case-insensitive) under BaseOut
function Resolve-TypeFolderPath([string]$folder){
  $preferred = Join-Path $BaseOut $folder
  if (Test-Path -LiteralPath $BaseOut) {
    try {
      Get-ChildItem -LiteralPath $BaseOut -Directory | ForEach-Object {
        if ($_.Name.ToLowerInvariant() -eq $folder.ToLowerInvariant()) {
          $existing = $_.FullName
          return $existing
        }
      }
    } catch {}
  }
  return $preferred
}

# Ensure base output exists
if (-not (Test-Path -LiteralPath $BaseOut)) {
  if ($DryRun) { Info "[DryRun] Would create: $BaseOut" } else { New-Item -ItemType Directory -Path $BaseOut -Force | Out-Null }
}

# Timestamp pattern detection (suffix _YYYYMMDD-HHMMSS)
$tsRegex = '_\d{8}-\d{6}$'

# Collect files
$extensions = @('*.fcstd','*.step','*.stp','*.stl','*.pdf')
$files = @()
foreach ($dir in $SourceDirs) {
  if (-not (Test-Path -LiteralPath $dir)) { Warn "Skip missing dir: $dir"; continue }
  foreach ($pat in $extensions) {
    $files += Get-ChildItem -LiteralPath $dir -Recurse -File -Include $pat -ErrorAction SilentlyContinue
  }
}

if ($files.Count -eq 0) { Info 'No matching files found.'; exit 0 }

Info "Found $($files.Count) file(s) to consider. BaseOut: $BaseOut"

foreach ($f in $files) {
  try {
    $ext = [IO.Path]::GetExtension($f.Name)
    $nameNoExt = [IO.Path]::GetFileNameWithoutExtension($f.Name)

    # Skip if file is already under BaseOut with a proper type folder and has timestamp suffix
    $hasTs = [bool]([Text.RegularExpressions.Regex]::IsMatch($nameNoExt, $tsRegex))

    $typeFolder = Get-TypeFolder $ext
    $destTypeFolderPath = Resolve-TypeFolderPath $typeFolder
    if (-not (Test-Path -LiteralPath $destTypeFolderPath)) {
      if ($DryRun) { Info "[DryRun] Would create: $destTypeFolderPath" } else { New-Item -ItemType Directory -Path $destTypeFolderPath -Force | Out-Null }
    }

    # If no timestamp -> build from last write time
    $finalNameBase = $nameNoExt
    if (-not $hasTs) {
      $ts = $f.LastWriteTime.ToString('yyyyMMdd-HHmmss')
      $finalNameBase = "$nameNoExt" + '_' + $ts
    }

    # If has timestamp but sits under wrong folder, keep name, just move
    $finalName = "$finalNameBase$ext"

    # Resolve target path
    $destPath = Join-Path $destTypeFolderPath $finalName

    # Avoid overwriting: append -1, -2 if exists
    if (Test-Path -LiteralPath $destPath) {
      $i = 1
      do {
        $candidate = Join-Path $destTypeFolderPath ("{0}-{1}{2}" -f $finalNameBase, $i, $ext)
        $i++
      } while (Test-Path -LiteralPath $candidate)
      $destPath = $candidate
    }

    # Skip if already at destination with same name
    if ([IO.Path]::GetFullPath($f.FullName) -ieq [IO.Path]::GetFullPath($destPath)) {
      continue
    }

    if ($DryRun) {
      Info "[DryRun] MOVE: $($f.FullName) -> $destPath"
    } else {
      # Ensure source is not locked
      Move-Item -LiteralPath $f.FullName -Destination $destPath
      Info "Moved: $($f.FullName) -> $destPath"
    }
  } catch {
    Warn "Skip '$($f.FullName)': $($_.Exception.Message)"
  }
}

Info 'Done.'
