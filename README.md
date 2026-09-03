# 📱 Quick Vendor Invoice (Flutter & Material 3)

A lightning-fast, modern, mobile Point-of-Sale (POS) & Invoice Billing app designed specifically for shopkeepers and food vendors (e.g. Frankie stall, Fast Food, Kirana, Retail).

Built with **Flutter 3.x**, **Dart 3.x**, **Riverpod**, **Material 3**, and **SQLite (sqflite)**, featuring 100% offline-first persistence, 80mm thermal receipt printing, PDF export, and 1-Click WhatsApp text receipt dispatch.

---

## ✨ Features & Capabilities

- 🧾 **High-Speed POS Billing**: Quick category selector (FRANKIE, BEVERAGE, SNACKS, EXTRA) and instant-tap item grid with dynamic running cart total.
- ➕ **Custom Line Item Override**: Add one-off items with custom names, prices, and quantities on the fly.
- 💬 **1-Click WhatsApp Receipt**: Formats a clean, emoji-styled itemized bill text and opens WhatsApp directly for the customer's phone number.
- 🖨️ **80mm Thermal Receipt & PDF Printing**: Generates standard thermal roll (80mm) slips and connects directly to Bluetooth, WiFi, or system printers via the `printing` package.
- 🍔 **Menu Catalog Management**: Add, edit, toggle active status, and organize food items with categories and prices.
- 📜 **Sales History & Analytics**: Real-time sales summary (Today's Sales, Today's Bills, Total Revenue), search past bills by customer name / invoice # / phone, and filter by date.
- ⚙️ **Shop Profile Configuration**: Configure Shop Name, Phone, Address, UPI ID, Currency Symbol, Tax %, and custom receipt footer note.
- 🔒 **100% Offline-First & Private**: Powered by local SQLite database. No external servers or cloud accounts required.

---

## 🏗 Architecture (Feature-First Clean Architecture)

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp with M3 ThemeData
│   ├── main_nav_screen.dart        # Bottom Navigation Scaffold
│   └── theme/                      # AppColors, AppTheme
├── core/
│   ├── database/                   # DatabaseHelper (SQLite, tables, pre-seeded data)
│   ├── utils/                      # CurrencyUtils, WhatsAppFormatter, PdfInvoiceGenerator
│   └── widgets/                    # Reusable widgets (ReceiptModal)
├── features/
│   ├── billing/                    # POS Billing screen, Cart & Checkout
│   ├── catalog/                    # Food menu items & pricing management
│   ├── history/                    # Sales summary KPIs & past invoices list
│   ├── settings/                   # Shop name, phone, address, UPI ID & tax %
│   └── providers.dart              # Riverpod state providers
├── models/                         # CatalogItem, Invoice, InvoiceItem, ShopSettings, SalesSummary
└── main.dart                       # App entrypoint with ProviderScope
```

---

## 📲 How to Build the Android `.apk` via GitHub Actions (Recommended)

1. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "feat: Flutter POS billing app with Clean Architecture & Riverpod"
   git push origin master
   ```

2. **Download Your APK**:
   - Go to your repository on GitHub.
   - Click on the **Actions** tab.
   - Click on the latest **"Build Flutter APK"** workflow run.
   - Under **Artifacts** at the bottom of the page, download **`Quick-Vendor-Invoice-Flutter-APK`**.
   - Install the APK on your Android phone!

---

## 💻 Local Development & Build

### Prerequisites:
- **Flutter SDK 3.x+**
- **Dart SDK 3.x+**
- **Android Studio** or VS Code with Flutter extension
- **Java 17+ / Android SDK**

### Run Locally:
```bash
flutter pub get
flutter run
```

### Build APK Locally:
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```
The output APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.
