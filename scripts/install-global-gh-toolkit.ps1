param(
    [switch]$Force
)
$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

$userProfilePath = [Environment]::GetFolderPath('UserProfile')
$toolkitRoot   = Join-Path $userProfilePath '.vscode-gh-toolkit'
$scriptsTarget = Join-Path $toolkitRoot 'scripts'

# Create folders
New-Item -Path $scriptsTarget -ItemType Directory -Force | Out-Null

# Source scripts from current workspace
$workspaceScripts = Join-Path $PSScriptRoot '.'
$toCopy = @(
    'gh-bootstrap.ps1',
    'gh-diagnostics.ps1',
    'gh-login-token.ps1',
    'gh-release-create.ps1',
    'gh-release-append-cn-notes.ps1',
    'generate-cn-highlights.ps1',
    'repo-create-and-push.ps1',
    'git-remote-to-https.ps1',
    'git-remote-to-ssh.ps1',
    'git-prefer-https.ps1',
    'git-prefer-ssh.ps1',
    'install-module-RepoToolkit.ps1',
    'merge-user-tasks.ps1',
    'backup-vscode-user.ps1',
    'restore-vscode-user.ps1',
    'bootstrap-after-reinstall.ps1'
)

foreach ($f in $toCopy) {
    $src = Join-Path $workspaceScripts $f
    $dst = Join-Path $scriptsTarget $f
    if (Test-Path -LiteralPath $src) {
        try {
            $srcFull = [IO.Path]::GetFullPath($src)
            $dstFull = [IO.Path]::GetFullPath($dst)
            if ($srcFull -eq $dstFull) {
                Info "Already up-to-date: $f"
            } else {
                Copy-Item -LiteralPath $src -Destination $dst -Force
                Info "Installed: $f"
            }
        } catch {
            Warn "Failed to install $($f): $_"
        }
    } else {
        Warn "Missing script: $f (skipped)"
    }
}

