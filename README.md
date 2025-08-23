# Digital Prescription

Flutter app to create, save, and print A4 medical prescriptions with a WYSIWYG layout, Bengali text support, and cross‑platform builds (Android, Windows, Linux, macOS).

## Highlights

- A4 PDF with background image; on‑screen layout mirrors the PDF output (what you see is what you get)
- Print directly or save PDFs; file name format: `<phone>_<patientName>_<yyyy-MM-dd>.pdf`
- Medicine entry UX:
  - Row 1: Medicine + Duration (compact; label “Days”, hint “days”)
  - Row 2: Dosage + Food instruction
- “Clear all” in AppBar safely resets state without controller disposal crashes
- Bengali support: HindSiliguri embedded; Food field uses rasterized text for accurate complex‑script shaping
- Android: one‑time save folder selection in Settings (drawer) with persistence; scoped‑storage‑aware permissions
- Mouse‑wheel zoom disabled to prevent accidental zooming; normal scroll and panning retained
- SQLite: `sqflite` on mobile, `sqflite_common_ffi` on desktop; no separate SQLite install needed

## Tech Stack

- Flutter (Dart)
- Packages: `pdf`, `printing`, `path_provider`, `permission_handler`, `shared_preferences`, `file_picker`, `flutter_typeahead`, `sqflite`, `sqflite_common_ffi`
- Fonts/Assets: HindSiliguri (embedded), `assets/images/bg.jpg` (background for UI and PDF)

## Key Files

- `lib/main.dart` — App entry; desktop DB init; interaction/zoom behavior
- `lib/services/pdf_service.dart` — A4 PDF generation, printing, saving, Bengali Food rasterization, path & permission handling
- `lib/controllers/prescription_controller.dart` — Page/state orchestration; clear/reset helpers
- `lib/widgets/prescription_page.dart` — On‑screen A4 preview using background image
- `lib/widgets/patient_info_panel.dart` — Patient/medicine form; duration/dosage/food controls; numbering starts at 1
- `lib/widgets/home_drawer.dart` — Settings (choose persistent PDF save folder), About
- `lib/database/database_helper.dart` — Platform‑aware SQLite initialization (mobile/desktop)
- `assets/images/bg.jpg` — Background used in both UI and PDF

## Build & Run

Prerequisites: Flutter SDK. For Windows desktop builds, install Visual Studio “Desktop development with C++”.

```bash
# Android (debug)
flutter run

# Android (release APK)
flutter build apk
# → build/app/outputs/flutter-apk/app-release.apk

# Windows (desktop)
flutter build windows
# → build/windows/runner/Release
```

Notes
- On Android 11+, storage permissions are requested; the app lets the user pick a save folder once (via Settings) and remembers it.
- PDFs default to a `Prescriptions` folder if the chosen directory is unavailable.

## Usage

1) Enter patient info and medicines
2) Tap Print to send to printer or Save to write a PDF
3) PDFs are named `<phone>_<patientName>_<date>.pdf` in the chosen directory

## Credits

Bengali type rendering combines embedded HindSiliguri for most text and rasterization (Flutter TextPainter) for the Food field to ensure accurate complex‑script shaping.

## Installation

For Linux:
```bash
sudo apt-get update && sudo apt-get install -y libsqlite3-dev
```