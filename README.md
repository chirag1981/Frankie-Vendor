# 📱 Quick Vendor Invoice (Native Android in Kotlin & Jetpack Compose)

A fast, modern, mobile-first Point-of-Sale (POS) & Invoice Billing app designed specifically for shopkeepers and food vendors (e.g. Frankie stall, Fast Food, Kirana, Retail).

Built 100% natively with **Kotlin**, **Jetpack Compose (Material 3)**, and **Room ORM SQLite**, featuring offline-first persistence, native PDF invoice generation, and 1-Click WhatsApp text receipt sharing.

---

## ✨ Features & Architecture

- 🧾 **Quick Billing & Real-Time Calculation**: Add custom items or tap catalog items. Real-time auto-calculation of Subtotal, Discount, and Grand Total.
- 🍔 **Quick Tap Menu / Catalog**: Tap once to add items with saved prices (e.g., *Veg Frankie ₹50*, *Cheese Frankie ₹70*).
- 💬 **1-Click WhatsApp Receipt**: Formats a clean, professional text receipt with emojis and opens WhatsApp directly for the customer's phone number.
- 📄 **Native PDF Invoice Generator**: Creates clean A5 printable receipts with Shop Details, Item Table, and payment summary, saved to `Downloads/VendorInvoices`.
- 📜 **Sales History & Analytics**: Real-time sales summary (Today's Sales, Total Revenue), search past bills by customer/invoice #, view item breakdowns, reshare to WhatsApp, or delete.
- ⚙️ **Shop Profile Configuration**: Configure Shop Name, Phone, Address, Currency Symbol, and custom footer note.
- 🔒 **100% Offline-First & Private**: Powered by Android Room SQLite. No external servers or cloud accounts required.

---

## 📲 How to Build the Android `.apk` via GitHub Actions (Recommended)

1. **Commit & Push to GitHub**:
   ```bash
   git add .
   git commit -m "feat: convert app to native Kotlin & Jetpack Compose"
   git push origin master
   ```

2. **Download Your APK**:
   - Go to your repository on GitHub.
   - Click on the **Actions** tab.
   - Click on the latest **"Build Android APK (Native Kotlin)"** workflow run.
   - Under **Artifacts** at the bottom of the page, download **`Quick-Vendor-Invoice-APK`**.
   - Extract the `.zip` to get `app-debug.apk` and install it on your Android phone!

---

## 💻 Local Development & Build (Android Studio)

### Prerequisites:
- **Android Studio** (Ladybug / Koala / Hedgehog or newer)
- **JDK 17+**

### Open in Android Studio:
1. Open Android Studio -> **Open Project** -> Select this folder (`Frankie-Vendor`).
2. Allow Gradle sync to complete.
3. Select an Android Emulator or connected physical phone and click **Run (Shift + F10)**.

### Build APK via CLI:
```bash
# Windows
gradlew.bat assembleDebug

# macOS / Linux
chmod +x gradlew
./gradlew assembleDebug
```
The output APK will be generated at `app/build/outputs/apk/debug/app-debug.apk`.

---

## 🗄️ Architecture & Project Structure

```
Frankie-Vendor/
├── .github/
│   └── workflows/
│       └── build-apk.yml            # Automated GitHub Actions APK builder
├── gradle/
│   ├── libs.versions.toml          # Pinned version catalog
│   └── wrapper/                    # Gradle wrapper configuration
├── app/
│   ├── build.gradle.kts            # App build dependencies & Compose setup
│   ├── proguard-rules.pro          # Proguard / R8 optimization rules
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml # Permissions & FileProvider
│       │   ├── java/com/vendor/invoice/
│       │   │   ├── QuickVendorApp.kt
│       │   │   ├── data/
│       │   │   │   ├── local/
│       │   │   │   │   ├── AppDatabase.kt
│       │   │   │   │   ├── entity/  # Room Entities (ShopSettings, Catalog, Invoice, Items)
│       │   │   │   │   └── dao/     # Room DAOs (ShopSettingsDao, CatalogItemDao, InvoiceDao)
│       │   │   │   └── repository/  # InvoiceRepository
│       │   │   ├── domain/
│       │   │   │   ├── model/       # Domain Models (DraftInvoiceItem, SalesSummary)
│       │   │   │   └── util/        # WhatsAppFormatter, PdfInvoiceGenerator, CurrencyUtils
│       │   │   └── ui/
│       │   │       ├── theme/       # Color, Theme, Type
│       │   │       ├── main/        # MainActivity, MainScreen (Bottom Navigation)
│       │   │       ├── billing/     # BillingScreen, BillingViewModel
│       │   │       ├── history/     # HistoryScreen, HistoryViewModel
│       │   │       ├── catalog/     # CatalogScreen, CatalogViewModel
│       │   │       └── settings/    # SettingsScreen, SettingsViewModel
│       │   └── res/                 # Vector Drawables, Strings, Colors, Themes
│       └── test/                    # Unit Tests (InvoiceMathTest, WhatsAppFormatterTest)
├── build.gradle.kts                 # Root project build
├── settings.gradle.kts              # Module configuration
└── README.md
```
