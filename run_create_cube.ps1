param(
    [double]$Length = 10,
    [double]$Width  = 10,
    [double]$Height = 10,
    [string]$Fcstd,
    [string]$Stl,
    [string]$Name = 'MyCube',
    [string]$Pos,           # "x,y,z" mm
    [string]$Rot,           # "rx,ry,rz" degrees
    [double]$HoleRadius = 0,
    [ValidateSet('X','Y','Z')]
    [string]$HoleAxis = 'Z'
)

# Candidate FreeCADCmd paths (Scoop first)
$candidates = @(
    'C:\Users\admin\scoop\apps\freecad\current\bin\freecadcmd.exe',
    'C:\Program Files\FreeCAD 1.0\bin\FreeCADCmd.exe',
    'C:\Program Files\FreeCAD 0.21\bin\FreeCADCmd.exe'
)

$fc = $null
foreach ($p in $candidates) {
    if (Test-Path $p) { $fc = $p; break }
}
if (-not $fc) {
    Write-Error '未找到 FreeCADCmd.exe，请安装 FreeCAD 或更新脚本中的候选路径。'
    exit 1
}

# Prepare environment variables for the child process
$env:FC_LENGTH = $Length.ToString([System.Globalization.CultureInfo]::InvariantCulture)
$env:FC_WIDTH  = $Width.ToString([System.Globalization.CultureInfo]::InvariantCulture)
$env:FC_HEIGHT = $Height.ToString([System.Globalization.CultureInfo]::InvariantCulture)
if ($Fcstd) { $env:FC_FCSTD = $Fcstd } else { Remove-Item Env:FC_FCSTD -ErrorAction SilentlyContinue }
if ($Stl)   { $env:FC_STL   = $Stl }   else { Remove-Item Env:FC_STL   -ErrorAction SilentlyContinue }
if ($Name)  { $env:FC_NAME  = $Name }  else { Remove-Item Env:FC_NAME  -ErrorAction SilentlyContinue }
if ($Pos)   { $env:FC_POS   = $Pos }   else { Remove-Item Env:FC_POS   -ErrorAction SilentlyContinue }
if ($Rot)   { $env:FC_ROT   = $Rot }   else { Remove-Item Env:FC_ROT   -ErrorAction SilentlyContinue }
if ($HoleRadius -gt 0) { $env:FC_HOLE_RADIUS = $HoleRadius.ToString([System.Globalization.CultureInfo]::InvariantCulture) } else { Remove-Item Env:FC_HOLE_RADIUS -ErrorAction SilentlyContinue }
if ($HoleAxis) { $env:FC_HOLE_AXIS = $HoleAxis.ToUpper() } else { Remove-Item Env:FC_HOLE_AXIS -ErrorAction SilentlyContinue }

# Run
& $fc 'd:\FreeCad\create_cube.py'

# Optional: show the newest FCStd path
Get-ChildItem -Path 'd:\FreeCad' -Filter '*.FCStd' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1 FullName, LastWriteTime | Format-Table -AutoSize
