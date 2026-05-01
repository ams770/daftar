'''text
Products Printer
This project implements a local-only product management system with barcode scanning capabilities, following Clean Architecture principles and using Cubit for state management.

lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart
│   └── di/
│       └── injection.dart
├── features/
│   └── products/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── product_local_datasource.dart
│       │   ├── models/
│       │   │   └── product_model.dart
│       │   └── repositories/
│       │       └── product_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── product.dart
│       │   ├── repositories/
│       │   │   └── product_repository.dart
│       │   └── usecases/
│       │       ├── add_product.dart
│       │       ├── get_product_by_code.dart
│       │       ├── get_products_paginated.dart
│       │       └── update_product.dart
│       └── presentation/
│           ├── cubits/
│           │   ├── products_cubit.dart
│           │   └── products_state.dart
│           ├── pages/
│           │   └── products_page.dart
│           └── widgets/
│               └── product_dialog.dart
└── main.dart
