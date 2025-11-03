param(
  [string]$Email
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

try {
  $sshExe = 'C:\Windows\System32\OpenSSH\ssh.exe'
  $sshKeygen = 'C:\Windows\System32\OpenSSH\ssh-keygen.exe'
  $sshAdd = 'C:\Windows\System32\OpenSSH\ssh-add.exe'
  if (-not (Test-Path -LiteralPath $sshExe)) { Err 'Windows OpenSSH not found.'; exit 1 }
  # Force git to use Windows OpenSSH
  git config --global core.sshCommand $sshExe | Out-Null
  Info "Git core.sshCommand set to: $sshExe"

  if (-not $Email -or $Email.Trim() -eq '') {
    $Email = git config user.email 2>$null
    if (-not $Email -or $Email.Trim() -eq '') { $Email = 'github-key@local' }
  }

  $sshDir = Join-Path $HOME '.ssh'
  if (-not (Test-Path -LiteralPath $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
  $keyPath = Join-Path $sshDir 'id_ed25519'
  $pubPath = $keyPath + '.pub'

  # Backup existing
  if (Test-Path -LiteralPath $keyPath) { Copy-Item -LiteralPath $keyPath -Destination ($keyPath + '.bak') -Force; Remove-Item -LiteralPath $keyPath -Force }
  if (Test-Path -LiteralPath $pubPath) { Copy-Item -LiteralPath $pubPath -Destination ($pubPath + '.bak') -Force; Remove-Item -LiteralPath $pubPath -Force }

  # Generate new key (no passphrase for automation; you can add later with ssh-keygen -p)
  & $sshKeygen -t ed25519 -a 64 -C $Email -f $keyPath -N '' -q
  Info "Generated new ed25519 key at: $keyPath"

  # Ensure ssh-agent running
  Set-Service -Name ssh-agent -StartupType Automatic
  Start-Service -Name ssh-agent
  Info 'ssh-agent is running.'

  # Add key to agent
  & $sshAdd $keyPath | Out-Null
  Info 'Key added to ssh-agent.'

  # Copy pub key to clipboard and open GitHub keys page
  Get-Content -LiteralPath $pubPath | Set-Clipboard
  Info 'Public key copied to clipboard.'
  Start-Process 'https://github.com/settings/keys'
  Warn 'Paste the key into GitHub -> Settings -> SSH and GPG keys -> New SSH key. Then run: ssh -T git@github.com (accept host key on first connect).'

} catch {
  Err $_
  exit 1
}
