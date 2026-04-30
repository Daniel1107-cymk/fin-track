# FinTrack

A **personal money tracking app** that works fully offline. Built with Flutter.

Track your income and expenses across multiple wallets, set budgets, manage saving goals, and gain insights with visual analytics — all stored locally on your device with optional biometric/PIN security.

---

## Features

### 💰 Dashboard
- At-a-glance overview of your total balance, recent spending, and budget status
- Highlights budgets that are over or nearly over their limit with visual indicators
- Quick snapshot of recent transactions

### 💳 Multi-Wallet Management
- Create and manage multiple wallets (cash, bank, e-wallet, etc.)
- Each wallet has its own balance, icon, and color
- Transfer funds between wallets with a built-in transfer dialog
- Track balances in different currencies

### 📊 Transactions
- Full transaction history with income/expense categorization
- Add, edit, and delete transactions
- Filter by category, date range, and wallet
- View breakdown: recent transactions and totals per wallet

### 📈 Analytics
- Interactive spending charts powered by **fl_chart**
- Category breakdown with color-coded visuals
- Income vs. expense comparison over time
- Top spending categories this month

### 🎯 Budgets
- Set monthly spending limits per category
- Real-time progress tracking with remaining amounts
- Visual indicators when a budget is at risk or exceeded

### ⭐ Saving Goals
- Define saving targets with goal amounts and deadlines
- Track progress toward each goal
- Add contributions over time

### 🔐 Security
- **Biometric lock** — Secure the app with fingerprint or face ID (device biometrics)
- **PIN lock** — 6-digit PIN with SHA-256 hashing
- **Auto-lock on background** — App locks immediately when sent to background
- Debug mode bypasses the lock for development

### ⚙️ Settings
- Dark theme toggle
- Export transaction data to CSV
- Clear all data with confirmation
- Default wallet selection
- Biometric and PIN toggle with setup flow

---

## Tech Stack

| Category | Choice |
|---|---|
| **Framework** | Flutter (Dart 3) |
| **State Management** | Riverpod (flutter_riverpod 2.x) |
| **Routing** | GoRouter 14.x (with ShellRoute + StatefulShellRoute) |
| **Local Database** | Isar 3.x (offline-first, no backend) |
| **Security** | local_auth, crypto (SHA-256) |
| **Charts** | fl_chart |
| **Fonts** | Google Fonts (DM Sans) |
| **Icons** | Iconsax |
| **Serialization** | Isar generators + build_runner |
| **Local Storage** | SharedPreferences |

---

## Getting Started

### Prerequisites

- **Flutter** 3.29+ ([install guide](https://docs.flutter.dev/get-started/install))
- Dart 3.7+ (bundled with Flutter)

### Clone & Install

```bash
git clone https://github.com/your-username/fin-track.git
cd fin-track
flutter pub get
```

### Generate Isar Models (if needed)

The `.g.dart` model files are pre-generated. If you modify any Isar model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
# Development (hot reload)
flutter run

# Release APK (Android)
flutter build apk --release
```

The app seeds sample data on first launch so you can explore immediately.

---

## Build Notes

### Android

- **Minimum SDK**: Android 7.0 (API 24)
- **Biometric permission**: `USE_BIOMETRIC` declared in `AndroidManifest.xml`
- `MainActivity` extends `FlutterFragmentActivity` (required for `local_auth`)
- Release APK: `flutter build apk --release` (tested, ~25 MB)

### iOS

- `NSFaceIDUsageDescription` configured in `Info.plist`
- Run `flutter build ios` for an archive

---

## Architecture

```
lib/
├── core/
│   ├── database/        — Isar database initialization & seeding
│   ├── providers/       — Riverpod providers (transactions, wallets, budgets, goals, security)
│   ├── router/          — GoRouter configuration with LockGate shell
│   ├── theme/           — Colors, typography, spacing constants
│   └── utils/           — Formatters (currency, date)
├── features/
│   ├── add_transaction/ — Add/edit transaction form
│   ├── analytics/       — Spending charts & breakdown
│   ├── budgets/         — Budget list & progress
│   ├── dashboard/       — Home screen overview
│   ├── goals/           — Saving goals tracking
│   ├── security/        — Lock gate, biometric & PIN screens, lifecycle observer
│   ├── settings/        — App settings & data management
│   ├── transactions/    — Transaction list with filters
│   └── wallets/         — Wallet management & transfer
└── shared/
    ├── models/          — Isar entities (Wallet, Transaction, Category, Budget, SavingGoal)
    └── widgets/         — Reusable UI (GlassCard, AppButton, AmountText, etc.)
```

---

## License

Private project — all rights reserved.
