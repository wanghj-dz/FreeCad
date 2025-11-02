param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg) { if (-not $Quiet) { Write-Host "[INFO] $msg" -ForegroundColor Cyan } }
function Write-Warn($msg) { if (-not $Quiet) { Write-Host "[WARN] $msg" -ForegroundColor Yellow } }
function Write-Err($msg)  { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# Ensure we're in a git repo
try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
} catch {
    Write-Err "Not inside a git repository. Open the repo folder and re-run."
    exit 1
}
Set-Location $repoRoot
Write-Info "Repo root: $repoRoot"

# Try to get owner/repo from gh first (more canonical)
$owner = $null
$repo  = $null
try {
    $nwo = gh repo view --json nameWithOwner -q .nameWithOwner 2>$null
    if ($LASTEXITCODE -eq 0 -and $nwo) {
        $parts = $nwo.Trim().Split('/')
        if ($parts.Length -eq 2) { $owner = $parts[0]; $repo = $parts[1] }
    }
} catch { }

# Fallback: parse from origin url
if (-not $owner -or -not $repo) {
    try {
        $origin = git config --get remote.origin.url 2>$null
    } catch { $origin = $null }

    if ($origin) {
        $sshRe   = [regex] '^[gG]it@github\.com:(?<owner>[^/]+)/(?<repo>[^.]+?)(?:\.git)?$'
        $httpsRe = [regex] '^https://github\.com/(?<owner>[^/]+)/(?<repo>[^.]+?)(?:\.git)?$'
        $m = $sshRe.Match($origin)
        if (-not $m.Success) { $m = $httpsRe.Match($origin) }
        if ($m.Success) {
            $owner = $m.Groups['owner'].Value
            $repo  = $m.Groups['repo'].Value
        }
    }
}

if (-not $owner -or -not $repo) {
    Write-Err "Cannot determine <owner>/<repo>. Ensure remote 'origin' exists or run 'gh repo set-default' and retry."
    exit 2
}

$newUrl = "git@github.com:$owner/$repo.git"
Write-Info "Setting origin to: $newUrl"

# Ensure origin exists or add
$hasOrigin = $false
try { git remote get-url origin *> $null; if ($LASTEXITCODE -eq 0) { $hasOrigin = $true } } catch { }

if ($hasOrigin) {
    git remote set-url origin $newUrl
} else {
    git remote add origin $newUrl
}

Write-Info "Remote now:"
 git remote -v | ForEach-Object { Write-Host "  $_" }

# Optional: advise if SSH keys are missing
try {
    $keys = Get-ChildItem -Path "$HOME/.ssh" -Filter "*.pub" -File -ErrorAction SilentlyContinue
    if (-not $keys) {
        Write-Warn "No SSH public keys found under $HOME/.ssh. You may need to generate and add one to GitHub."
        Write-Host "  Generate: ssh-keygen -t ed25519 -C \"you@example.com\"" -ForegroundColor DarkGray
        Write-Host "  Copy key:  Get-Content $HOME/.ssh/id_ed25519.pub | Set-Clipboard" -ForegroundColor DarkGray
        Write-Host "  Add at:   https://github.com/settings/keys" -ForegroundColor DarkGray
    }
} catch { }

exit 0
