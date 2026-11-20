/// كلمات بحث مفهرسة لـ Firestore (بدل مسح كل المستندات client-side).
///
/// Firestore مفيهاش فهرس substring، فبنخزّن في كل مستند مصفوفة بكل
/// المقاطع الممكنة للنص الموحّد؛ البحث بقى `arrayContains` على كلمة واحدة
/// وبرجّع بس المستندات المطابقة — قراءة واحدة لكل نتيجة بدل آلاف القراءات.
class SearchTokens {
  SearchTokens._();

  /// أقصى طول مقطع (الكلمات الطويلة جداً مش محتاجة كل مقاطعها).
  static const int _maxTokenLength = 20;

  /// سقف آمن لعدد الـ tokens في الحقل الواحد (حد مستند Firestore 1MB).
  static const int _maxTokensPerField = 400;

  /// توحيد النص: trim + lowercase + تحويل الأرقام العربية/الفارسية للاتينية.
  static String normalize(Object? value) {
    if (value == null) return '';
    var s = value.toString().trim().toLowerCase();
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      final ai = arabicIndic.indexOf(ch);
      if (ai != -1) {
        buffer.write(ai);
        continue;
      }
      final ea = easternArabic.indexOf(ch);
      if (ea != -1) {
        buffer.write(ea);
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  /// كل مقاطع النص (من مقطع واحد للنص كله) — بيغطي البحث في أي مكان بالكلمة.
  static List<String> of(Object? value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return const [];
    final tokens = <String>{};
    _addSubstrings(normalized, tokens);
    // مقاطع كل كلمة لوحدها عشان "النور" تتلاقى جوّه "محل النور".
    for (final word in normalized.split(RegExp(r'\s+'))) {
      if (word.isNotEmpty) _addSubstrings(word, tokens);
    }
    return tokens.take(_maxTokensPerField).toList();
  }

  /// مقاطع أرقام التليفون بعد تجريدها من كل ما عدا الأرقام.
  static List<String> phone(Object? value) {
    final digits = normalize(value).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const [];
    final tokens = <String>{};
    _addSubstrings(digits, tokens);
    return tokens.take(_maxTokensPerField).toList();
  }

  /// tokens مخزن/محل — بيطابق الحقول اللي بيبحث فيها بحث الأدمن.
  static List<String> shop({
    required String shopName,
    String? ownerName,
    String? phone,
  }) =>
      <String>{
        ...of(shopName),
        ...of(ownerName),
        ...SearchTokens.phone(phone),
      }.toList();

  static List<String> product(String name) => of(name);

  static List<String> subscriptionRequest({
    required String shopName,
    String? ownerName,
    String? phone,
  }) =>
      shop(shopName: shopName, ownerName: ownerName, phone: phone);

  /// كلمة البحث نفسها بعد التوحيد — هي الـ token اللي بنسأل عنه في Firestore.
  static String queryToken(String query) => normalize(query);

  static void _addSubstrings(String value, Set<String> out) {
    final limit = value.length < _maxTokenLength ? value.length : _maxTokenLength;
    for (var start = 0; start < limit; start++) {
      for (var end = start + 1; end <= limit; end++) {
        out.add(value.substring(start, end));
      }
    }
  }
}
