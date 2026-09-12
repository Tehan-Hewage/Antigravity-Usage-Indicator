<#
.SYNOPSIS
    Registers a Windows Scheduled Task to keep Antigravity Usage Indicator updated automatically.

.DESCRIPTION
    Creates a user-level Windows Scheduled Task named "AntigravityUsageSync"
    that runs silently in the background at logon and every 15 minutes.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Uninstall
)

$taskName = "AntigravityUsageSync"

if ($Uninstall) {
    Write-Host "Unregistering scheduled task '$taskName'..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "[OK] Task removed." -ForegroundColor Green
    exit 0
}

$daemonScript = Join-Path $PSScriptRoot "sync_daemon.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$daemonScript`" -RunOnce"
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register repetition every 15 minutes
$trigger.RepetitionInterval = (New-TimeSpan -Minutes 15)
$trigger.RepetitionDuration = [TimeSpan]::Zero # Indefinite

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Automatic background quota updater for Antigravity Usage Indicator" -Force | Out-Null
    Write-Host "[OK] Scheduled task '$taskName' registered successfully!" -ForegroundColor Green
    Write-Host "It will run silently in the background every 15 minutes and at login." -ForegroundColor Cyan
} catch {
    Write-Warning "Could not register scheduled task: $_"
    Write-Host "You can also run the background loop directly via: powershell -File scripts\sync_daemon.ps1" -ForegroundColor Yellow
}
