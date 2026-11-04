import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/log_util.dart';
import '../../../../core/models/product.dart';
import '../../../../core/utils/number_parser.dart';
import '../../data/models/product_field.dart';
import '../../data/models/product_fields_catalog.dart';
import '../../data/repos/product_config_repo.dart';
import '../states/product_form_state.dart';

/// يدير نموذج إضافة/تعديل المنتج:
/// - تحميل إعدادات الحقول حسب نشاط المتجر من Firebase.
/// - إظهار/إخفاء الحقول الاختيارية.
/// - التحقق من القيم وبناء كائن Product (مع specs) للحفظ.
///
/// الحفظ الفعلي يمر عبر ProductsCubit (مع الحفاظ على سلوك AppEvents الحالي).
class ProductFormCubit extends Cubit<ProductFormState> {
  final ProductConfigRepo _configRepo;

  ProductFormCubit({required ProductConfigRepo configRepo})
    : _configRepo = configRepo,
      super(const ProductFormState());

  /// يحمّل إعدادات الحقول من نوع النشاط. آمن أكثر من مرة.
  ///
  /// [existing]: المنتج الحالي (وضع التعديل) — الحقول الاختيارية المليئة
  /// تُظهر تلقائياً حتى لا تختفي بيانات قديمة عن المستخدم.
  Future<void> load({Product? existing}) async {
    emit(state.copyWith(status: ProductFormStatus.loading, clearError: true));
    try {
      final config = await _configRepo.getProductFormConfig();
      final visible = <String>{};
      if (existing != null) {
        for (final f in config.optionalFields) {
          if (_hasValue(existing, f.key)) visible.add(f.key);
        }
      }
      emit(
        state.copyWith(
          status: ProductFormStatus.ready,
          config: config,
          businessType: config.businessType,
          visibleOptional: visible,
          clearError: true,
        ),
      );
    } catch (e) {
      // فشل غير متوقع → نكمل بإعدادات عامة حتى لا تتعطل الشاشة.
      logWarning('[ProductFormCubit] load config failed: $e');
      emit(
        state.copyWith(
          status: ProductFormStatus.ready,
          config: ProductFieldsCatalog.configFor(null),
          clearError: true,
        ),
      );
    }
  }

  /// هل الحقل الاختياري ظاهر؟
  bool isFieldVisible(ProductFieldConfig field) =>
      !field.optional || state.visibleOptional.contains(field.key);

  /// إظهار/إخفاء حقل اختياري من بطاقة "مواصفات إضافية".
  void toggleOptional(String key) {
    final next = Set<String>.from(state.visibleOptional);
    if (!next.remove(key)) next.add(key);
    emit(state.copyWith(visibleOptional: next));
  }

  // ─────────────────────────── التحقق ───────────────────────────

  /// يتحقق من القيم الظاهرة ويرجع مفتاح رسالة الخطأ (مترجم) أو null.
  ///
  /// القواعد مبنية على إعدادات الحقول: إجباري + أرقام + سعر موجب.
  String? validate(Map<String, dynamic> values) {
    // وجود صفوف Variants يعني أن الكمية محسوبة منها (الحقل قد يكون فارغاً).
    final variantsRaw = values[ProductFieldKeys.variants];
    final hasVariantRows = variantsRaw is List && variantsRaw.isNotEmpty;

    for (final field in state.config.fields) {
      if (!isFieldVisible(field)) continue;
      if (field.key == ProductFieldKeys.stock && hasVariantRows) continue;
      final raw = values[field.key];
      final text = raw is String ? raw.trim() : '';

      if (field.required) {
        final empty = raw == null ||
            (raw is String && raw.trim().isEmpty) ||
            (raw is List && raw.isEmpty);
        if (empty) return 'validatorRequired';
      }

      switch (field.type) {
        case ProductFieldType.decimal:
          if (text.isEmpty) {
            if (field.required) return 'validatorRequired';
            break;
          }
          final n = double.tryParse(NumberParser.toLatin(text));
          if (n == null) return 'validatorNumber';
          if (n <= 0) return 'validatorPositiveNumber';
        case ProductFieldType.number:
          if (text.isEmpty) {
            if (field.required) return 'validatorRequired';
            break;
          }
          final n = int.tryParse(NumberParser.toLatin(text));
          if (n == null || n < 0) return 'productsInvalidNumber';
        default:
          break;
      }
    }
    return null;
  }

  // ─────────────────────── بناء المنتج ───────────────────────

