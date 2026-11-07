import 'models/stock_purchase_item.dart';

/// سطر شراء قادم من الواجهة — قيم غير موثوقة تُعاد معالجتها بالكامل هنا
/// داخل معاملة Firestore اعتماداً على لقطات المنتجات الموثوقة.
class PurchaseLineInput {
  final String productId;
  final double quantity;
  final double purchaseUnitCost;

  const PurchaseLineInput({
    required this.productId,
    required this.quantity,
    required this.purchaseUnitCost,
  });
}

/// لقطة منتج موثوقة كما قُرئت داخل المعاملة من مجموعة `products`.
class ProductSnapshot {
  final String id;
  final String name;
  final String shopId;
  final double stock;
  final double costPrice;

  const ProductSnapshot({
    required this.id,
    required this.name,
    required this.shopId,
    required this.stock,
    required this.costPrice,
  });
}

/// تحديث مطلوب لمنتج واحد بعد المعادلة المرجحة.
class ProductUpdate {
  final String productId;
  final double newStock;
  final double newAverageCost;

  const ProductUpdate({
    required this.productId,
    required this.newStock,
    required this.newAverageCost,
  });
}

/// نتيجة المعالجة الكاملة: كل ما يجب كتابته داخل المعاملة.
class ComputedPurchase {
  final List<StockPurchaseItem> items;
  final Map<String, ProductUpdate> productUpdates;
  final double totalAmount;

  const ComputedPurchase({
    required this.items,
    required this.productUpdates,
    required this.totalAmount,
  });
}

/// معادلات زيادة المخزون — منطق نقي بلا أي اعتماد على Firestore أو الواجهة.
///
/// القواعد:
///  - newStock = currentStock + receivedQuantity
///  - المخزون الحالي = صفر  → newAverageCost = purchaseUnitCost
///  - غير ذلك            → متوسط مرجح:
///      ((currentStock × currentCost) + (receivedQuantity × purchaseUnitCost))
///      / (currentStock + receivedQuantity)
///
/// كل الفشل يُرمى كـ Exception برسالة عربية تصل للمستخدم كما هي
/// (نفس نمط SalesRepoImpl)، وأي خطأ يفشل عملية الشراء كلها بلا تحديث جزئي.
class StockPurchaseCalculator {
  StockPurchaseCalculator._();

  /// تقريب مالي لخانتين عشريتين (12.346 ← 12.35).
  static double roundMoney(double value) =>
      (value * 100).roundToDouble() / 100;

  /// newStock = المخزون الحالي + الكمية الواردة.
  static double computeNewStock({
    required double currentStock,
    required double receivedQuantity,
  }) {
    final newStock = currentStock + receivedQuantity;
    if (!newStock.isFinite) {
      throw Exception('قيمة المخزون الجديد غير صالحة');
    }
    return newStock;
  }

  /// متوسط سعر الشراء الجديد (مرجح) — يتعامل مع المخزون الصفري بلا قسمة على صفر.
  static double computeAverageCost({
    required double currentStock,
    required double currentCost,
    required double receivedQuantity,
    required double purchaseUnitCost,
  }) {
    if (!receivedQuantity.isFinite || receivedQuantity <= 0) {
      throw Exception('الكمية يجب أن تكون أكبر من صفر');
    }
    if (!purchaseUnitCost.isFinite || purchaseUnitCost < 0) {
      throw Exception('سعر الشراء غير صالح');
    }
    if (!currentStock.isFinite || currentStock < 0) {
      throw Exception('المخزون الحالي غير صالح');
    }
    if (!currentCost.isFinite || currentCost < 0) {
      throw Exception('تكلفة الشراء الحالية غير صالحة');
    }

    // مخزون صفري (أو لم يصل أي كمية بعد): التكلفة الجديدة = سعر الشراء.
    if (currentStock == 0) {
      return roundMoney(purchaseUnitCost);
    }

    final totalQuantity = currentStock + receivedQuantity; // > 0 دائماً هنا
    final totalValue =
        (currentStock * currentCost) + (receivedQuantity * purchaseUnitCost);
    final average = totalValue / totalQuantity;
    if (!average.isFinite) {
      throw Exception('متوسط سعر الشراء غير صالح');
    }
    return roundMoney(average);
  }

