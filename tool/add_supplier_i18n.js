// One-off helper: append supplier localization keys to ar.json / en.json
// without disturbing the existing formatting. Safe to re-run.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');

const en = {
  suppliersSection: 'Suppliers',
  suppliersTitle: 'Suppliers',
  suppliersAdd: 'Add supplier',
  suppliersAddNew: 'Add new supplier',
  suppliersEdit: 'Edit supplier',
  suppliersDetails: 'Supplier details',
  suppliersCancel: 'Cancel',
  suppliersSaving: 'Saving...',
  suppliersSaveChanges: 'Save changes',
  suppliersRetry: 'Retry',
  suppliersLoading: 'Loading suppliers...',
  suppliersCountLabel: 'Total suppliers',
  suppliersCountZero: 'No suppliers yet',
  suppliersCountPill: '{} suppliers',
  suppliersSearchHint: 'Search by name, company or phone',
  suppliersEmptyTitle: 'No suppliers yet',
  suppliersEmptySubtitle: 'Add your first supplier and link it to your products',
  suppliersNoResultsTitle: 'No results found',
  suppliersNoResultsSubtitle: 'Try another search word',
  suppliersClearSearch: 'Clear search',

  supplierCall: 'Call',
  supplierWhatsApp: 'WhatsApp',
  supplierCopyPhone: 'Copy number',
  supplierPhoneCopied: 'Phone number copied',
  supplierContactFailed: "Couldn't open the dialer",
  supplierDelete: 'Delete',
  supplierDeleteTitle: 'Delete supplier?',
  supplierDeleteBody: 'Are you sure you want to delete "{0}"? This cannot be undone.',
  supplierDeleted: 'Supplier deleted',

  supplierFormSectionMain: 'Supplier information',
  supplierFieldLabelName: 'Supplier name',
  supplierFieldLabelPhone: 'Phone number',
  supplierFieldLabelCompany: 'Company name',
  supplierFieldLabelSecondaryPhone: 'Secondary phone',
  supplierFieldLabelEmail: 'Email',
  supplierFieldLabelAddress: 'Address',
  supplierFieldLabelCity: 'City',
  supplierFieldLabelNotes: 'Notes',
  supplierFieldHintName: 'e.g. Ahmed Abdallah',
  supplierFieldHintPhone: 'e.g. 01001112223',
  supplierFieldHintCompany: 'e.g. El-Nour Supplies',
  supplierFieldHintSecondaryPhone: 'Optional second number',
  supplierFieldHintEmail: 'example@email.com',
  supplierFieldHintAddress: 'e.g. 12 El-Tahrir St.',
  supplierFieldHintCity: 'e.g. Cairo',
  supplierFieldHintNotes: 'Any general info about this supplier',

  supplierLinkedProducts: 'Linked products',
  supplierLinkedCount: '{} linked products',
  supplierNoLinkedProducts: 'No products linked to this supplier',
  supplierNoLinkedProductsHint: 'Link products to this supplier from the product form',
  supplierNotesLabel: 'General notes',
  supplierNotesHint: 'Add your notes about this supplier here',
  supplierNotesSave: 'Save notes',
  supplierNotesSaved: 'Notes saved',

  supplierPickerTitle: 'Choose supplier',
  supplierPickerHint: 'Search by name, company or number',
  supplierPickerClear: 'No supplier',
  supplierPickerClearHint: 'Remove the supplier from this product',
  supplierPickerEmpty: 'No suppliers',
  supplierPickerEmptyHint: 'Add a supplier first to link it to your products',

  supplierProductSection: 'Supplier',
  supplierProductHint: 'Optional - choose a supplier for this product',
  supplierProductLinked: 'This product is linked to a supplier',
  supplierProductOptional: 'No supplier selected - this is optional',
  supplierProductView: 'View supplier',
  supplierProductPrice: 'Sale: {}',
  supplierProductStock: 'Stock: {}',

  supplierErrNameRequired: 'Please enter the supplier name',
  supplierErrPhoneRequired: 'Please enter the supplier phone number',
  supplierErrPhoneInvalid: 'The phone number must be 7 to 15 digits',
  supplierErrDuplicatePhone: 'Another supplier in your shop already uses this number',
  supplierErrNotFound: 'Supplier not found',
  supplierErrNotAuthorized: "You can't modify a supplier from another shop",
  supplierErrNotSignedIn: 'Please sign in first',
  supplierErrNoShop: 'No shop is linked to this account',
  supplierErrLinkedProducts: 'This supplier is linked to products and cannot be deleted',
};

