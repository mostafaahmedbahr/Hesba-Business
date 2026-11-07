import 'package:equatable/equatable.dart';

import '../../../../core/models/product.dart';
import '../../../../core/utils/number_parser.dart';
import '../../data/stock_purchase_calculator.dart';

enum StockPurchaseStatus { initial, saving, success, error }

/// سطر واحد في نموذج الفاتورة — النصوص الخام هنا (مصدر الحساب) والواجهة
/// مجرد عرض يرسل التغييرات عبر Cubit (بلا setState).
class PurchaseLine extends Equatable {
  final String id;

  /// فاضي = المنتج لم يُختار بعد.
  final String productId;
  final String productName;

  /// لقطة عرض وقت الاختيار (المعاملة تقرأ القيم الحقيقية بنفسها).
  final double currentStock;
  final double currentCost;

  /// نص الكمية ونص سعر شراء الوحدة كما كتبهما المستخدم.
  final String qtyText;
  final String costText;

  const PurchaseLine({
    required this.id,
    this.productId = '',
    this.productName = '',
    this.currentStock = 0,
    this.currentCost = 0,
    this.qtyText = '',
    this.costText = '',
  });

  bool get hasProduct => productId.isNotEmpty;

  /// القيم بعد تحويل الأرقام العربية (صفر لو النص غير صالح).
  double get qty => NumberParser.parseDouble(qtyText);
  double get unitCost => NumberParser.parseDouble(costText);

  /// مفتاح خطأ التحقق (null = السطر صالح) — يُترجم عبر translateError.
  String? get validationErrorKey {
    if (!hasProduct) return 'purchaseErrPickProduct';
    if (qtyText.trim().isEmpty || !qty.isFinite || qty <= 0) {
      return 'purchaseErrQtyPositive';
    }
    if (costText.trim().isEmpty || !unitCost.isFinite || unitCost < 0) {
      return 'purchaseErrCostNegative';
    }
    return null;
  }

  /// إجمالي السطر للعرض — صفر لو القيم ناقصة/غير صالحة.
  double get lineTotal {
    if (validationErrorKey != null) return 0;
    return StockPurchaseCalculator.roundMoney(qty * unitCost);
  }

  PurchaseLine copyWith({
    String? productId,
    String? productName,
    double? currentStock,
    double? currentCost,
    String? qtyText,
    String? costText,
  }) {
    return PurchaseLine(
      id: id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      currentCost: currentCost ?? this.currentCost,
      qtyText: qtyText ?? this.qtyText,
      costText: costText ?? this.costText,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        currentStock,
        currentCost,
        qtyText,
        costText,
      ];
}

class StockPurchaseState extends Equatable {
  final StockPurchaseStatus status;

  /// أسطر الفاتورة (سطر واحد فاضي على الأقل).
  final List<PurchaseLine> lines;

  /// المنتجات الفعالة المتاحة للاختيار (من stream المنتجات).
  final List<Product> products;
  final bool productsLoaded;

  /// تاريخ الشراء (اختيار المستخدم).
  final DateTime purchaseDate;

  /// مفتاح/رسالة الخطأ — مفتاح ترجمة يبدأ بـ purchaseErr أو رسالة عربية
  /// خام من الـ repo تمر كما هي (نفس سلوك translateError في المبيعات).
  final String? errorMessage;
  final Map<String, String> errorArgs;

  StockPurchaseState({
    this.status = StockPurchaseStatus.initial,
    this.lines = const [],
    this.products = const [],
    this.productsLoaded = false,
    DateTime? purchaseDate,
    this.errorMessage,
    this.errorArgs = const {},
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  /// عدد الأصناف المختارة فعلاً.
  int get itemCount => lines.where((l) => l.hasProduct).length;

  /// إجمالي الفاتورة (مجموع الأسطر الصالحة، مقرَّب لخانتين).
  double get totalAmount => StockPurchaseCalculator.roundMoney(
        lines.fold<double>(0, (sum, line) => sum + line.lineTotal),
      );

  /// فيه سطر واحد مختار على الأقل (شرط عرض زر التأكيد كمُفعّل).
  bool get hasSelection => lines.any((l) => l.hasProduct);

  bool get isSaving => status == StockPurchaseStatus.saving;

  StockPurchaseState copyWith({
    StockPurchaseStatus? status,
    List<PurchaseLine>? lines,
    List<Product>? products,
    bool? productsLoaded,
    DateTime? purchaseDate,
    String? errorMessage,
    Map<String, String>? errorArgs,
    bool clearError = false,
  }) {
    return StockPurchaseState(
      status: status ?? this.status,
      lines: lines ?? this.lines,
      products: products ?? this.products,
      productsLoaded: productsLoaded ?? this.productsLoaded,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorArgs: clearError ? const {} : (errorArgs ?? this.errorArgs),
    );
  }

  @override
  List<Object?> get props => [
        status,
        lines,
        products,
        productsLoaded,
        purchaseDate,
        errorMessage,
        errorArgs,
      ];
}
