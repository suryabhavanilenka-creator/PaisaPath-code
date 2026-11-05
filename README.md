# PaisaPath - Expenses Tracker

<div align="center">
  <img src="assets/icon/app_icon.png" width="120" alt="PaisaPath launcher icon" />
  <p><b>An offline-first expense tracker for Android, built with Flutter.</b></p>
  <p><a href="https://paisapath-six.vercel.app"><b>🌐 Try the live web version</b></a></p>
</div>

PaisaPath is a personal expense manager that lets you record income and expense
transactions, browse them with search and filters, see calendar-month summaries,
analyse spending trends in a chart, and export everything to CSV. All data is
stored **locally on the device** with SQLite — no accounts, no network, no
cloud services.

Built as part of the **IITM Pravartak & BodhBridge Flutter Development
Programme** (approved topic: Expense Tracker).

---

## 1. Features

| Area | Details |
| --- | --- |
| Add / edit transactions | Amount (₹, decimal, max-length guarded), category chips, payment-method dropdown, date picker, optional description |
| Validation | Required amount, numeric-only input formatters, `> 0` amount bound, max amount cap, description length cap, selection checks with clear per-field error messages |
| Dashboard | Greeting header, "This Month's Spending" hero card, Today / Net Balance chips, Income & Expenses totals, last-seven-days spending chart, searchable + category-filterable + month-filterable transaction list |
| Four UI states | Loading, Error (with Retry), Empty (with CTA) and Data — implemented on the dashboard list |
| Statistics | Month-by-month bar chart (last 3 months), category breakdown with highest-category highlight, average daily spend, totals for the filtered scope |
| Settings | Light / Dark / System theme selection (persisted), "Clear all data" with confirmation, CSV export, About section |
| Persistence | SQLite via `sqflite`; survives app restarts |
| Export | CSV export of all transactions to app documents (shareable via the system share flow) |
| Theming | Material 3, generated from the single seed colour `#2563EB`. **No screen-level hardcoded colours** — every widget uses `Theme.of(context)` / `ColorScheme` |
| Formatting | `en_IN` Indian digit grouping for rupees (e.g. `₹1,23,456.50`), `DD MMM YYYY` dates |
| Charts | Custom `CustomPainter` bar chart (no third-party chart library) — consistent with Material colour scheme |

## 2. Technology stack

| Layer | Choice |
| --- | --- |
| Framework | Flutter (stable ≥ 3.35), Dart 3, null safety |
| State management | `provider` (6.x) — `ChangeNotifier` + `MultiProvider`, screens never call the DB directly |
| Local database | `sqflite` (single-table `expenses` with indexed `date` column) |
| Theming | Material 3 (`ColorScheme.fromSeed(seedColor: Color(0xFF2563EB))`) |
| Dates & numbers | `intl` (`en_IN` currency, `DateFormat`) |
| Persistence of theme | `shared_preferences` |
| Launcher icons | `flutter_launcher_icons` (1024×1024 master + adaptive icon, brand `#2563EB`) |
| Tests | `flutter_test`, provider unit tests + widget tests with a deterministic in-memory store fake |

## 3. Architecture

