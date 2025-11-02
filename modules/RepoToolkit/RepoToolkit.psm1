# RepoToolkit PowerShell Module
# Lightweight wrappers around repo/gh tasks with built-in script delegation.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-ToolkitScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Name,
        [string[]]$ArgumentList
    )
    $scriptsDir = Join-Path $PSScriptRoot 'Scripts'
    $scriptPath = Join-Path $scriptsDir $Name
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Toolkit script not found: $scriptPath"
    }
    & $scriptPath @ArgumentList
}

function Install-RepoToolkitGlobalTasks {
    [CmdletBinding()] param()
    Invoke-ToolkitScript -Name 'install-global-gh-toolkit.ps1'
}

function Invoke-RepoCreateAndPush {
    [CmdletBinding()]
    param(
        [ValidateSet('private','public','internal')]
        [string]$Visibility = 'private',
        [switch]$UseHttps,
        [switch]$NoPrompt
    )
    $args = @('-Visibility', $Visibility)
    if ($UseHttps) { $args += '-UseHttps' }
    if ($NoPrompt) { $args += '-NoPrompt' }
    Invoke-ToolkitScript -Name 'repo-create-and-push.ps1' -ArgumentList $args
}

function Set-RepoRemoteHttps { [CmdletBinding()] param() Invoke-ToolkitScript -Name 'git-remote-to-https.ps1' }
function Set-RepoRemoteSsh   { [CmdletBinding()] param() Invoke-ToolkitScript -Name 'git-remote-to-ssh.ps1' }

function Set-GitPreferenceHttps { [CmdletBinding()] param() Invoke-ToolkitScript -Name 'git-prefer-https.ps1' }
function Set-GitPreferenceSsh   { [CmdletBinding()] param() Invoke-ToolkitScript -Name 'git-prefer-ssh.ps1' }

function Invoke-GhBootstrap   { [CmdletBinding()] param() Invoke-ToolkitScript -Name 'gh-bootstrap.ps1' }
function Invoke-GhDiagnostics { [CmdletBinding()] param() Invoke-ToolkitScript -Name 'gh-diagnostics.ps1' }
function Invoke-GhLoginToken  { [CmdletBinding()] param() Invoke-ToolkitScript -Name 'gh-login-token.ps1' }

function Get-RepoToolkitInfo {
    [CmdletBinding()] param()
    [pscustomobject]@{
        ModuleRoot = $PSScriptRoot
        Scripts    = Join-Path $PSScriptRoot 'Scripts'
        Version    = (Test-ModuleManifest (Join-Path $PSScriptRoot 'RepoToolkit.psd1')).ModuleVersion.ToString()
    }
}

Export-ModuleMember -Function \
    Install-RepoToolkitGlobalTasks, \
    Invoke-RepoCreateAndPush, \
    Set-RepoRemoteHttps, Set-RepoRemoteSsh, \
    Set-GitPreferenceHttps, Set-GitPreferenceSsh, \
    Invoke-GhBootstrap, Invoke-GhDiagnostics, Invoke-GhLoginToken, \
    Get-RepoToolkitInfo
