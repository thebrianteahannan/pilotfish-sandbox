# Sets PilotFish eiConsole workingDirectory_0 via Java Preferences (Windows registry)
# and launches eiConsole. Designed to run at interactive logon as brianhannan.
#
# Java Preferences node:
#   HKCU\SOFTWARE\JavaSoft\Prefs\com\pilotfish\eip\gui\console\config\prefs
# Value name (Windows encoding of workingDirectory_0):
#   com.pilotfish.eip.console.working/Directory_0
#
# Value encoding: Java path /C:/... with uppercase letters prefixed by '/' and
# each '/' doubled for Windows Preferences storage.

$ErrorActionPreference = 'Stop'

$LogPath = Join-Path $env:USERPROFILE 'AIL-eiconsole-startup.log'
$PrefsKey = 'HKCU:\SOFTWARE\JavaSoft\Prefs\com\pilotfish\eip\gui\console\config\prefs'
$PrefsValueName = 'com.pilotfish.eip.console.working/Directory_0'
$EiConsole = 'C:\Program Files\PilotFish Technology\eiConsole26R1\eiConsole.exe'

# Preferred live repo path (Parallels Mac share), then local staged copy.
$Candidates = @(
    'C:\Mac\Home\Documents\PilotFish Sandbox\Clients\CRL Plus\eip-root',
    'C:\Users\brianhannan\PilotFish eiConsole Working Directories\CRL Plus - AIL\eip-root',
    'C:\AIL-eip-root'
)

function Write-Log([string]$Message) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    try { Add-Content -Path $LogPath -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
}

# Encode a Windows path the way Java Preferences stores it on Windows.
# Example: C:\Mac\Home\...\eip-root
#       -> /C:///Mac///Home///...//eip-root
# (drive path as C:/... with no leading slash; uppercase letters get a '/'
#  prefix; each '/' is doubled.)
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
    Write-Log '=== AIL eiConsole startup begin ==='

    $eipRoot = $null
    foreach ($c in $Candidates) {
        if (Test-Path -LiteralPath (Join-Path $c 'interfaces')) {
            $eipRoot = $c
            break
        }
    }
    if (-not $eipRoot) {
        throw "No usable eip-root found. Tried: $($Candidates -join '; ')"
    }
    Write-Log "Using eip-root: $eipRoot"

    $encoded = ConvertTo-JavaWindowsPrefsPath $eipRoot
    Write-Log "Encoded prefs value: $encoded"

    if (-not (Test-Path -LiteralPath $PrefsKey)) {
        New-Item -Path $PrefsKey -Force | Out-Null
    }
    New-ItemProperty -Path $PrefsKey -Name $PrefsValueName -Value $encoded -PropertyType String -Force | Out-Null
    Write-Log "Set $PrefsValueName"

    # Verify
    $current = (Get-ItemProperty -Path $PrefsKey -Name $PrefsValueName).$PrefsValueName
    Write-Log "Verified: $current"
    if ($current -ne $encoded) {
        throw "Registry verify failed"
    }

    if (-not (Test-Path -LiteralPath $EiConsole)) {
        throw "eiConsole not found at $EiConsole"
    }

    $running = Get-Process -Name 'eiConsole' -ErrorAction SilentlyContinue
    if ($running) {
        Write-Log "eiConsole already running (PID(s): $($running.Id -join ',')). Leaving existing instance."
    }
    else {
        Start-Process -FilePath $EiConsole
        Write-Log 'Started eiConsole.exe'
    }

    Write-Log '=== AIL eiConsole startup OK ==='
    exit 0
}
catch {
    Write-Log ("ERROR: " + $_.Exception.Message)
    exit 1
}
