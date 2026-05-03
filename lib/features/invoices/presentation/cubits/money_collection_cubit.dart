import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/money_collection.dart';
import '../../domain/repositories/invoice_repository.dart';

abstract class MoneyCollectionState extends Equatable {
  final List<MoneyCollection> collections;
  final bool hasMore;
  final String? searchQuery;
  final DateTime startDate;
  final DateTime endDate;

  const MoneyCollectionState({
    required this.collections,
    required this.hasMore,
    this.searchQuery,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [collections, hasMore, searchQuery, startDate, endDate];
}

class MoneyCollectionInitial extends MoneyCollectionState {
  MoneyCollectionInitial()
      : super(
          collections: [],
          hasMore: true,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 1)),
        );
}

class MoneyCollectionLoading extends MoneyCollectionState {
  const MoneyCollectionLoading({
    required super.collections,
    required super.hasMore,
    super.searchQuery,
    required super.startDate,
    required super.endDate,
  });
}

class MoneyCollectionLoaded extends MoneyCollectionState {
  const MoneyCollectionLoaded({
    required super.collections,
    required super.hasMore,
    super.searchQuery,
    required super.startDate,
    required super.endDate,
  });

  MoneyCollectionLoaded copyWith({
    List<MoneyCollection>? collections,
    bool? hasMore,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return MoneyCollectionLoaded(
      collections: collections ?? this.collections,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class MoneyCollectionError extends MoneyCollectionState {
  final String message;
  const MoneyCollectionError({
    required this.message,
    required super.collections,
    required super.hasMore,
    super.searchQuery,
    required super.startDate,
    required super.endDate,
  });

  @override
  List<Object?> get props => [...super.props, message];
}

class MoneyCollectionCubit extends Cubit<MoneyCollectionState> {
  final InvoiceRepository repository;
  static const int _limit = 20;

  MoneyCollectionCubit(this.repository) : super(MoneyCollectionInitial());

  Future<void> loadCollections({bool refresh = false}) async {
    if (state is MoneyCollectionLoading && !refresh) return;

    final currentOffset = refresh ? 0 : state.collections.length;
    
    emit(MoneyCollectionLoading(
      collections: refresh ? [] : state.collections,
      hasMore: refresh ? true : state.hasMore,
      searchQuery: state.searchQuery,
      startDate: state.startDate,
      endDate: state.endDate,
    ));

    try {
      final newCollections = await repository.getCollectionsPaginated(
        limit: _limit,
        offset: currentOffset,
        searchQuery: state.searchQuery,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      emit(MoneyCollectionLoaded(
        collections: refresh ? newCollections : [...state.collections, ...newCollections],
        hasMore: newCollections.length == _limit,
        searchQuery: state.searchQuery,
        startDate: state.startDate,
        endDate: state.endDate,
      ));
    } catch (e) {
      emit(MoneyCollectionError(
        message: e.toString(),
        collections: state.collections,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        startDate: state.startDate,
        endDate: state.endDate,
      ));
    }
  }

  Future<void> setSearchQuery(String? query) async {
    emit(MoneyCollectionLoaded(
      collections: [],
      hasMore: true,
      searchQuery: query,
      startDate: state.startDate,
      endDate: state.endDate,
    ));
    await loadCollections(refresh: true);
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    emit(MoneyCollectionLoaded(
      collections: [],
      hasMore: true,
      searchQuery: state.searchQuery,
      startDate: start,
      endDate: end,
    ));
    await loadCollections(refresh: true);
  }

  Future<void> addCollection(MoneyCollection collection) async {
    try {
      await repository.saveMoneyCollection(collection);
      // Reload collections to show the new one
      await loadCollections(refresh: true);
    } catch (e) {
      emit(MoneyCollectionError(
        message: e.toString(),
        collections: state.collections,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        startDate: state.startDate,
        endDate: state.endDate,
      ));
    }
  }

  Future<void> deleteCollection(int id) async {
    try {
      await repository.deleteMoneyCollection(id);
      await loadCollections(refresh: true);
    } catch (e) {
      emit(MoneyCollectionError(
        message: e.toString(),
        collections: state.collections,
        hasMore: state.hasMore,
        searchQuery: state.searchQuery,
        startDate: state.startDate,
        endDate: state.endDate,
      ));
    }
  }

  Future<List<MoneyCollection>> getCollectionsByInvoice(int invoiceId) async {
    return await repository.getCollectionsByInvoice(invoiceId);
  }
}
