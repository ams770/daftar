import 'package:get_it/get_it.dart';
import '../../features/products/data/datasources/product_local_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/add_product.dart';
import '../../features/products/domain/usecases/get_product_by_code.dart';
import '../../features/products/domain/usecases/get_products_paginated.dart';
import '../../features/products/domain/usecases/update_product.dart';
import '../../features/products/presentation/cubits/products_cubit.dart';
import '../database/database_helper.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Cubits
  sl.registerFactory(() => ProductsCubit(
        getProductsPaginated: sl(),
        getProductByCode: sl(),
        addProduct: sl(),
        updateProduct: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetProductsPaginated(sl()));
  sl.registerLazySingleton(() => GetProductByCode(sl()));
  sl.registerLazySingleton(() => AddProduct(sl()));
  sl.registerLazySingleton(() => UpdateProduct(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(sl()),
  );

  // Core
  sl.registerLazySingleton(() => DatabaseHelper.instance);
}