```
lib/
├── main.dart                     # App bootstrap: DB open, theme load, MultiProvider, routes
├── models/
│   └── expense.dart              # Expense model, TransactionType, map round-trip + safe parsing
├── services/
│   ├── database_service.dart     # sqflite implementation of the TransactionStore interface
│   └── storage_service.dart      # CSV export helper
├── providers/
│   ├── expense_provider.dart     # Central ChangeNotifier: load/CRUD/search/filter/sort + derived summaries
│   └── theme_provider.dart       # ThemeMode state (persisted)
├── utils/
│   ├── app_theme.dart            # Light + dark themes from the single seed colour
│   ├── app_constants.dart        # Categories, icons, payment methods, limits
│   ├── currency_formatter.dart   # ₹ en_IN formatting + input parsing
│   └── date_formatter.dart       # DD MMM YYYY formatting, month keys, greeting
├── navigation/
│   └── app_navigation.dart       # Route names, onGenerateRoute, bottom-nav shell + FAB
├── screens/
│   ├── dashboard_screen.dart     # Screen 1 — dashboard (all four list states)
│   ├── add_expense_screen.dart   # Screen 3 — add / edit form with validation
│   ├── expense_detail_screen.dart# Screen 4 — full record detail with edit/delete
│   ├── statistics_screen.dart    # Custom chart + analytics
│   └── settings_screen.dart      # Theme, export, clear data, about
└── widgets/
    ├── expense_card.dart         # Transaction row
    ├── summary_card.dart         # Income / expense stat tiles
    ├── spending_chart.dart       # CustomPainter bar chart
    ├── month_filter_sheet.dart   # Month filter bottom sheet
    ├── category_icon.dart        # Category → icon + tinted circle
    ├── empty_state.dart          # Friendly empty illustration + CTA
    ├── error_widget.dart         # Recoverable error + Retry
    └── loading_widget.dart       # Loading spinner wrapper
test/                             # Model, provider and widget tests (+ test_support fake)
```

**Key design decision:** persistence is abstracted behind a small
`TransactionStore` interface (`lib/services/database_service.dart`). The
production app binds `sqflite`; the test-suite binds an in-memory fake
(`test/test_support/in_memory_store.dart`). This keeps widget- and
provider-level tests hermetic — they never touch real device storage and can
simulate storage failures deterministically.

## 4. Screenshots

Screenshots of the running app will be added here.

<!-- Screenshots pending: dashboard, insights, profile, add/edit form. -->

## 5. Data source

PaisaPath uses **no external data source**. Every transaction is entered by
the user through the in-app form and stored **locally**:

* **Android:** a private SQLite database file (`expenses` table, indexed by
  date) in the app's documents directory — created and managed via `sqflite`.
* **Web:** the same SQLite schema running in the browser via SQLite-WASM
  (`sqflite_common_ffi_web`), persisted in browser storage (OPFS/IndexedDB).

There are no network calls, no accounts, no analytics and no third-party
services; category names, icons and payment-method options are static
constants defined in `lib/utils/app_constants.dart`.

## 6. Getting started

### Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Flutter SDK | stable ≥ 3.35 (developed on 3.47.x) | `flutter doctor` must be clean for Android |
| JDK | 17 | `JAVA_HOME` must point to JDK 17 |
| Android SDK | API 34/36 + build-tools | Platform + build-tools installed, licences accepted |

### Run it

```bash
flutter pub get
flutter run
```

The app stores its database in the app-private documents directory of the
target device/emulator — nothing else is required.

### Tests

```bash
flutter analyze   # static analysis — currently 0 issues
flutter test      # 33 tests: model, provider and widget-level suites
```

What the suites cover:

* `test/expense_model_test.dart` — map round-trip, safe parsing of malformed data, signed amounts, ₹ formatting.
* `test/expense_provider_test.dart` — load/error/retry, idempotent `ensureLoaded`, CRUD, clearing, month/today summaries, category breakdown, search/filters/sort, listener discipline.
* `test/add_expense_screen_test.dart` — form rendering, all validation branches, a full save flow, and the edit flow.
* `test/dashboard_screen_test.dart` — dashboards rendering summary + cards from real data, empty state, error state with working Retry, and live search filtering.

### Build a release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

> Windows/OneDrive note: if the project folder lives inside OneDrive, the
> sync engine can lock files inside `build/` and fail the Gradle build.
> Pause OneDrive (or temporarily kill `OneDrive.exe`) during the build.
> Kotlin incremental compilation is already disabled (cross-drive cache
> limitation) via `android/gradle.properties`.

**Install on an Android phone:**

