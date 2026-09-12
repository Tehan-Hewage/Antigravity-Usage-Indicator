# Antigravity Quota Bridge

The `quota_bridge.ps1` PowerShell script is a secure, decoupled local bridge that ingests raw quota data from external sources (scripts, CLI tools, webhooks, or scheduled jobs) via **STDIN** or parameters, normalizes the payload into the application's strict schema, and performs an **atomic disk write** to:

```
%LOCALAPPDATA%\AntigravityUsageIndicator\quota.json
```

---

## Key Design Principles

1. **Zero Secret Storage**: Never stores, accepts, or transmits Google passwords, session tokens, or authentication cookies.
2. **Defensive Normalization**: Automatically accommodates diverse input representations:
   - Supports `remainingPercent` (e.g. `62`) or `remainingFraction` (e.g. `0.62`).
   - Automatically clamps values to `0..100`.
   - Handles missing optional fields (`plan`, `quotaName`, `resetTime`).
3. **Atomic File Writes**: Writes to a temporary staging file (`quota.tmp.json`) before moving/overwriting `quota.json`. This guarantees that the Flutter file watcher never encounters a half-written or locked file.

---

## Usage Examples

### 1. Pipe JSON from STDIN
```powershell
Get-Content examples/quota_normal.json | powershell -ExecutionPolicy Bypass -File bridge/quota_bridge.ps1
```

### 2. Pass Inline JSON
```powershell
powershell -ExecutionPolicy Bypass -File bridge/quota_bridge.ps1 -InputJson '{"remainingPercent": 75, "model": "Gemini 1.5 Pro", "plan": "Pro"}'
```

### 3. Target a Custom Output Path (for testing)
```powershell
powershell -ExecutionPolicy Bypass -File bridge/quota_bridge.ps1 -InputJson '{"remainingFraction": 0.42}' -OutputPath "test_quota.json"
```

---

## Return Codes
- `0`: Success, file written atomically.
- `1`: Missing input payload.
- `2`: No recognizable percentage or fraction in the JSON payload.
- `3`: Fatal parsing or filesystem error.