const ar = {
  suppliersSection: 'الموردين',
  suppliersTitle: 'الموردين',
  suppliersAdd: 'إضافة مورد',
  suppliersAddNew: 'إضافة مورد جديد',
  suppliersEdit: 'تعديل المورد',
  suppliersDetails: 'تفاصيل المورد',
  suppliersCancel: 'إلغاء',
  suppliersSaving: 'جاري الحفظ...',
  suppliersSaveChanges: 'حفظ التعديلات',
  suppliersRetry: 'إعادة المحاولة',
  suppliersLoading: 'جاري تحميل الموردين...',
  suppliersCountLabel: 'إجمالي الموردين',
  suppliersCountZero: 'لا يوجد موردون حتى الآن',
  suppliersCountPill: '{} مورد',
  suppliersSearchHint: 'ابحث بالاسم أو الشركة أو رقم الهاتف',
  suppliersEmptyTitle: 'لا يوجد موردون حتى الآن',
  suppliersEmptySubtitle: 'أضف أول مورد واربطه بمنتجاتك',
  suppliersNoResultsTitle: 'لا توجد نتائج',
  suppliersNoResultsSubtitle: 'جرّب كلمة بحث تانية',
  suppliersClearSearch: 'مسح البحث',

  supplierCall: 'اتصال',
  supplierWhatsApp: 'واتساب',
  supplierCopyPhone: 'نسخ الرقم',
  supplierPhoneCopied: 'تم نسخ رقم الهاتف',
  supplierContactFailed: 'مقدرناش نفتح الهاتف',
  supplierDelete: 'حذف',
  supplierDeleteTitle: 'حذف المورد؟',
  supplierDeleteBody: 'متأكد إنك عايز تحذف "{0}"؟ ده مش هيتراجع.',
  supplierDeleted: 'تم حذف المورد',

  supplierFormSectionMain: 'بيانات المورد',
  supplierFieldLabelName: 'اسم المورد',
  supplierFieldLabelPhone: 'رقم الهاتف',
  supplierFieldLabelCompany: 'اسم الشركة',
  supplierFieldLabelSecondaryPhone: 'رقم إضافي',
  supplierFieldLabelEmail: 'البريد الإلكتروني',
  supplierFieldLabelAddress: 'العنوان',
  supplierFieldLabelCity: 'المدينة',
  supplierFieldLabelNotes: 'ملاحظات',
  supplierFieldHintName: 'مثال: أحمد عبد الله',
  supplierFieldHintPhone: 'مثال: 01001112223',
  supplierFieldHintCompany: 'مثال: شركة النور للتوريدات',
  supplierFieldHintSecondaryPhone: 'رقم تاني لو موجود',
  supplierFieldHintEmail: 'example@email.com',
  supplierFieldHintAddress: 'مثال: شارع التحرير 12',
  supplierFieldHintCity: 'مثال: القاهرة',
  supplierFieldHintNotes: 'أي معلومات عامة عن المورد',

  supplierLinkedProducts: 'المنتجات المرتبطة',
  supplierLinkedCount: '{} منتج مرتبط',
  supplierNoLinkedProducts: 'لا توجد منتجات مرتبطة بهذا المورد',
  supplierNoLinkedProductsHint: 'اربط المنتجات بالمورد من نموذج إضافة المنتج',
  supplierNotesLabel: 'ملاحظات عامة',
  supplierNotesHint: 'اكتب ملاحظاتك عن المورد هنا',
  supplierNotesSave: 'حفظ الملاحظات',
  supplierNotesSaved: 'تم حفظ الملاحظات',

  supplierPickerTitle: 'اختر المورد',
  supplierPickerHint: 'ابحث بالاسم أو الشركة أو الرقم',
  supplierPickerClear: 'بدون مورد',
  supplierPickerClearHint: 'شيل المورد من المنتج ده',
  supplierPickerEmpty: 'مفيش موردين',
  supplierPickerEmptyHint: 'أضف مورد الأول عشان تربطه بمنتجاتك',

  supplierProductSection: 'المورد',
  supplierProductHint: 'اختياري - اختار مورد للمنتج ده',
  supplierProductLinked: 'المنتج ده مرتبط بمورد',
  supplierProductOptional: 'مفيش مورد محدد - الحقل اختياري',
  supplierProductView: 'عرض المورد',
  supplierProductPrice: 'بيع: {}',
  supplierProductStock: 'المخزون: {}',

  supplierErrNameRequired: 'من فضلك اكتب اسم المورد',
  supplierErrPhoneRequired: 'من فضلك اكتب رقم هاتف المورد',
  supplierErrPhoneInvalid: 'رقم الهاتف لازم يكون من 7 لـ 15 رقماً',
  supplierErrDuplicatePhone: 'فيه مورد تاني في نفس المحل بالرقم ده',
  supplierErrNotFound: 'المورد غير موجود',
  supplierErrNotAuthorized: 'ممنوع تعديل مورد تبع محل تاني',
  supplierErrNotSignedIn: 'لازم تسجّل دخول الأول',
  supplierErrNoShop: 'مفيش محل مرتبط بالحساب ده',
  supplierErrLinkedProducts: 'المورد مرتبط بمنتجات ولا يمكن حذفه',
};

const missing = [];
for (const key of Object.keys(en)) {
  if (!(key in ar)) missing.push(`ar missing: ${key}`);
}
for (const key of Object.keys(ar)) {
  if (!(key in en)) missing.push(`en missing: ${key}`);
}
if (missing.length) {
  console.error(missing.join('\n'));
  process.exit(1);
}

function merge(file, additions) {
  const full = path.join(root, 'assets', 'translations', file);
  const raw = fs.readFileSync(full, 'utf8');
  const obj = JSON.parse(raw);
  const before = Object.keys(obj).length;
  // Existing keys win (never clobber a hand-tuned translation) and keep
  // their position so the file diff stays readable.
  const merged = { ...obj };
  for (const [key, value] of Object.entries(additions)) {
    if (!(key in merged)) merged[key] = value;
  }
  const after = Object.keys(merged).length;
  const trailingNewline = raw.endsWith('\n') ? '\n' : '';
  fs.writeFileSync(full, JSON.stringify(merged, null, 2) + trailingNewline, 'utf8');
  console.log(`${file}: ${before} -> ${after} keys`);
}

merge('en.json', en);
merge('ar.json', ar);
