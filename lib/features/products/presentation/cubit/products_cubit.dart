import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/product.dart';
import '../../data/repos/products_repo.dart';
import '../states/products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final ProductsRepo _repo;
  StreamSubscription<List<Product>>? _sub;

  ProductsCubit({required this._repo})
      : super(const ProductsState());

  void init() {
    _sub ??= _repo.watchProducts().listen(
          (products) => emit(
            ProductsState(status: ProductsStatus.success, products: products),
          ),
          onError: (Object e) => emit(
            ProductsState(status: ProductsStatus.failure, errorMessage: '$e'),
          ),
        );
    loadShopType();
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
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _repo.updateProduct(product);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _repo.deleteProduct(productId);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}