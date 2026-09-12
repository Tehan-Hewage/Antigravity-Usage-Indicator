<#
.SYNOPSIS
    Antigravity Live Usage Sync Daemon (Background Poller & Live Extractor).
    Automatically syncs live Antigravity IDE quota to %LOCALAPPDATA%\AntigravityUsageIndicator\quota.json.

.DESCRIPTION
    Interacts securely with the local Antigravity IDE Language Server process over loopback HTTPS
    to extract real-time model usage fractions, remaining percentages, and reset timestamps with
    zero external credential storage.

.PARAMETER IntervalMinutes
    Interval between background updates in minutes. Default: 3 minutes.

.PARAMETER RunOnce
    If set, runs a single live sync iteration and exits immediately.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [int]$IntervalMinutes = 2,

    [Parameter()]
    [switch]$RunOnce
)

$ErrorActionPreference = "SilentlyContinue"

# Resolve bridge script path
$bridgeCandidates = @(
    (Join-Path $PSScriptRoot "..\bridge\quota_bridge.ps1"),
    (Join-Path $PSScriptRoot "bridge\quota_bridge.ps1"),
    (Join-Path $PSScriptRoot "quota_bridge.ps1")
)

$bridgeScript = $null
foreach ($c in $bridgeCandidates) {
    if (Test-Path $c) {
        $bridgeScript = (Resolve-Path $c).Path
        break
    }
}

if (-not $bridgeScript) {
    Write-Warning "Could not find quota_bridge.ps1. Sync daemon cannot update target file."
    exit 1
}

function Get-LiveAntigravityQuota {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    # 1. Locate running Antigravity Language Server processes
    $lsProcs = Get-CimInstance Win32_Process | Where-Object { $_.Name -like "*language_server*" }
    if (-not $lsProcs) {
        return $null
    }

    foreach ($proc in $lsProcs) {
        # 2. Extract CSRF token from command line
        if ($proc.CommandLine -match '--csrf_token\s+([a-f0-9\-]+)') {
            $csrfToken = $Matches[1]
        } else {
            continue
        }

        # 3. Retrieve listening ports for this process
        $ports = @()
        try {
            $ports = Get-NetTCPConnection -OwningProcess $proc.ProcessId -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalPort
        } catch {
            # Fallback to netstat if Get-NetTCPConnection is unavailable
            $netstatOut = netstat -ano | Select-String "LISTENING\s+$($proc.ProcessId)"
            foreach ($line in $netstatOut) {
                if ($line -match '127\.0\.0\.1:(\d+)') {
                    $ports += [int]$Matches[1]
                }
            }
        }

        # 4. Probe ports for RetrieveUserQuotaSummary endpoint
        foreach ($port in $ports) {
            try {
                $headers = @{
                    'x-codeium-csrf-token' = $csrfToken
                    'Content-Type' = 'application/json'
                }
                $uri = "https://127.0.0.1:$port/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary"
                $res = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body '{}' -TimeoutSec 2
                
                if ($res -and $res.response -and $res.response.groups) {
                    return $res.response
                }
            } catch {
                # Try next port
            }
        }
    }

    return $null
}

function Sync-QuotaNow {
    try {
        $quotaSummary = Get-LiveAntigravityQuota

        if ($quotaSummary -and $quotaSummary.groups) {
            $subQuotas = @()
            foreach ($group in $quotaSummary.groups) {
                $isClaude = $group.displayName -like '*Claude*'
                foreach ($bucket in $group.buckets) {
                    $pct = [math]::Round([math]::Max(0, [math]::Min(100, $bucket.remainingFraction * 100)))
                    $is5h = ($bucket.displayName -like '*5-Hour*') -or ($bucket.displayName -like '*Five Hour*')
                    
                    $modelLabel = if ($isClaude) {
                        if ($is5h) { 'Claude 5-Hr' } else { 'Claude 3.7' }
                    } else {
                        if ($is5h) { '5-Hour' } else { 'Weekly' }
                    }

                    $subQuotas += [PSCustomObject]@{
                        model = $modelLabel
                        quotaName = $bucket.displayName
                        remainingPercent = $pct
                        remainingFraction = [math]::Round($bucket.remainingFraction, 4)
                        resetTime = $bucket.resetTime
                    }
                }
            }

            # Pick default display quota: 5-Hour limit preferred over Weekly limit
            $primary = $subQuotas | Where-Object { $_.model -eq '5-Hour' } | Select-Object -First 1
            if (-not $primary) {
                $primary = $subQuotas | Where-Object { $_.model -eq 'Weekly' } | Select-Object -First 1
            }
            if (-not $primary -and $subQuotas.Count -gt 0) {
                $primary = $subQuotas[0]
            }

            # Put primary quota first so index 0 is always the primary display metric
            $orderedQuotas = @($primary) + @($subQuotas | Where-Object { $_.model -ne $primary.model })

            if ($primary) {
                $nowIso = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
                $payload = [PSCustomObject]@{
                    provider = 'google-antigravity'
                    plan = 'Google AI Pro'
                    model = $primary.model
                    quotaName = $primary.quotaName
                    remainingPercent = $primary.remainingPercent
                    remainingFraction = $primary.remainingFraction
                    resetTime = $primary.resetTime
                    updatedAt = $nowIso
                    quotas = $orderedQuotas
                }

                $json = $payload | ConvertTo-Json -Depth 5
                $json | powershell -ExecutionPolicy Bypass -File $bridgeScript | Out-Null

                $nowStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                Write-Host "[$nowStr] Live quota synced: $($primary.model) -> $($primary.remainingPercent)%" -ForegroundColor Green
                return $true
            }
        } else {
            Write-Host "Antigravity IDE Language Server not responding or closed. Retaining current file." -ForegroundColor DarkGray
        }
    } catch {
        Write-Warning "Live sync iteration failed: $_"
    }
    return $false
}

# Initial sync
Sync-QuotaNow | Out-Null

if ($RunOnce) {
    exit 0
}

Write-Host "Antigravity Usage Sync Daemon running (Interval: $IntervalMinutes mins)..." -ForegroundColor Cyan

while ($true) {
    Start-Sleep -Seconds ($IntervalMinutes * 60)
    Sync-QuotaNow | Out-Null
}