1. Copy `app-release.apk` to the phone.
2. Tap the file and allow *"Install from this source"* when prompted, or:
   ```bash
   adb install -r app-release.apk
   ```
3. Launch **PaisaPath** from the launcher.

## 7. Website (web) version

PaisaPath is also available as a **fully functional website** — the same
codebase compiled with `flutter build web`. On web, SQLite runs in the
browser via WASM (`sqflite_common_ffi_web`) and is persisted in browser
storage (OPFS/IndexedDB), so **records survive page reloads and browser
restarts** — the same database semantics as on Android.

**Run locally:**

```bash
flutter build web --release
python serve_web.py            # serves http://127.0.0.1:8421
```

`serve_web.py` adds the `Cross-Origin-Opener-Policy` /
`Cross-Origin-Embedder-Policy` headers the browser storage APIs require.
(Plain `python -m http.server` may disable persistence in some browsers.)

**Deploy anywhere static files are served** — GitHub Pages, Firebase
Hosting, Netlify, any web server — by uploading the `build/web` folder
(keep the two security headers in place).

**Automated deployment (recommended):** pushing to `main` triggers
`.github/workflows/deploy-web.yml`, which runs `flutter analyze`, the
test suite and `flutter build web --release`, applies the Vercel header
configuration, and deploys `build/web` to Vercel. Configure these three
repository secrets first (GitHub → Settings → Secrets and variables):

| Secret | Where to get it |
| --- | --- |
| `VERCEL_TOKEN` | Vercel → Account Settings → Tokens |
| `VERCEL_ORG_ID` + `VERCEL_PROJECT_ID` | run `vercel link` locally, then read `.vercel/project.json` (that folder is git-ignored) |

| Platform | Storage backend | Persistence |
| --- | --- | --- |
| Android APK | `sqflite` (real SQLite) | ✅ Permanent, device-local |
| Web | SQLite-WASM in browser (OPFS/IndexedDB) | ✅ Survives reloads, per-browser profile |

## 8. Data & privacy

* Database: local SQLite file in the app's private storage (table `expenses`) on Android; browser-managed storage on web.
* CSV export: written to the app documents directory and handed to the
  Android share sheet (or a browser download on web) — no data leaves the
  device except through the user's explicit share action.
* No third-party analytics, no accounts. The Android app performs one
  optional update check against this project's own website
  (`app-version.json`); it sends no personal data and fails silently offline.

## 9. Known limitations

* Physical-device verification (install + smoke test) is pending; all checks so
  far are build-level and emulator-level (`flutter analyze`, `flutter test`).
* CSV export targets the device share sheet (Android); importing CSV back is not supported.
* Statistics charts cover 3 months (window configurable in code).
* Web database is per-browser/per-device profile (like any website's local
  storage); it does not sync between devices — same offline-first privacy model.

## 10. Team

| Member | Role | Parts built |
| --- | --- | --- |
| **L. Surya Bhavani** | Team lead & core engineering | App architecture, state management (`Provider`), SQLite database layer (`sqflite` + SQLite-WASM for web), automated tests (33), release APK build, GitHub & Vercel deployment, defect log |
| **K. Lakshmi Prasanna** | Dashboard & analytics UI | Dashboard screen (summary cards, spending chart, search/filters, four UI states), statistics screen (monthly bar chart, category breakdown, daily spending), Material 3 light/dark theming |
| **M. Divya** | Forms, details & data tools | Add/Edit expense form with full validation, expense detail screen (edit/delete), CSV export (Android file + web download), settings screen (theme selection, clear data, about) |

*All three members contributed to testing and the live demonstration.*
K. Lakshmi Prasanna: tested the CSV export flow on web and Android and reported the export defect.
M. Divya: tested the CSV export flow on web and Android and reported the export defect.
M. Divya: also verified the export file opens correctly on Android.

## 11. Defects & incident log

See [DEFECT_LOG.md](DEFECT_LOG.md) for every real defect found during
development, its impact and its resolution status.
