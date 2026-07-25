# iPad → Windows eiConsole (AIL routes)

## Status
- Windows 11 Parallels VM: **Windows 11 (1)**
- Guest RDP: `10.211.55.4:3389` (Parallels Shared network)
- Mac LAN forward: **`192.168.68.52:3390` → VM RDP** (LaunchAgent `com.pilotfish.ail-rdp-forward`)
- eiConsole working directory is set via Java Preferences registry so the console opens on the AIL tree.

## Working directory (registry)
eiConsole ignores CLI path args. It reads recent working directories from Java Preferences:

- Hive / key:  
  `HKCU\SOFTWARE\JavaSoft\Prefs\com\pilotfish\eip\gui\console\config\prefs`
- Value name: `com.pilotfish.eip.console.working/Directory_0`
- Target path:  
  `C:\Mac\Home\Documents\PilotFish Sandbox\Clients\CRL Plus\eip-root`
- Encoded value:  
  `/C:///Mac///Home///Documents///Pilot/Fish /Sandbox///Clients///C/R/L /Plus//eip-root`

Scripts (in this repo):
- `vm-windows/Set-AIL-eiConsolePrefs.ps1` — set prefs + launch eiConsole
- `vm-windows/Install-AIL-LogonTask.ps1` — install Windows **At logon** task
- Mac helper: `~/bin/ail_start_vm_eiconsole.sh` — resume VM, seed prefs, run launch now

Windows scheduled task: **`AIL-eiConsole-AtLogon`** (runs as `brianhannan` at logon).  
One-shot / resume launch: task **`AIL-eiConsole-Now`**.  
Log: `C:\Users\brianhannan\AIL-eiconsole-startup.log`

## Spin up from Mac
```bash
~/bin/ail_start_vm_eiconsole.sh
```

## On your iPad
1. Install **Microsoft Remote Desktop**.
2. Add PC:
   - **PC name:** `192.168.68.52:3390`
   - User: your Windows VM account (`brianhannan`)
3. Connect (same Wi‑Fi as the Mac).
4. eiConsole should already be open on **CRL Plus / eip-root** with **Clients → AmericanIncomeLife** routes `1`–`4`.

## Keep-alive
- Mac awake; VM running (`prlctl resume "Windows 11 (1)"` if paused).
- LaunchAgents: `com.pilotfish.ail-rdp-forward`, `com.pilotfish.vm-keepalive`.

## If connect fails
- Confirm iPad and Mac are on the same LAN.
- From Mac: `nc -vz 10.211.55.4 3389` and `lsof -nP -iTCP:3390 -sTCP:LISTEN`
- Sign in once in Parallels if RDP rejects (interactive login / privacy settings).
