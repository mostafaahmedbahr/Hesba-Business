import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/log_util.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/app_events.dart';
import '../../data/repos/products_repo.dart';
import '../states/products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final ProductsRepo _repo;
  StreamSubscription<List<Product>>? _sub;

  ProductsCubit({required this._repo})
      : super(const ProductsState());

  void init() {
    _sub ??= _repo.watchProducts().listen(
          // copyWith عشان البحث والفلتر مايتصفروش مع كل تحديث.
          (products) => emit(
            state.copyWith(status: ProductsStatus.success, products: products, clearError: true),
          ),
          onError: (Object e) => emit(
            state.copyWith(status: ProductsStatus.failure, errorMessage: '$e'),
          ),
        );
    loadShopType();
  }

  /// يحدث البحث.
  void setSearch(String query) {
    if (query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
  }

  /// يحدث فلتر القسم.
  void setCategoryFilter(String filter) {
    if (filter == state.categoryFilter) return;
    emit(state.copyWith(categoryFilter: filter));
  }

  /// Fetches the shop business type and keeps it in the state. Safe to call
  /// again if the form opens before it has been loaded.
  Future<String?> loadShopType() async {
    final type = await _repo.getShopBusinessType();
    if (!isClosed && type != null) {
      emit(state.copyWith(shopType: type));
    }
    return type;
  }

  Future<bool> addProduct(Product product) async {
    try {
      await _repo.addProduct(product);
      AppEvents.instance.productAdded();
      AppEvents.instance.productChanged();
      return true;
    } catch (e) {
      logWarning('[ProductsCubit] addProduct failed: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _repo.updateProduct(product);
      AppEvents.instance.productUpdated();
      AppEvents.instance.productChanged();
      return true;
    } catch (e) {
      logWarning('[ProductsCubit] updateProduct failed: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _repo.deleteProduct(productId);
      AppEvents.instance.productDeleted();
      AppEvents.instance.productChanged();
      return true;
    } catch (e) {
      logWarning('[ProductsCubit] deleteProduct failed: $e');
      return false;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}