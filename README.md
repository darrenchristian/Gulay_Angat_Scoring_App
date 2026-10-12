<p align="center">
  <img src="assets/gulay_angat_logo.png" alt="GulayAngat Festival 2026 Logo" width="260" />
</p>

<h1 align="center">GulayAngat ScoreSync</h1>
<p align="center">
  <strong>Official Digital Event Scoring & Real-Time Consolidation System for Gulay Angat Events</strong><br/>
  <em>Gunita ng Lahi at Yamang Angat Festival</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Windows-2563EB?style=for-the-badge&logo=flutter" alt="Platform: Android | Windows" />
  <img src="https://img.shields.io/badge/Backend-Firebase%20Auth%20%26%20Cloud%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Backend: Firebase" />
  <img src="https://img.shields.io/badge/Offline%20Ready-Auto--Sync-10B981?style=for-the-badge" alt="Offline Ready: Auto-Sync" />
</p>

---

## Overview

**GulayAngat ScoreSync** is a multi-platform digital judging, scoring, and live score consolidation application built specifically for **Gulay Angat Events** (*Gunita ng Lahi at Yamang Angat Festival*).

Designed with an **Android-first** experience for judges using tablets at live event venues and **Windows desktop** support for event administrators and tabulation committees, the app eliminates manual paper tally sheets, prevents calculation errors, and streams consolidated rankings in real time.

---

## Key Features

### 🏛️ For Event Administrators
- **Event Management**: Create and manage multiple Gulay Angat competitions, pageants, and cultural events with live status control (`Draft`, `Live / Open`, `Completed`).
- **Sortable Criteria Builder**:
  - Define custom scoring criteria with maximum point values and percentage weights (with live `100%` weight validation).
  - **Custom & Preset Sorting**: Reorder criteria via drag-and-drop handles (`⋮⋮`), move up/down arrows (`↑` / `↓`), or one-tap quick-sort presets (*Weight High → Low*, *Weight Low → High*, *Max Points*, *Alphabetical*).
  - Sorted criteria automatically sync in real time to all connected judges' scorecards.
- **Contestant Registration**: Register candidates, groups, or contingents with contestant numbers, representation/barangay/organization details, and bios.
- **Global Judges Pool & Event Linking**:
  - Generate reusable judge accounts (`JDG-XXXX`) outside of individual events so judges never have to log out when switching between different Gulay Angat events on the same tablet.
  - Link or unlink judges per event with a single tap.
  - **Score Integrity Lock**: Once a judge has submitted scores for an event, their link to that event is automatically locked to prevent accidental unlinking during tabulation.
- **Live Consolidated Leaderboard**:
  - Real-time rank computation based on average scores across all linked judges, complete with Gold, Silver, and Bronze podium highlights and per-judge / per-criterion score breakdowns.
- **Password-Protected Score Reset**:
  - Reset an individual judge's scores or reset all scores for an event—protected by an **Admin Password Confirmation** prompt (`reauthenticateWithCredential`) to prevent accidental data loss.

---

### ⚖️ For Event Judges
- **One-Code Instant Access**: Log in using a unique Judge ID (e.g., `JDG-7K9A`)—no email or password required.
- **Seamless Multi-Event Switching**: Switch between any assigned Gulay Angat events from the dashboard without logging out of the device.
- **Interactive Digital Scorecard**:
  - Displays criteria in the exact sequence configured by the Event Administrator.
  - Smooth sliders and `+` / `-` quick-stepper buttons for accurate point allocation, plus optional judge remarks/comments.
- **Venue-Proof Offline Mode & Auto-Sync**:
  - **Non-Blocking Offline Saving**: If venue Wi-Fi drops mid-event, judges can continue scoring without interruption or hanging spinners. Scores are saved immediately to local storage and queued for sync.
  - **Live Sync Status Badges**: Each scored contestant displays either **🟢 Synced** (acknowledged by the cloud server) or **🟠 Pending Sync** (saved offline on the tablet, waiting for Wi-Fi), plus a top status banner showing how many scores are waiting to upload.
  - **Local Session Persistence**: Keeps the judge logged in across app restarts even when completely offline.

---

## Project Structure

```text
scoring_app/
├── assets/
│   └── gulay_angat_logo.png             # Official GulayAngat Festival logo
├── lib/
│   ├── core/
│   │   └── constants/
│   │       ├── app_colors.dart          # Brand color palette
│   │       └── app_theme.dart           # Material 3 light theme configuration
│   ├── models/
│   │   ├── contestant_model.dart        # Contestant / contingent data model
│   │   ├── criterion_model.dart         # Scoring criterion & order model
│   │   ├── event_model.dart             # Event metadata & reset timestamp guards
│   │   ├── judge_model.dart             # Global judge account model
│   │   └── score_submission_model.dart  # Deterministic scorecard & sync metadata
│   ├── providers/
│   │   ├── auth_provider.dart           # Admin & Judge session state management
│   │   └── event_provider.dart          # Real-time leaderboard & score consolidation
│   ├── screens/
│   │   ├── admin/                       # Admin dashboard, criteria, contestants, judges, live results
│   │   ├── auth/                        # Unified Judge ID & Admin login screen
│   │   └── judge/                       # Judge event selector & interactive scorecard
│   ├── services/
│   │   ├── auth_service.dart            # Firebase Auth & Judge code verification
│   │   ├── firestore_service.dart       # Cloud Firestore streams, batch writes & offline sync
│   │   └── local_session_storage.dart   # On-device Judge session persistence
│   ├── firebase_options.dart            # Multi-platform Firebase configuration
│   └── main.dart                        # Application entry point
├── android/                             # Android tablet & phone target configuration
└── windows/                             # Windows desktop target configuration
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.14.0` or compatible stable/beta channel)
- Android Studio / Android SDK (for Android tablet builds)
- Visual Studio 2022 with **Desktop development with C++** (for Windows desktop builds)
- Firebase Project (`scoring-app-8bae2`) with **Firebase Authentication** (Email/Password) and **Cloud Firestore** enabled

### Installation & Running Locally

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on Android Tablet / Device**:
   ```bash
   flutter run -d <android-device-id>
   ```

3. **Run on Windows Desktop**:
   ```bash
   flutter run -d windows
   ```

---

## Building for Production

### Android Release APK
```bash
flutter build apk --release
```
The signed release APK will be generated at:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/flutter-apk/GulayAngat_ScoreSync_Release.apk`

### Windows Release Executable
```bash
flutter build windows --release
```
The release bundle will be generated at:
- `build/windows/x64/runner/Release/scoring_app.exe`

---

## Built For
**Gulay Angat Events** — *Gunita ng Lahi at Yamang Angat Festival*
