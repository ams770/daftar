# Daftar

A professional, local-only product management and invoicing system for mobile devices. Built with Flutter, this application allows small businesses to manage inventory, generate invoices, and print receipts directly to Bluetooth thermal printers.

## 🚀 Key Features

### 📦 Inventory Management
- **Barcode Support**: Scan products using the device camera or enter codes manually.
- **Excel Integration**: 
  - **Import**: Bulk import products from Excel (`.xlsx`) with real-time validation and duplicate detection.
  - **Export**: Export your entire inventory to Excel for bacشkup or reporting.
- **Product Tracking**: Manage names, codes, and prices with an easy-to-use interface.

### 🧾 Invoicing & Sales
- **Dynamic Invoices**: Create professional invoices with automatic VAT calculations.
- **Payment Methods**: Support for Cash, Credit, and Bank Transfer payments.
- **PDF Generation**: Generate high-quality PDF invoices that can be shared or saved.
- **Barcode Checkout**: Quickly add items to an invoice by scanning barcodes.

### 🖨️ Thermal Printing
- **Bluetooth Connectivity**: Seamlessly connect to mobile Bluetooth thermal printers.
- **Flexible Formatting**: Support for both **3-inch (80mm)** and **4-inch (110mm)** paper widths.
- **Logo Printing**: Print your brand logo directly on receipts.

### 🌍 Localization & UX
- **Full RTL Support**: Completely localized in **English** and **Arabic**.
- **Modern Aesthetics**: A premium "Daftar-style" UI with smooth animations and responsive design.
- **Quick Onboarding**: Friendly setup flow for brand identity, taxation, and language preferences.

---

## 🏗️ Architecture

This project follows **Clean Architecture** principles to ensure maintainability, scalability, and testability.

### Layers:
1.  **Presentation**: UI components (Widgets), Pages, and State Management using **BLoC (Cubit)**.
2.  **Domain**: Core business logic, Entities, and UseCases. This layer is independent of any other layer.
3.  **Data**: Repositories implementation, Data Sources (SQLite, File System), and Data Models.
4.  **Core**: Cross-cutting concerns like Dependency Injection, Theme, Constants, and Database Helpers.

### Tech Stack:
- **Framework**: Flutter
- **State Management**: flutter_bloc (Cubit)
- **Local Database**: sqflite (SQLite)
- **Dependency Injection**: get_it
- **Localization**: easy_localization
- **PDF Generation**: pdf
- **Excel Processing**: excel
- **Icons**: lucide_icons

---

## 📁 Project Structure

```text
lib/
├── core/                # Shared utilities, theme, and DI
├── features/
│   ├── onboarding/      # Initial setup flow
│   ├── products/        # Inventory and Excel management
│   ├── invoices/        # Sales and PDF generation
│   ├── printer/         # Bluetooth thermal printing logic
│   └── settings/        # Brand and App configurations
├── main.dart            # Entry point
```

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode
- A physical Android/iOS device (for Bluetooth printing)

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter run` on your connected device.

---

## 📝 License
This project is for internal use and demonstrations.
