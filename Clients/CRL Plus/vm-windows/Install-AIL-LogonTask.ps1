# Installs an At-logon scheduled task that sets eiConsole workingDirectory_0
# and launches eiConsole for the interactive user.

$ErrorActionPreference = 'Stop'
$LogPath = Join-Path $env:USERPROFILE 'AIL-eiconsole-startup.log'
$InstalledScript = 'C:\AIL-Set-eiConsolePrefs.ps1'
$TaskName = 'AIL-eiConsole-AtLogon'

function Write-Log([string]$Message) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    try { Add-Content -Path $LogPath -Value $line -Encoding UTF8 } catch {}
}

try {
    Write-Log 'Install begin'

    $scriptRoot = $PSScriptRoot
    if (-not $scriptRoot -and $MyInvocation.MyCommand.Path) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    $Candidates = @(
        'C:\Mac\Home\Documents\PilotFish Sandbox\Clients\CRL Plus\vm-windows\Set-AIL-eiConsolePrefs.ps1',
        $InstalledScript
    )
    if ($scriptRoot) {
        $Candidates = @((Join-Path $scriptRoot 'Set-AIL-eiConsolePrefs.ps1')) + $Candidates
    }

    $StartupScript = $null
    foreach ($c in $Candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) {
            $StartupScript = $c
            break
        }
    }
    if (-not $StartupScript) {
        throw "Could not find Set-AIL-eiConsolePrefs.ps1"
    }

    Write-Log "Source script: $StartupScript"
    Copy-Item -LiteralPath $StartupScript -Destination $InstalledScript -Force

    $user = $env:USERNAME
    if (-not $user -or $user -like '*$') { $user = 'brianhannan' }
    Write-Log "Task user: $user"

    # Prefer schtasks for reliability under interactive scheduled-task context.
    $tr = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File $InstalledScript"
    $create = schtasks /Create /TN $TaskName /TR $tr /SC ONLOGON /RU $user /IT /F
    Write-Log ("schtasks create: " + ($create -join ' '))

    foreach ($old in @('CheckAILPrefs', 'LaunchAILConsole', 'OpenEiConsoleAIL', 'SetAILPrefs', 'AIL-Install-LogonTask', 'AIL-eiConsole-Now')) {
        schtasks /Delete /TN $old /F 2>$null | Out-Null
    }

    Write-Log 'Running prefs+launch once now...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $InstalledScript
    $code = $LASTEXITCODE
    Write-Log "One-shot exit code: $code"
    if ($null -eq $code) { $code = 0 }
    exit $code
}
catch {
    Write-Log ("INSTALL ERROR: " + $_.Exception.Message)
    exit 1
}
