# ⚡ Antigravity Usage Indicator

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.29-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20x64-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![State](https://img.shields.io/badge/State-Riverpod%202.6-purple?style=for-the-badge)](https://riverpod.dev)
[![Release](https://img.shields.io/badge/Release-v1.0.0-blue?style=for-the-badge&logo=github)](https://github.com/Tehan-Hewage/Antigravity-Usage-Indicator/releases/tag/v1.0.0)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**A sleek, unobtrusive floating Windows desktop notch that displays real-time Google Antigravity & Gemini quota usage with automatic live telemetry extraction.**

*Unofficial community utility for monitoring Google Antigravity IDE & Gemini quota limits.*

<br/>

[⬇️ **Download Latest Portable Release (v1.0.0 for Windows x64)**](https://github.com/Tehan-Hewage/Antigravity-Usage-Indicator/releases/download/v1.0.0/AntigravityUsageIndicator-v1.0.0-windows-x64.zip)

</div>

---

## 📸 Visual Overview

```
MODE 1 — MINIMAL (Pill)         MODE 2 — COMPACT (Default Notch)
┌────────────┐                  ┌──────────────────────────────┐
│  ⚡   94%   │                  │ ⚡  5-Hour              94%  │
│  ███████─  │                  │    ███████████████████──     │
└────────────┘                  └──────────────────────────────┘

MODE 3 — EXPANDED (Live Telemetry & Breakdown)
┌──────────────────────────────────────────────┐
│ ⚡ Antigravity Quota                    ▲  ⚙ │
│ ──────────────────────────────────────────── │
│ 94% remaining · Five Hour Limit              │
│ ██████████████████████████████████████────   │
│                                              │
│ Resets in      4h 22m                        │
│ Reset time     Today 4:24 PM                 │
│ Account Plan   Google AI Pro                 │
│ Last Synced    Just now                      │
│                                              │
│ [Quotas Breakdown]                           │
│ • 5-Hour Limit:   94% [█████████████████──]  │
│ • Weekly Limit:   63% [███████████────────]  │
│ • Claude 3.7:     72% [█████████████──────]  │
│ • Claude 5-Hr:   100% [███████████████████]  │
│                                              │
│ ⚙ Settings                         ⚡ Sync   │
└──────────────────────────────────────────────┘
```

---

## ✨ Key Features

- ⚡ **5-Hour Rolling Limit as Primary**: Shows your most critical short-term session limit by default, with instant 1-click toggling between **5-Hour** and **Weekly** quotas.
- 🔄 **Live Antigravity IDE Extraction**: Zero API keys, zero user logins, zero scraping! Automatically communicates with the local Antigravity IDE Language Server process over secure loopback HTTPS using dynamic session tokens.
- 🎨 **Redesigned Glassmorphic Settings**:
  - **Live Sync & Telemetry**: Connection status badge (`🟢 Antigravity IDE Connected`), relative last-synced ticker, primary metric selector, auto-sync frequency dropdown, live multi-model quota cards, and immediate "Sync Now" button.
  - **Draggable Window & Instant Centering**: Drag the settings window anywhere from its header bar, or click **Center Settings Window** at any time.
  - **Appearance**: Toggle Minimal / Compact / Expanded modes, real-time widget background opacity slider, model title toggle, and percentage counter.
  - **Placement**: Magnetic top-center edge snapping, custom coordinate memory, and quick placement presets.
- 🪟 **Production Native Win32 Hardening**:
  - **Single-Instance Mutex**: Running a duplicate instance automatically brings your active widget to the foreground and gracefully exits.
  - **Zero-Flash Launch**: Initial Win32 creation size matches the compact notch dimensions (`224×68`), eliminating 1280×720 launch pop and white flash.
  - **Isolated Repaint Boundaries**: Zero CPU burn during desktop animations or idle periods.
- 📌 **Always on Top & Hidden from Taskbar**: Floats cleanly above IDEs, terminals, and browsers without stealing taskbar space.
- ⏱️ **Configurable Background Auto-Sync**: Runs silently in the background every 1 to 5 minutes (default: 2 minutes).

---

## 🚀 Quick Start

### 1. Prerequisites
- **OS**: Windows 10 or Windows 11 (x64)
- **Flutter SDK**: 3.24+ (e.g. `A:\flutter\bin` or on system PATH)
- **Build Tools**: Visual Studio 2022 with Desktop development with C++ & CMake

### 2. Clone the Repository
```powershell
git clone https://github.com/Tehan-Hewage/Antigravity-Usage-Indicator.git
cd "Antigravity-Usage-Indicator"
```

### 3. Install Dependencies
```powershell
flutter pub get
```

### 4. Run Development Build
```powershell
flutter run -d windows
```

---

## 🔄 Automatic Live Quota Sync

The application syncs directly from the active Antigravity IDE session using the included daemon:

```powershell
# Run a single live sync test
powershell -ExecutionPolicy Bypass -File .\scripts\sync_daemon.ps1 -RunOnce

# Run continuous background sync (every 2 minutes)
powershell -ExecutionPolicy Bypass -File .\scripts\sync_daemon.ps1 -IntervalMinutes 2

# Register as a permanent Windows Scheduled Task (silent at startup)
powershell -ExecutionPolicy Bypass -File .\scripts\register_scheduled_task.ps1
```

### How Live Extraction Works (Zero Secrets)
1. Discovers the running local Antigravity Language Server process (`language_server_windows_x64.exe`).
2. Parses its active `--csrf_token` and loopback listening port directly from the process command line.
3. Performs a loopback RPC call to:
   ```
   https://127.0.0.1:<port>/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary
   ```
4. Normalizes all model quotas and writes atomically to `%LOCALAPPDATA%\AntigravityUsageIndicator\quota.json`.
5. The Flutter desktop app's native Win32 file watcher immediately refreshes the floating notch.

---

## 📊 Data Schema (`quota.json`)

Stored locally at:
```
%LOCALAPPDATA%\AntigravityUsageIndicator\quota.json
```

```json
{
  "provider": "google-antigravity",
  "model": "5-Hour",
  "quotaName": "Five Hour Limit Remaining",
  "remainingFraction": 0.94,
  "remainingPercent": 94,
  "plan": "Google AI Pro",
  "resetTime": "2026-09-12T11:24:20Z",
  "updatedAt": "2026-09-12T12:00:20+05:30",
  "quotas": [
    {
      "model": "5-Hour",
      "quotaName": "Five Hour Limit Remaining",
      "remainingPercent": 94,
      "resetTime": "2026-09-12T11:24:20Z"
    },
    {
      "model": "Weekly",
      "quotaName": "Weekly Limit Remaining",
      "remainingPercent": 63,
      "resetTime": "2026-09-16T04:27:32Z"
    },
    {
      "model": "Claude 3.7",
      "quotaName": "Weekly Limit Remaining",
      "remainingPercent": 72,
      "resetTime": "2026-09-16T13:59:32Z"
    },
    {
      "model": "Claude 5-Hr",
      "quotaName": "Five Hour Limit Remaining",
      "remainingPercent": 100,
      "resetTime": "2026-09-12T11:27:37Z"
    }
  ]
}
```

---

## 🏗️ Architecture

```
lib/
├── app/
│   ├── app.dart                   # MaterialApp, ThemeMode, and routes
│   └── routes.dart                # AppRoutes definition
├── core/
│   ├── constants/
│   │   └── app_constants.dart     # Widget dimensions, paths, thresholds
│   ├── services/
│   │   ├── logging_service.dart   # File logger (%LOCALAPPDATA%/logs/app.log)
│   │   ├── window_service.dart    # Frameless window manager, centerSettingsWindow, snapping
│   │   ├── startup_service.dart   # Windows registry auto-launch
│   │   └── tray_service.dart      # Native Windows system tray & context menu
│   ├── theme/
│   │   └── app_theme.dart         # Glassmorphism tokens, glow accents, dark palette
│   └── utils/
│       ├── date_time_utils.dart   # Countdown and relative time formatters
│       └── percentage_utils.dart  # Clamping, color thresholds, fraction math
├── features/
│   ├── quota/
│   │   ├── domain/                # QuotaSnapshot, QuotaDataStatus
│   │   ├── data/                  # LocalJsonQuotaProvider, MockQuotaProvider, QuotaRepository
│   │   └── presentation/          # Riverpod notifiers, ProgressBar, Countdown, Live Breakdown
│   ├── settings/
│   │   ├── domain/                # AppSettings (5-Hour primary, intervals, opacity, position)
│   │   ├── data/                  # SettingsRepository (SharedPreferences)
│   │   └── presentation/          # SettingsScreen with 6 glassmorphic categories
│   └── widget/
│       └── presentation/          # FloatingWidgetScreen, MinimalWidget, CompactWidget, ExpandedWidget
└── shared/
    └── widgets/                   # AppCard, AppSwitchTile
```

---

## 🧪 Testing & Code Quality

```powershell
# Run static analysis (0 warnings)
flutter analyze

# Run unit and widget test suite (27 tests)
flutter test
```

---

## 📦 Building Standalone Release

Build the optimized Windows release package using the automated pipeline:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_release.ps1
```

This compiles the release binary and outputs:
- **Standalone Folder**: `dist/AntigravityUsageIndicator-v1.0.0-windows-x64/`
- **Portable ZIP**: `dist/AntigravityUsageIndicator-v1.0.0-windows-x64.zip`

---

## 🔒 Privacy & Security Guarantee

- **100% Local**: No external servers, no telemetry, no cloud analytics.
- **Zero Secrets**: Uses only local loopback HTTPS communication with the active IDE process on your machine.
- **Auditable**: Fully open-source under the MIT license.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
