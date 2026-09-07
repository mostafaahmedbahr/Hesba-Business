class AppConstants {
  static const String appName = 'حسبة';
  static const String appDescription = 'نظام إدارة المحلات الصغيرة';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String shopsCollection = 'shops';
  static const String productsCollection = 'products';
  static const String salesCollection = 'sales';
  static const String returnsCollection = 'returns';
  static const String expensesCollection = 'expenses';
  static const String cashRegisterCollection = 'cashRegister';

  // User Roles
  static const String roleOwner = 'owner';
  static const String roleManager = 'manager';
  static const String roleCashier = 'cashier';

  // Expense Categories
  static const List<String> expenseCategories = [
    'إيجار',
    'رواتب',
    'مرافق',
    'مستلزمات',
    'أخرى',
  ];

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentCard = 'card';
  static const String paymentMobileWallet = 'mobile_wallet';

  static const List<Map<String, dynamic>> paymentMethods = [
    {'value': paymentCash, 'label': 'نقدي'},
    {'value': paymentCard, 'label': 'بطاقة'},
    {'value': paymentMobileWallet, 'label': 'محفظة إلكترونية'},
  ];
}