# Generate user tasks snippet
$globalPwsh = 'pwsh -NoProfile -ExecutionPolicy Bypass -File'
$tpl = @{
  version = '2.0.0'
  tasks = @(
    @{ label='global: gh: Bootstrap (check/install)'; type='shell'; command="$globalPwsh ${scriptsTarget}/gh-bootstrap.ps1" },
    @{ label='global: gh: Login (browser)'; type='shell'; command='gh auth login'; options=@{ shell=@{ executable='pwsh.exe'; args=@('-NoProfile','-ExecutionPolicy','Bypass','-Command') } } },
    @{ label='global: gh: Login with token (masked)'; type='shell'; command="$globalPwsh ${scriptsTarget}/gh-login-token.ps1" },
    @{ label='global: gh: Status'; type='shell'; command='gh auth status'; options=@{ shell=@{ executable='pwsh.exe'; args=@('-NoProfile','-ExecutionPolicy','Bypass','-Command') } } },
    @{ label='global: gh: Logout'; type='shell'; command='gh auth logout -h github.com'; options=@{ shell=@{ executable='pwsh.exe'; args=@('-NoProfile','-ExecutionPolicy','Bypass','-Command') } } },
    @{ label='global: gh: Diagnostics (log)'; type='shell'; command="$globalPwsh ${scriptsTarget}/gh-diagnostics.ps1" },
    @{ label='global: gh: Release Create (prompt, generate-notes)'; type='shell'; command="$globalPwsh ${scriptsTarget}/gh-release-create.ps1 -GenerateNotes" },
    @{ label='global: gh: Release Create (prompt, draft)'; type='shell'; command="$globalPwsh ${scriptsTarget}/gh-release-create.ps1 -Draft -GenerateNotes" },
    @{ label='global: gh: Release Append CN Highlights (auto)'; type='shell'; command="$globalPwsh ${scriptsTarget}/generate-cn-highlights.ps1 -UpdateRelease -Tag \${input:releaseTag}" },
    @{ label='global: repo: Create & Push (public, HTTPS)'; type='shell'; command="$globalPwsh ${scriptsTarget}/repo-create-and-push.ps1 -Visibility public -UseHttps -NoPrompt" },
    @{ label='global: repo: Create & Push (private, HTTPS)'; type='shell'; command="$globalPwsh ${scriptsTarget}/repo-create-and-push.ps1 -Visibility private -UseHttps -NoPrompt" },
    @{ label='global: repo: Switch remote to HTTPS'; type='shell'; command="$globalPwsh ${scriptsTarget}/git-remote-to-https.ps1" },
    @{ label='global: repo: Switch remote to SSH'; type='shell'; command="$globalPwsh ${scriptsTarget}/git-remote-to-ssh.ps1" },
    @{ label='global: repo: Prefer HTTPS (no SSH key)'; type='shell'; command="$globalPwsh ${scriptsTarget}/git-prefer-https.ps1" },
        @{ label='global: repo: Prefer SSH'; type='shell'; command="$globalPwsh ${scriptsTarget}/git-prefer-ssh.ps1" },
        # VS Code user profile helpers
        @{ label='global: VS Code: Backup user (zip)'; type='shell'; command="$globalPwsh ${scriptsTarget}/backup-vscode-user.ps1" },
        @{ label='global: VS Code: Restore user (latest, merge tasks)'; type='shell'; command="$globalPwsh ${scriptsTarget}/restore-vscode-user.ps1 -MergeTasks" },
        @{ label='global: VS Code: Bootstrap after reinstall'; type='shell'; command="$globalPwsh ${scriptsTarget}/bootstrap-after-reinstall.ps1" },
        # Module-based global tasks (require RepoToolkit installed)
        @{ label='global: module: Repo Create & Push (public, HTTPS)'; type='shell'; command='Import-Module RepoToolkit; Invoke-RepoCreateAndPush -Visibility public -UseHttps -NoPrompt'; options=@{ shell=@{ executable='pwsh.exe'; args=@('-NoProfile','-ExecutionPolicy','Bypass','-Command') } } },
        @{ label='global: module: Set Remote HTTPS'; type='shell'; command='Import-Module RepoToolkit; Set-RepoRemoteHttps'; options=@{ shell=@{ executable='pwsh.exe'; args=@('-NoProfile','-ExecutionPolicy','Bypass','-Command') } } },
        @{ label='global: module: Set Remote SSH'; type='shell'; command='Import-Module RepoToolkit; Set-RepoRemoteSsh'; options=@{ shell=@{ executable='pwsh.exe'; args=@('-NoProfile','-ExecutionPolicy','Bypass','-Command') } } },
        @{ label='global: module: Prefer HTTPS'; type='shell'; command='Import-Module RepoToolkit; Set-GitPreferenceHttps'; options=@{ shell=@{ executable='pwsh.exe'; args=@('-NoProfile','-ExecutionPolicy','Bypass','-Command') } } },
        @{ label='global: module: Prefer SSH'; type='shell'; command='Import-Module RepoToolkit; Set-GitPreferenceSsh'; options=@{ shell=@{ executable='pwsh.exe'; args=@('-NoProfile','-ExecutionPolicy','Bypass','-Command') } } },
        @{ label='global: module: Self-update RepoToolkit'; type='shell'; command="$globalPwsh ${scriptsTarget}/install-module-RepoToolkit.ps1" }
  )
}

# Serialize to JSON (no comments)
$snippetPath = Join-Path $toolkitRoot 'tasks.user.json'
($tpl | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $snippetPath -Encoding UTF8
Info "User tasks snippet generated: $snippetPath"

# Optionally install as user tasks if no tasks.json exists yet
$userTasks = Join-Path $env:APPDATA 'Code\User\tasks.json'
if (-not (Test-Path -LiteralPath $userTasks)) {
    Copy-Item -LiteralPath $snippetPath -Destination $userTasks
    Info "Installed user tasks to: $userTasks"
} else {
    Warn "User tasks already exist at $userTasks. Review and merge if desired."
    Write-Host "Open with:  Ctrl+Shift+P -> 'Tasks: Open User Tasks' and copy entries from:`n  $snippetPath" -ForegroundColor DarkGray
}

Info "Global toolkit installed to: $toolkitRoot"