  /// يعالج الفاتورة كلها من القيم الموثوقة ويعيد ما يجب كتابته.
  ///
  /// يرمي Exception على أول مشكلة (منتج ناقص/ملكية خاطئة/قيمة غير صالحة)
  /// — المعاملة كاملة تفشل عندها بدون أي تحديث جزئي.
  static ComputedPurchase compute({
    required String shopId,
    required List<PurchaseLineInput> lines,
    required Map<String, ProductSnapshot> products,
  }) {
    if (shopId.trim().isEmpty) {
      throw Exception('لم يتم العثور على المتجر');
    }
    if (lines.isEmpty) {
      throw Exception('يجب إضافة منتج واحد على الأقل');
    }

    final seenProductIds = <String>{};
    final items = <StockPurchaseItem>[];
    final updates = <String, ProductUpdate>{};
    var totalAmount = 0.0;

    for (final line in lines) {
      final label = _labelFor(line, products);

      if (line.productId.trim().isEmpty) {
        throw Exception('يجب اختيار المنتج');
      }
      if (!seenProductIds.add(line.productId)) {
        throw Exception('المنتج مكرر في الفاتورة: $label');
      }
      if (!line.quantity.isFinite || line.quantity <= 0) {
        throw Exception('الكمية يجب أن تكون أكبر من صفر: $label');
      }
      if (!line.purchaseUnitCost.isFinite || line.purchaseUnitCost < 0) {
        throw Exception('سعر شراء غير صالح: $label');
      }

      final product = products[line.productId];
      if (product == null) {
        throw Exception('المنتج غير موجود: $label');
      }
      if (product.shopId != shopId) {
        throw Exception('المنتج لا يتبع هذا المحل: ${product.name}');
      }
      if (!product.stock.isFinite ||
          product.stock < 0 ||
          !product.costPrice.isFinite ||
          product.costPrice < 0) {
        throw Exception('بيانات المنتج غير صالحة: ${product.name}');
      }

      final newStock = computeNewStock(
        currentStock: product.stock,
        receivedQuantity: line.quantity,
      );
      final newAverageCost = computeAverageCost(
        currentStock: product.stock,
        currentCost: product.costPrice,
        receivedQuantity: line.quantity,
        purchaseUnitCost: line.purchaseUnitCost,
      );
      final lineTotal = roundMoney(line.quantity * line.purchaseUnitCost);
      if (!lineTotal.isFinite) {
        throw Exception('قيمة السطر غير صالحة: ${product.name}');
      }

      items.add(
        StockPurchaseItem(
          productId: line.productId,
          productName: product.name,
          quantity: line.quantity,
          previousStock: product.stock,
          newStock: newStock,
          previousCost: product.costPrice,
          purchaseUnitCost: line.purchaseUnitCost,
          newAverageCost: newAverageCost,
          lineTotal: lineTotal,
        ),
      );
      updates[line.productId] = ProductUpdate(
        productId: line.productId,
        newStock: newStock,
        newAverageCost: newAverageCost,
      );
      totalAmount += lineTotal;
    }

    final total = roundMoney(totalAmount);
    if (!total.isFinite) {
      throw Exception('إجمالي الفاتورة غير صالح');
    }

    return ComputedPurchase(
      items: items,
      productUpdates: updates,
      totalAmount: total,
    );
  }

  /// اسم المنتج للرسالة (من اللقطة الموثوقة) مع fallback للمعرّف.
  static String _labelFor(
    PurchaseLineInput line,
    Map<String, ProductSnapshot> products,
  ) {
    final snapshot = products[line.productId];
    if (snapshot != null && snapshot.name.trim().isNotEmpty) {
      return snapshot.name;
    }
    return line.productId;
  }
}
