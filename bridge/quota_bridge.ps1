<#
.SYNOPSIS
    Antigravity Quota Bridge for Windows.
    Reads quota JSON from STDIN or parameter, normalizes schema, and writes atomically.

.DESCRIPTION
    Receives quota payload, normalizes fields defensively into the schema expected by
    the Antigravity Usage Indicator Flutter app, and writes atomically to quota.json.
    DO NOT pass credentials, cookies, or secrets to this script.

.PARAMETER InputJson
    Optional JSON string. If omitted, the script reads all text from STDIN.

.PARAMETER OutputPath
    Target destination for quota.json. Defaults to:
    $env:LOCALAPPDATA\AntigravityUsageIndicator\quota.json

.EXAMPLE
    cat examples/quota_normal.json | powershell -File bridge/quota_bridge.ps1
    echo '{"remainingFraction": 0.75, "model": "Gemini 1.5 Pro"}' | powershell -File bridge/quota_bridge.ps1
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputJson,

    [Parameter()]
    [string]$OutputPath = "$env:LOCALAPPDATA\AntigravityUsageIndicator\quota.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    # 1. Read input from pipeline / parameter / stdin
    $rawInput = ""
    if (-not [string]::IsNullOrWhiteSpace($InputJson)) {
        $rawInput = $InputJson
    }
    elseif ($PSBoundParameters.ContainsKey('InputObject')) {
        $rawInput = $PSBoundParameters['InputObject']
    }
    else {
        $rawInput = [Console]::In.ReadToEnd()
    }

    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        Write-Error "No JSON payload received via STDIN or -InputJson parameter."
        exit 1
    }

    # 2. Parse JSON safely
    $data = $rawInput | ConvertFrom-Json

    # 3. Defensive extraction of percentage / fraction
    $remainingPercent = $null

    if ($null -ne $data.remainingPercent) {
        $remainingPercent = [Math]::Round([double]$data.remainingPercent)
    }
    elseif ($null -ne $data.remainingFraction) {
        $remainingPercent = [Math]::Round([double]$data.remainingFraction * 100)
    }
    elseif ($null -ne $data.percentRemaining) {
        $remainingPercent = [Math]::Round([double]$data.percentRemaining)
    }
    elseif ($null -ne $data.fractionRemaining) {
        $remainingPercent = [Math]::Round([double]$data.fractionRemaining * 100)
    }
    elseif ($null -ne $data.quota -and $null -ne $data.quota.remainingPercent) {
        $remainingPercent = [Math]::Round([double]$data.quota.remainingPercent)
    }
    else {
        # Check if wrapped in quotas array
        if ($null -ne $data.quotas -and $data.quotas.Count -gt 0) {
            $first = $data.quotas[0]
            if ($null -ne $first.remainingPercent) {
                $remainingPercent = [Math]::Round([double]$first.remainingPercent)
            } elseif ($null -ne $first.remainingFraction) {
                $remainingPercent = [Math]::Round([double]$first.remainingFraction * 100)
            }
        }
    }

    if ($null -eq $remainingPercent) {
        Write-Error "Could not find a valid remainingPercent or remainingFraction in input."
        exit 2
    }

    # Clamp to [0, 100]
    $remainingPercent = [Math]::Max(0, [Math]::Min(100, [int]$remainingPercent))
    $remainingFraction = [Math]::Round($remainingPercent / 100.0, 4)

    # 4. Extract metadata fields defensively
    $model = if ($null -ne $data.model) { [string]$data.model } else { "Gemini" }
    $provider = if ($null -ne $data.provider) { [string]$data.provider } else { "google-antigravity" }
    $quotaName = if ($null -ne $data.quotaName) { [string]$data.quotaName } else { "gemini-quota" }
    $plan = if ($null -ne $data.plan) { [string]$data.plan } else { "Standard" }

    # Reset time
    $resetTime = $null
    if ($null -ne $data.resetTime) {
        $resetTime = [string]$data.resetTime
    }

    # Updated at timestamp (ISO 8601) - always stamp current sync time
    $updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

    # Extract sub-quotas array if present
    $normalizedQuotas = @()
    if ($null -ne $data.quotas -and $data.quotas.Count -gt 0) {
        foreach ($q in $data.quotas) {
            $qPercent = $null
            if ($null -ne $q.remainingPercent) { $qPercent = [Math]::Round([double]$q.remainingPercent) }
            elseif ($null -ne $q.remainingFraction) { $qPercent = [Math]::Round([double]$q.remainingFraction * 100) }
            elseif ($null -ne $q.percentRemaining) { $qPercent = [Math]::Round([double]$q.percentRemaining) }
            elseif ($null -ne $q.fractionRemaining) { $qPercent = [Math]::Round([double]$q.fractionRemaining * 100) }

            if ($null -ne $qPercent) {
                $qPercent = [Math]::Max(0, [Math]::Min(100, [int]$qPercent))
                $qFraction = [Math]::Round($qPercent / 100.0, 4)
                $qModel = if ($null -ne $q.model) { [string]$q.model } else { $model }
                $qQuotaName = if ($null -ne $q.quotaName) { [string]$q.quotaName } else { "Quota" }
                $qReset = if ($null -ne $q.resetTime) { [string]$q.resetTime } else { $null }

                $normalizedQuotas += [ordered]@{
                    provider          = $provider
                    model             = $qModel
                    quotaName         = $qQuotaName
                    remainingFraction = $qFraction
                    remainingPercent  = $qPercent
                    plan              = $plan
                    resetTime         = $qReset
                    updatedAt         = $updatedAt
                }
            }
        }
    }

    # 5. Build normalized payload
    $normalized = [ordered]@{
        provider          = $provider
        model             = $model
        quotaName         = $quotaName
        remainingFraction = $remainingFraction
        remainingPercent  = $remainingPercent
        plan              = $plan
        resetTime         = $resetTime
        updatedAt         = $updatedAt
    }

    if ($normalizedQuotas.Count -gt 0) {
        $normalized["quotas"] = $normalizedQuotas
    }

    # 6. Ensure destination directory exists
    $targetDir = [System.IO.Path]::GetDirectoryName($OutputPath)
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # 7. Atomic write: Write to temporary file first, then replace target file
    $tmpPath = [System.IO.Path]::Combine($targetDir, "quota.tmp.json")
    $jsonOutput = $normalized | ConvertTo-Json -Depth 10

    [System.IO.File]::WriteAllText($tmpPath, $jsonOutput, [System.Text.Encoding]::UTF8)

    # Atomic move / overwrite using .NET File.Move with overwrite flag
    if ([System.IO.File]::Exists($OutputPath)) {
        [System.IO.File]::Copy($tmpPath, $OutputPath, $true)
        [System.IO.File]::Delete($tmpPath)
    } else {
        [System.IO.File]::Move($tmpPath, $OutputPath)
    }

    Write-Host "[OK] Quota updated successfully: $remainingPercent% ($model) -> $OutputPath"
    exit 0
}
catch {
    Write-Error "Bridge execution failed: $_"
    exit 3
}
