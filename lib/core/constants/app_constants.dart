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

  // Product categories per shop business type (dropdown). The customer picks
  // product sub-categories relative to the business type they chose during
  // registration (e.g. clothing shop -> t-shirt, pants, ...).
  // 'أخرى' (always last) reveals a free-text field.
  static const List<String> defaultProductCategories = ['عام', 'أخرى'];

  static const Map<String, List<String>> productCategoriesByBusinessType = {
    'سوبر ماركت': [
      'خضروات',
      'فواكه',
      'ألبان وأجبان',
      'مخبوزات',
      'معلبات',
      'مشروبات',
      'منظفات',
      'عناية شخصية',
      'حلويات ووجبات خفيفة',
      'أخرى',
    ],
    'بقالة': [
      'مشروبات',
      'معلبات',
      'خضروات',
      'فواكه',
      'ألبان',
      'مخبوزات',
      'منظفات',
      'حلويات ووجبات خفيفة',
      'أخرى',
    ],
    'محل خضروات': ['خضروات', 'فواكه', 'أعشاب', 'أخرى'],
    'محل فواكه': ['فواكه', 'خضروات', 'عصائر طازجة', 'أخرى'],
    'محل لحوم': ['لحوم طازجة', 'دواجن', 'مصنعات', 'أخرى'],
    'محل أسماك': ['أسماك', 'جمبري', 'قشريات', 'أخرى'],
    'صيدلية': [
      'أدوية',
      'مستحضرات تجميل',
      'عناية بالبشرة',
      'مكملات غذائية',
      'مستلزمات طبية',
      'أخرى',
    ],
    'محل ملابس': [
      'تيشيرت',
      'قميص',
      'بنطلون',
      'جينز',
      'جاكت',
      'فستان',
      'عباية',
      'ملابس أطفال',
      'ملابس داخلية',
      'أخرى',
    ],
    'محل إلكترونيات': [
      'موبايلات',
      'لاب توب',
      'سماعات',
      'شواحن',
      'أجهزة منزلية',
      'كاميرات',
      'أخرى',
    ],
    'محل عطور': ['عطور رجالي', 'عطور حريمي', 'بخاخات', 'زيوت عطرية', 'أخرى'],
    'محل أحذية': ['كوتشي', 'صنادل', 'حذاء رسمي', 'بوت', 'شبشب', 'أخرى'],
    'محل أدوات منزلية': ['أدوات مطبخ', 'أواني', 'كهربائيات', 'تنظيم وتخزين', 'أخرى'],
    'محل ورد': ['ورود', 'نباتات', 'سلال زهور', 'إكسسوارات ورد', 'أخرى'],
    'كافيه': ['قهوة', 'ساندوتشات', 'حلويات', 'مشروبات باردة', 'أخرى'],
    'مطعم': ['أطباق رئيسية', 'مقبلات', 'مشروبات', 'حلويات', 'أخرى'],
    'محل حلويات': ['كيك', 'بسكويت', 'شوكولاتة', 'حلويات شرقية', 'أخرى'],
    'محل حلاقة': ['أدوات حلاقة', 'مستحضرات عناية', 'ماكينات', 'أخرى'],
    'غير ذلك': ['عام', 'أخرى'],
  };

  // Product sizes (dropdown). 'أخرى' reveals a free-text field.
  static const List<String> productSizes = [
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    'موحد',
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