  /// يبني المنتج من قيم الحقول الظاهرة.
  ///
  /// - الحقول الأساسية → top-level (color/size/...) للتوافق مع البيانات القديمة.
  /// - الباقي → specs، مع الحفاظ على specs القديمة غير الواردة في القيم
  ///   (مثل حقل اختياري مخفي مُدخل قيمته سابقاً).
  /// - الكمية = مجموع صفوف Variants لو موجودة.
  Product buildProduct({
    Product? existing,
    required Map<String, dynamic> values,
  }) {
    final specs = Map<String, dynamic>.from(existing?.specs ?? const {});

    // طبقة القيم الظاهرة فوق specs القديمة.
    values.forEach((key, value) {
      if (_isBaseField(key)) return;
      if (value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty)) {
        specs.remove(key);
      } else if (value is String) {
        specs[key] = value.trim();
      } else {
        specs[key] = value;
      }
    });

    String str(String key) {
      final v = values[key];
      return v is String ? v.trim() : '';
    }

    final variants = values[ProductFieldKeys.variants];
    var stock = int.tryParse(NumberParser.toLatin(str(ProductFieldKeys.stock))) ??
        existing?.stock ??
        0;
    if (variants is List && variants.isNotEmpty) {
      stock = 0;
      for (final row in variants) {
        if (row is Map) {
          stock += int.tryParse(
                NumberParser.toLatin('${row['qty'] ?? ''}'),
              ) ??
              0;
        }
      }
    }

    final costPrice =
        double.tryParse(NumberParser.toLatin(str(ProductFieldKeys.costPrice))) ??
        existing?.costPrice ??
        0;
    final price =
        double.tryParse(NumberParser.toLatin(str(ProductFieldKeys.price))) ??
        existing?.price ??
        0;
    // الحقل الفاضي يحتفظ بالافتراضي التاريخي 5.
    final lowStockText = str(ProductFieldKeys.lowStockThreshold);
    final lowStock = lowStockText.isEmpty
        ? (existing?.lowStockThreshold ?? 5)
        : (int.tryParse(NumberParser.toLatin(lowStockText)) ??
              existing?.lowStockThreshold ??
              5);

    // color/size تبقى top-level؛ تُمرَّر فقط لو الحقل ظاهر في الإعدادات.
    final hasColor = state.config.has(ProductFieldKeys.color);
    final hasSize = state.config.has(ProductFieldKeys.size);
    final color = hasColor ? str(ProductFieldKeys.color) : null;
    final size = hasSize ? str(ProductFieldKeys.size) : null;

    if (existing != null) {
      return existing.copyWith(
        name: str(ProductFieldKeys.name),
        category: str(ProductFieldKeys.category),
        code: str(ProductFieldKeys.code),
        costPrice: costPrice,
        price: price,
        stock: stock,
        lowStockThreshold: lowStock,
        notes: str(ProductFieldKeys.notes),
        imageUrl: str(ProductFieldKeys.imageUrl),
        specs: specs,
        color: color ?? existing.color,
        size: size ?? existing.size,
      );
    }

    return Product(
      id: '',
      name: str(ProductFieldKeys.name),
      category: str(ProductFieldKeys.category),
      code: str(ProductFieldKeys.code),
      costPrice: costPrice,
      price: price,
      stock: stock,
      lowStockThreshold: lowStock,
      notes: str(ProductFieldKeys.notes),
      imageUrl: str(ProductFieldKeys.imageUrl),
      color: color ?? '',
      size: size ?? '',
      specs: specs,
      shopId: '',
      ownerId: '',
    );
  }

  // ─────────────────────────── خصوصي ───────────────────────────

  static const _baseFields = {
    ProductFieldKeys.name,
    ProductFieldKeys.category,
    ProductFieldKeys.code,
    ProductFieldKeys.costPrice,
    ProductFieldKeys.price,
    ProductFieldKeys.stock,
    ProductFieldKeys.lowStockThreshold,
    ProductFieldKeys.color,
    ProductFieldKeys.size,
    ProductFieldKeys.notes,
    ProductFieldKeys.imageUrl,
  };

  bool _isBaseField(String key) => _baseFields.contains(key);

  /// هل المنتج الحالي يحمل قيمة لهذا الحقل (لإظهار الاختياري تلقائياً)؟
  bool _hasValue(Product product, String key) {
    if (_isBaseField(key)) {
      switch (key) {
        case ProductFieldKeys.color:
          return product.color.trim().isNotEmpty;
        case ProductFieldKeys.size:
          return product.size.trim().isNotEmpty;
        case ProductFieldKeys.notes:
          return product.notes.trim().isNotEmpty;
        case ProductFieldKeys.imageUrl:
          return product.imageUrl.trim().isNotEmpty;
        default:
          return false;
      }
    }
    final v = product.specs[key];
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is List) return v.isNotEmpty;
    if (v is bool) return v;
    return true;
  }
}
