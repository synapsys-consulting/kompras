# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kompras is a Flutter e-commerce/purchasing management app. Package name: `kompras`. SDK constraint: `>=3.3.0 <4.0.0`.

## Common Commands

```bash
flutter run                        # Run the app (device/emulator must be connected)
flutter build apk                  # Build Android APK
flutter build ios                  # Build iOS app
flutter analyze                    # Run static analysis (uses flutter_lints)
flutter test                       # Run tests
flutter test test/widget_test.dart # Run a single test file
flutter pub get                    # Install dependencies
```

## Architecture

**MVC + Provider pattern** with `ChangeNotifier` for state management.

```
lib/
├── controller/   # Business logic, API calls (PurchaseController, PurchaseDetailController, etc.)
├── model/        # Data classes with fromJson() factories; stateful models (Cart, Catalog) extend ChangeNotifier
├── service/      # API service classes (NewProductService)
├── util/         # Shared utilities: colors, config, responsive helpers, dialogs, snackbars
├── view/         # UI widgets (24 views: Cart, Login, SignUp, Purchase, Address, etc.)
└── main.dart     # Entry point, MultiProvider setup, theme config, SSL overrides
```

**State providers** (set up via `MultiProvider` in `main.dart`):
- `Cart` — shopping cart items, totals, tax calculations
- `Catalog` — product catalog with parent-child hierarchical relationships
- `DefaultAddressList` / `AddressesList` — delivery address management

**Backend**: REST API on AWS EC2. Server URL and constants configured in `lib/util/configuration.util.dart`. JWT tokens stored in `SharedPreferences` under key `'token'`.

**Navigation**: imperative `Navigator.push()`/`Navigator.pop()` — no named routes or router package.

**Responsive design**: custom `ResponsiveWidget` utility (`lib/util/ResponsiveWidget.util.dart`).

## Key Conventions

- File naming: `PascalCase.layer.dart` (e.g., `Cart.view.dart`, `Cart.model.dart`, `PurchaseDetailController.controller.dart`)
- Models use factory `fromJson()` constructors for JSON deserialization
- Views access state via `Consumer<T>` and `Provider.of<T>(context)`
- API calls use both `http` and `dio` packages
- Theme colors defined in `lib/util/color.util.dart` (amber/orange palette prefixed `tanteLaden*`)
- Assets in `assets/images/`

## Platform Config

- **Android**: compileSdk 36, targetSdk 36, JVM 17, namespace `com.example.kompras`
- **iOS**: deployment target iOS 13.0, bundle ID `com.example.kompras`
- `MyHttpOverrides` in `main.dart` handles custom SSL certificate validation for the backend server
