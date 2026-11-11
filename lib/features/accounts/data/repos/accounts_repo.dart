import '../models/debt_model.dart';
import '../models/payment_model.dart';
import '../models/person_model.dart';

/// عمليات ميزة الحسابات (ذمم العملاء والموردين + قاعدة الأشخاص).
abstract class AccountsRepo {
  /// القائمة الحيّة لكل المديونيات في المحل (الاتجاهان والطرفان).
  Stream<List<DebtModel>> watchDebts();

  /// القائمة الحيّة لكل الأشخاص المحفوظين في المحل — تُستخدم في
  /// اقتراحات الاسم/الرقم أثناء كتابة بيانات الطرف.
  Stream<List<PersonModel>> watchPersons();

  /// بحث عن أشخاص (يُستخدم في قائمة الاختيار).
  Future<List<PersonModel>> searchPersons(String query);

  /// إضافة مديونية جديدة.
  ///
  /// لو الرقم مسجّل لشخص قائم → يُعاد استخدام نفس السجل (بدون تكرار)،
  /// ويُرقّى نوعه لو لزم (عميل ↔ مورد = both). لو الاسم تغيّر والرقم
  /// واحد → تُحدَّث لقطة الاسم في المديونية فقط.
  ///
  /// لو الرقم جديد → يُنشأ شخص وحفظه للاستخدام مستقبلًا.
  Future<DebtModel> addDebt({
    required String name,
    required String phone,
    required String partyType,
    required String direction,
    required double amount,
    String note = '',
  });

  /// يجد جهة اتصال بنفس الرقم داخل المحل أو ينشئها، ويدمج النوع لو لزم.
  ///
  /// نفس سياسة منع التكرار في المديونيات: نفس الرقم الموحّد = نفس
  /// الشخص. الرقم موجود → يُستخدم سجله (والنوع يُرقّى لـ both لو لزم).
  /// الرقم جديد → يُنشأ شخص ويُحفظ للاستخدام مستقبلًا.
  ///
  /// يُستخدم من تسجيل المبيعات لربط الفاتورة بجهة الاتصال بدون تكرار.
  Future<PersonModel> findOrCreatePerson({
    required String name,
    required String phone,
    required String partyType,
  });

  /// تسجيل دفعة على مديونية — transaction ذرّية:
  /// تنشئ مستند الدفعة وتحدّث paidAmount، وترفض الدفع الزائد عن
  /// المتبقي. لو الدفعة غطّت المتبقي بالكامل تتغيّر الحالة مشتقّةً
  /// إلى "مدفوع"، والسجل الأصلي يفضل محفوظًا.
  Future<void> addPayment({
    required String debtId,
    required double amount,
    String note = '',
  });

  /// ستريم مديونية واحدة (للتحديث الحيّ في شاشة كشف الحساب).
  Stream<DebtModel?> watchDebt(String debtId);

  /// ستريم كل الدفعات على مديونية (الأحدث أولًا).
  Stream<List<PaymentModel>> watchPayments(String debtId);
}
