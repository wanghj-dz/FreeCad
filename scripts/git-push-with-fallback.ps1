$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

# Get origin URL
$origin = git remote get-url origin 2>$null
if (-not $origin) { Err "No 'origin' remote found."; exit 1 }
Info "Origin: $origin"

# First attempt: normal push
Info "Pushing: git push -u origin HEAD"
$pushOutput = & git push -u origin HEAD 2>&1
$code = $LASTEXITCODE
if ($code -eq 0) {
  $pushOutput | ForEach-Object { $_ }
  Info 'Push succeeded.'
  exit 0
}

# Detect SSH publickey failure
$combined = ($pushOutput | Out-String)
$sshRemote = ($origin -match '^git@github.com:')
$pubkeyError = ($combined -match 'Permission denied \(publickey\)') -or ($combined -match 'Could not read from remote repository') -or ($combined -match 'Load key')

if ($sshRemote -and $pubkeyError) {
  Warn 'SSH push failed due to public key/agent issue. Trying HTTPS fallback for this push (no permanent change)...'
  Info 'Fallback: git -c url.https://github.com/.insteadof=git@github.com: push -u origin HEAD'
  $fallbackOutput = & git -c url.https://github.com/.insteadof=git@github.com: push -u origin HEAD 2>&1
  $fallbackCode = $LASTEXITCODE
  $fallbackOutput | ForEach-Object { $_ }
  if ($fallbackCode -eq 0) {
    Info 'Push succeeded via HTTPS fallback. Consider switching remote to HTTPS if you do not plan to use SSH.'
    exit 0
  } else {
    Err 'HTTPS fallback push still failed.'
    Warn 'You can: (1) run task "repo: Prefer HTTPS (no SSH key)" to switch permanently; or (2) configure SSH key and agent, then retry.'
    exit $fallbackCode
  }
}

# Other failures: print original output and suggest next steps
$pushOutput | ForEach-Object { $_ }
Err "Push failed with exit code $code."
Warn 'If this is an SSH auth issue, run "repo: Prefer HTTPS (no SSH key)" or configure your SSH key (ssh-keygen, add to GitHub, ssh -T git@github.com).'
exit $code
