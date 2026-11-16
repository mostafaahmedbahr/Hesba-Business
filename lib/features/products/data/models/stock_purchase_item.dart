class StockPurchaseItem {
  final String productId;
  final String productName;
  final double quantity;
  final double unitCost;

  const StockPurchaseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  double get total => quantity * unitCost;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitCost': unitCost,
        'total': total,
      };
}
