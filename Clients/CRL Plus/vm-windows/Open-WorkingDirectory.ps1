# Set eiConsole workingDirectory_0 to a given Windows path and (re)launch eiConsole.
# Usage: Open-WorkingDirectory.ps1 -EipRoot "C:\path\to\eip-root"

param(
    [Parameter(Mandatory = $true)]
    [string]$EipRoot
)

$ErrorActionPreference = 'Stop'
$LogPath = Join-Path $env:USERPROFILE 'AIL-eiconsole-startup.log'
$PrefsKey = 'HKCU:\SOFTWARE\JavaSoft\Prefs\com\pilotfish\eip\gui\console\config\prefs'
$PrefsValueName = 'com.pilotfish.eip.console.working/Directory_0'
$EiConsole = 'C:\Program Files\PilotFish Technology\eiConsole26R1\eiConsole.exe'

function Write-Log([string]$Message) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    try { Add-Content -Path $LogPath -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
}

function ConvertTo-JavaWindowsPrefsPath([string]$WindowsPath) {
    $normalized = $WindowsPath.TrimEnd('\')
    $javaPath = $normalized.Replace('\', '/')
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $javaPath.ToCharArray()) {
        if ($ch -eq '/') {
            [void]$sb.Append('//')
        }
        elseif ([char]::IsUpper($ch)) {
            [void]$sb.Append('/')
            [void]$sb.Append($ch)
        }
        else {
            [void]$sb.Append($ch)
        }
    }
    return $sb.ToString()
}

try {
    Write-Log '=== Open working directory begin ==='
    if (-not (Test-Path -LiteralPath (Join-Path $EipRoot 'interfaces'))) {
        throw "Not a usable eip-root (missing interfaces): $EipRoot"
    }

    $encoded = ConvertTo-JavaWindowsPrefsPath $EipRoot
    Write-Log "eip-root: $EipRoot"
    Write-Log "encoded: $encoded"

    if (-not (Test-Path -LiteralPath $PrefsKey)) {
        New-Item -Path $PrefsKey -Force | Out-Null
    }
    New-ItemProperty -Path $PrefsKey -Name $PrefsValueName -Value $encoded -PropertyType String -Force | Out-Null

    $current = (Get-ItemProperty -Path $PrefsKey -Name $PrefsValueName).$PrefsValueName
    if ($current -ne $encoded) { throw "Registry verify failed: $current" }
    Write-Log 'prefs set OK'

    Get-Process -Name 'eiConsole' -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Log "Stopping eiConsole PID $($_.Id)"
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 1

    if (-not (Test-Path -LiteralPath $EiConsole)) {
        throw "eiConsole not found at $EiConsole"
    }
    Start-Process -FilePath $EiConsole
    Write-Log 'Started eiConsole.exe'
    Write-Log '=== Open working directory OK ==='
    exit 0
}
catch {
    Write-Log ("ERROR: " + $_.Exception.Message)
    exit 1
}
