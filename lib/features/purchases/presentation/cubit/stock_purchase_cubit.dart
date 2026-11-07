import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/product.dart';
import '../../../../core/services/app_events.dart';
import '../../../products/data/repos/products_repo.dart';
import '../../data/repos/stock_purchase_repo.dart';
import '../../data/stock_purchase_calculator.dart';
import 'stock_purchase_state.dart';

/// يدير شاشة زيادة المخزون: أسطر الفاتورة، تاريخ الشراء، قائمة المنتجات،
/// والإرسال مع حماية من النقر المزدوج ومفتاح تكرار لكل جلسة إرسال.
class StockPurchaseCubit extends Cubit<StockPurchaseState> {
  final StockPurchaseRepo repo;
  final ProductsRepo productsRepo;

  StreamSubscription<List<Product>>? _productsSub;
  int _seq = 0;

  /// مفتاح تكرار الإرسال — يُنشأ مرة واحدة لكل محاولة حفظ ويُعاد استخدامه
  /// عند إعادة المحاولة بعد خطأ، ويُمسح بعد النجاح.
  String? _purchaseId;

  StockPurchaseCubit({
    required this.repo,
    required this.productsRepo,
  }) : super(StockPurchaseState()) {
    // منتجات المحل الحيّة — الفعالة فقط (المخفي للبيع لا يُعاد تعبئته).
    _productsSub = productsRepo.watchProducts().listen(
      (products) {
        if (isClosed) return;
        emit(
          state.copyWith(
            products: products.where((p) => p.isActive).toList(),
            productsLoaded: true,
          ),
        );
      },
      onError: (_) {
        if (!isClosed) emit(state.copyWith(productsLoaded: true));
      },
    );
  }

  /// سطر جديد فاضي (يبدأ باختيار المنتج).
  void addLine() {
    emit(
      state.copyWith(
        lines: [...state.lines, PurchaseLine(id: 'line_${_seq++}')],
      ),
    );
  }

  void removeLine(String id) {
    if (state.lines.length <= 1) return; // سطر واحد على الأقل دائماً.
    emit(state.copyWith(lines: state.lines.where((l) => l.id != id).toList()));
  }

  /// اختيار منتج لسطر: يحفظ اللقطة ويقترح سعر شراء الوحدة الحالي لو الحقل فاضي.
  void selectProduct(String lineId, Product product) {
    emit(
      state.copyWith(
        lines: state.lines.map((line) {
          if (line.id != lineId) return line;
          final prefillCost = line.costText.trim().isEmpty
              ? (product.costPrice % 1 == 0
                  ? product.costPrice.toStringAsFixed(0)
                  : product.costPrice.toStringAsFixed(2))
              : line.costText;
          return line.copyWith(
            productId: product.id,
            productName: product.name,
            currentStock: product.stock,
            currentCost: product.costPrice,
            costText: prefillCost,
          );
        }).toList(),
      ),
    );
  }

  /// إلغاء اختيار المنتج (إرجاع السطر لحالته الفاضية — الكمية المكتوبة
  /// تفضل كما هي وسعر الوحدة يُمسح ليُقترح من المنتج الجديد).
  void clearProduct(String lineId) {
    emit(
      state.copyWith(
        lines: state.lines.map((line) {
          if (line.id != lineId) return line;
          return PurchaseLine(id: line.id, qtyText: line.qtyText);
        }).toList(),
      ),
    );
  }

  /// تحديث نص كمية/تكلفة لسطر (يُعاد حساب الإجماليات فوراً).
  void updateLineText(String lineId, {String? qtyText, String? costText}) {
    emit(
      state.copyWith(
        lines: state.lines.map((line) {
          if (line.id != lineId) return line;
          return line.copyWith(qtyText: qtyText, costText: costText);
        }).toList(),
      ),
    );
  }

  void setDate(DateTime date) => emit(state.copyWith(purchaseDate: date));

  /// جلسة جديدة: سطر فاضي واحد + مسح مفتاح التكرار.
  void reset() {
    _purchaseId = null;
    emit(
      StockPurchaseState(
        lines: [PurchaseLine(id: 'line_${_seq++}')],
        purchaseDate: DateTime.now(),
      ),
    );
  }

  /// حفظ الفاتورة — حماية نقر مزدوج + تحقق مسبق قبل الاتصال بالـ repo.
  Future<void> submit({
    String supplierName = '',
    String supplierPhone = '',
    String invoiceNumber = '',
    String notes = '',
  }) async {
    if (state.isSaving) return; // إعادة الدخول (double-tap) لا تُنشئ فاتورتين.

    if (state.lines.isEmpty || !state.hasSelection) {
      _emitClientError('purchaseErrEmptyLines');
      return;
    }
    for (var i = 0; i < state.lines.length; i++) {
      final line = state.lines[i];
      if (!line.hasProduct) {
        _emitClientError('purchaseErrPickProduct', {'row': '${i + 1}'});
        return;
      }
      final errorKey = line.validationErrorKey;
      if (errorKey != null) {
        _emitClientError(errorKey);
        return;
      }
    }

    emit(state.copyWith(
      status: StockPurchaseStatus.saving,
      clearError: true,
    ));

    try {
      // نفس المعرّف لكل إعادة محاولة داخل نفس الجلسة → منع التكرار.
      _purchaseId ??= repo.generatePurchaseId();

      await repo.addPurchase(
        purchaseId: _purchaseId!,
        ownerId: '',
        shopId: '',
        supplierName: supplierName,
        supplierPhone: supplierPhone,
        invoiceNumber: invoiceNumber,
        purchaseDate: state.purchaseDate,
        notes: notes,
        lines: [
          for (final line in state.lines)
            PurchaseLineInput(
              productId: line.productId,
              quantity: line.qty,
              purchaseUnitCost: line.unitCost,
            ),
        ],
      );

      _purchaseId = null;
      // تحديث كل الشاشات (المنتجات/الرئيسية/التقارير) بعد زيادة المخزون.
      AppEvents.instance.productChanged();

      emit(state.copyWith(status: StockPurchaseStatus.success));
    } catch (e) {
      final msg = '$e'.replaceAll('Exception: ', '');
      emit(state.copyWith(status: StockPurchaseStatus.error, errorMessage: msg));
      // _purchaseId يُمسح فقط بعد النجاح — إعادة المحاولة تستخدم نفس المفتاح.
    }
  }

  void _emitClientError(String key, [Map<String, String>? args]) {
    emit(state.copyWith(
      status: StockPurchaseStatus.error,
      errorMessage: key,
      errorArgs: args,
    ));
  }

  @override
  Future<void> close() {
    _productsSub?.cancel();
    return super.close();
  }
}
