@{
    RootModule        = 'RepoToolkit.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'e5a6a2e3-cf9f-4d84-9b7b-5c6c2e7a0b2d'
    Author            = 'wanghj-dz'
    CompanyName       = 'Open Source'
    Copyright        = '(c) 2025 wanghj-dz. All rights reserved.'
    Description       = 'Lightweight repo + GitHub CLI helpers as a PowerShell module.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Install-RepoToolkitGlobalTasks',
        'Invoke-RepoCreateAndPush',
        'Set-RepoRemoteHttps','Set-RepoRemoteSsh',
        'Set-GitPreferenceHttps','Set-GitPreferenceSsh',
        'Invoke-GhBootstrap','Invoke-GhDiagnostics','Invoke-GhLoginToken',
        'Get-RepoToolkitInfo'
    )
    CmdletsToExport   = @()
    AliasesToExport   = @()
    PrivateData       = @{}
}
