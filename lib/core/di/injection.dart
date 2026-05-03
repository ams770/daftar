import 'package:get_it/get_it.dart';
import '../services/excel_service.dart';
import '../services/excel_service_impl.dart';
import '../../features/products/data/datasources/product_local_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/add_product.dart';
import '../../features/products/domain/usecases/get_product_by_code.dart';
import '../../features/products/domain/usecases/get_products_paginated.dart';
import '../../features/products/domain/usecases/update_product.dart';
import '../../features/products/domain/usecases/validate_excel_products_use_case.dart';
import '../../features/products/domain/usecases/import_excel_products_use_case.dart';
import '../../features/products/domain/usecases/export_products_to_excel_use_case.dart';
import '../../features/products/domain/usecases/delete_product.dart';
import '../../features/products/presentation/cubits/products_cubit.dart';
import '../../features/invoices/data/datasources/invoice_local_datasource.dart';
import '../../features/invoices/data/repositories/invoice_repository_impl.dart';
import '../../features/invoices/domain/repositories/invoice_repository.dart';
import '../../features/invoices/presentation/cubits/invoice_cubit.dart';
import '../../features/invoices/presentation/cubits/add_invoice_cubit.dart';
import '../../features/invoices/presentation/cubits/money_collection_cubit.dart';
import '../../features/settings/presentation/cubits/settings_cubit.dart';
import '../database/database_helper.dart';
import '../services/settings_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Cubits
  sl.registerFactory(() => ProductsCubit(
        getProductsPaginated: sl(),
        getProductByCode: sl(),
        addProduct: sl(),
        updateProduct: sl(),
        validateExcelProducts: sl(),
        importExcelProducts: sl(),
        exportProductsToExcel: sl(),
        deleteProduct: sl(),
        excelService: sl(),
      ));
  sl.registerFactory(() => SettingsCubit(sl()));
  sl.registerFactory(() => InvoiceCubit(sl()));
  sl.registerFactory(() => AddInvoiceCubit(sl()));
  sl.registerFactory(() => MoneyCollectionCubit(sl()));

  // Use cases
  sl.registerLazySingleton(() => GetProductsPaginated(sl()));
  sl.registerLazySingleton(() => GetProductByCode(sl()));
  sl.registerLazySingleton(() => AddProduct(sl()));
  sl.registerLazySingleton(() => UpdateProduct(sl()));
  sl.registerLazySingleton(() => ValidateExcelProductsUseCase(sl()));
  sl.registerLazySingleton(() => ImportExcelProductsUseCase(sl()));
  sl.registerLazySingleton(() => ExportProductsToExcelUseCase(sl(), sl()));
  sl.registerLazySingleton(() => DeleteProduct(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<InvoiceLocalDataSource>(
    () => InvoiceLocalDataSourceImpl(sl()),
  );

  // Services
  sl.registerLazySingleton<ExcelService>(() => ExcelServiceImpl());
  sl.registerLazySingleton<SettingsService>(() => SettingsServiceImpl(sl()));

  // Core
  sl.registerLazySingleton(() => DatabaseHelper.instance);
}
