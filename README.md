# 📱 Quick Vendor Invoice (Android APK in Python)

A fast, mobile-first Invoice & Billing app designed specifically for shopkeepers and food vendors (e.g. Frankie stall, Fast Food, Kirana, Retail).

Built with **Python & Flet (Flutter Material 3 UI Engine)**, fully offline-capable with SQLite, PDF invoice generation, and 1-Click WhatsApp bill sharing.

---

## ✨ Features

- 🧾 **Quick Billing & Dynamic Line Items**: Add custom items or tap pre-saved catalog items. Real-time auto-calculation of Subtotal, Discount, Tax, and Grand Total.
- 🍔 **Quick Tap Menu / Catalog**: Tap once to add items with saved prices (e.g., *Veg Frankie ₹50*, *Cheese Frankie ₹70*).
- 💬 **1-Click WhatsApp Bill**: Formats a clean text receipt and opens WhatsApp directly for the customer's phone number.
- 📄 **Professional PDF Generator**: Creates clean A5/A4 printable receipts with Shop Details, Item Table, and UPI Payment ID.
- 📜 **Sales History & Stats**: Track daily sales, view past bills, reprint receipts, or reshare to WhatsApp anytime.
- ⚙️ **Shop Profile**: Set Shop Name, Contact Phone, Address, UPI ID, and custom footer note.
- 📦 **Android APK Ready**: Zero-configuration cloud APK build via GitHub Actions or local CLI.

---

## 🚀 How to Run Locally (Desktop Simulation)

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the App**:
   - **Native Phone Simulation**:
     ```bash
     python main.py
     ```
   - **Web Browser Mode**:
     ```bash
     python main.py --web
     ```

---

## 📲 How to Build the Android `.apk` File

You have **two easy ways** to build the `.apk`:

### 🌟 Method 1: Free Automated GitHub Actions (No SDK Needed - Recommended)
1. Push this project to your GitHub repository:
   ```bash
   git init
   git add .
   git commit -m "feat: initial shop invoice app"
   git remote add origin https://github.com/your-username/your-repo.git
   git push -u origin main
   ```
2. Go to the **Actions** tab on your GitHub repository.
3. The **"Build Android APK"** workflow runs automatically on Ubuntu Cloud runners.
4. When finished (approx. 4-5 minutes), click on the workflow run and download the **`Quick-Vendor-Invoice-APK`** artifact zip containing your `.apk`!
5. Transfer the `.apk` to your Android phone and install.

---

### 💻 Method 2: Local Build via Flet CLI
If you have Flutter / Android SDK installed locally:
```bash
flet build apk --project "QuickVendorInvoice" --product "Quick Vendor Invoice" --org "com.vendor.invoice"
```
The output `.apk` file will be generated in `build/apk/`.

---

## 🗄️ Architecture & File Structure

```
Frankie-Vendor/
├── .github/
│   └── workflows/
│       └── build-apk.yml       # Cloud APK builder workflow
├── app/
│   ├── database.py             # SQLite persistence (Shop, Invoices, Catalog)
│   ├── pdf_service.py          # PDF invoice generator (fpdf2)
│   ├── utils.py                # WhatsApp bill formatter & URL builder
│   └── views/
│       ├── billing_view.py     # Main POS billing interface
│       ├── history_view.py     # Past invoices and analytics
│       ├── catalog_view.py     # Menu items management
│       └── settings_view.py    # Shop profile & UPI settings
├── main.py                     # Main application entry point
├── requirements.txt            # Python dependencies (flet, fpdf2)
└── README.md                   # Documentation
```
