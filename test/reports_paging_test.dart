import 'package:flutter_test/flutter_test.dart';
import 'package:hesba/core/utils/paged_fetch.dart';

/// اختبارات ترقيم الصفحات (cursor pagination) المستخدم في جلب بيانات
/// التقارير الكامل — بلا قيود 300 وبدون تكرار أو سقوط بين الصفحات.
void main() {
  /// مصدر صفحات وهمي: يقسم [data] لصفحات [pageSize] ويعيد cursor = رقم
  /// آخر عنصر في الصفحة (يدمر عبر `nextCursor`) — نفس عقد `startAfterDocument`.
  ({
    Future<PageResult<int>> Function(Object? cursor) fetch,
    List<Object?> cursorsSeen,
  }) fakeSource(
    List<int> data, {
    int pageSize = 300,
    int? failAtPage,
    bool repeatCursor = false,
  }) {
    final cursorsSeen = <Object?>[];
    var calls = 0;
    Future<PageResult<int>> fetch(Object? cursor) async {
      cursorsSeen.add(cursor);
      calls++;
      final start = cursor == null ? 0 : (cursor as int) + 1;
      if (failAtPage != null && calls == failAtPage) {
        throw Exception('page failed');
      }
      if (start >= data.length) {
        return PageResult<int>(items: const [], cursor: null, hasMore: false);
      }
      final end = (start + pageSize).clamp(0, data.length);
      final items = data.sublist(start, end);
      // cursor = رقم آخر عنصر في الصفحة (index — زي startAfterDocument):
      // أو نفس الرقم لمحاكاة cursor عالق.
      final next = repeatCursor ? (cursor as int? ?? -1) : end - 1;
      return PageResult<int>(
        items: items,
        cursor: next,
        hasMore: end < data.length,
      );
    }

    return (fetch: fetch, cursorsSeen: cursorsSeen);
  }

  test('أكثر من 300 سجل عبر صفحتين: الكل مُجلب بلا قص', () async {
    final data = List.generate(350, (i) => i); // 350 سجل
    final src = fakeSource(data);
    final result = await fetchAllPages<int>(
      fetchPage: src.fetch,
      idOf: (v) => '$v',
    );

    expect(result.isComplete, isTrue);
    expect(result.items.length, 350);
    expect(result.items.toSet().length, 350); // لا تكرار
    expect(result.items.first, 0);
    expect(result.items.last, 349);
    // صفحتان فقط: cursor=null ثم cursor=299 (الصفحة الأخيرة تغلق نفسها).
    expect(src.cursorsSeen.first, isNull);
    expect(src.cursorsSeen.length, 2);
  });

  test('الإجماليات كاملة مستقلة عن أي ترقيم عرض (350 = مجموع كل الصفحات)',
      () async {
    final data = List.generate(350, (i) => i + 1); // 1..350
    final expected = data.fold<int>(0, (a, b) => a + b);
    final src = fakeSource(data);
    final result = await fetchAllPages<int>(
      fetchPage: src.fetch,
      idOf: (v) => '$v',
    );
    final total = result.items.fold<int>(0, (a, b) => a + b);
    expect(total, expected); // 61425
    expect(result.isComplete, isTrue);
  });

  test('عدد من مضاعفات حجم الصفحة ينتهي بلا حلقة لا نهائية', () async {
    final data = List.generate(600, (i) => i); // صفحتان ممتلئتان بالضبط
    final src = fakeSource(data, pageSize: 300);
    final result = await fetchAllPages<int>(
      fetchPage: src.fetch,
      idOf: (v) => '$v',
    );
    expect(result.items.length, 600);
    expect(result.isComplete, isTrue);
    // صفحتان ممتلئتان: [null, 299] — الصفحة الأخيرة تعود بـ hasMore=false.
    expect(src.cursorsSeen.length, 2);
  });

  test('cursor يتقدم بالترتيب الصحيح بين الصفحات', () async {
    final data = List.generate(700, (i) => i);
    final src = fakeSource(data, pageSize: 300);
    await fetchAllPages<int>(fetchPage: src.fetch, idOf: (v) => '$v');
    expect(src.cursorsSeen, [null, 299, 599]);
  });

  test('صفحات متداخلة (تكرار سجل على الحد) لا تُحتسب مرتين', () async {
    // محاكاة انزياح: الصفحة الثانية تعيد آخر سجل من الأولى.
    var page = 0;
    Future<PageResult<int>> fetch(Object? cursor) async {
      page++;
      if (page == 1) {
        return PageResult<int>(items: [1, 2, 3], cursor: 3, hasMore: true);
      }
      if (page == 2) {
        // تكرار العنصر 3 + عنصر جديد.
        return PageResult<int>(items: [3, 4], cursor: 4, hasMore: true);
      }
      return PageResult<int>(items: const [], cursor: null, hasMore: false);
    }

    final result = await fetchAllPages<int>(
      fetchPage: fetch,
      idOf: (v) => '$v',
    );
    expect(result.items, [1, 2, 3, 4]); // 3 مرة واحدة فقط
    expect(result.isComplete, isTrue);
  });

  test('cursor لا يتقدم → تقرير ناقص بدل حلقة لا نهائية', () async {
    final src = fakeSource(List.generate(1000, (i) => i), repeatCursor: true);
    final result = await fetchAllPages<int>(
      fetchPage: src.fetch,
      idOf: (v) => '$v',
    );
    expect(result.isComplete, isFalse); // لا نعرضه كمكتمل أبداً
    expect(result.items.length, lessThan(1000));
    expect(src.cursorsSeen.length, lessThan(10)); // توقف فعلاً
  });

  test('بلوغ حد الصفحات الأقصى → isComplete = false', () async {
    final data = List.generate(1500, (i) => i);
    final src = fakeSource(data, pageSize: 300);
    final result = await fetchAllPages<int>(
      fetchPage: src.fetch,
      idOf: (v) => '$v',
      maxPages: 3, // يتوقف بعد 900 سجل من 1500
    );
    expect(result.items.length, 900);
    expect(result.isComplete, isFalse);
  });

  test('فشل جلب صفحة يُرفع للصادر (لا إجماليات صامتة ناقصة)', () async {
    final src = fakeSource(List.generate(400, (i) => i), failAtPage: 2);
    await expectLater(
      fetchAllPages<int>(fetchPage: src.fetch, idOf: (v) => '$v'),
      throwsA(isA<Exception>()),
    );
  });

  test('مصدر فارغ → نتيجة فارغة مكتملة', () async {
    final src = fakeSource(const []);
    final result = await fetchAllPages<int>(
      fetchPage: src.fetch,
      idOf: (v) => '$v',
    );
    expect(result.items, isEmpty);
    expect(result.isComplete, isTrue);
  });

  test('سجلات بمعرّف فارغ لا تُفقد ولا تتكرر بلا دليل', () async {
    var page = 0;
    Future<PageResult<String>> fetch(Object? cursor) async {
      page++;
      if (page == 1) {
        return PageResult<String>(items: ['a', ''], cursor: 'x', hasMore: true);
      }
      return PageResult<String>(items: const [], cursor: null, hasMore: false);
    }

    final result = await fetchAllPages<String>(
      fetchPage: fetch,
      idOf: (s) => s,
    );
    expect(result.items, ['a', '']); // المعرّف الفارغ يُحفظ كما هو
    expect(result.isComplete, isTrue);
  });

  test('بدون idOf لا يحدث إزالة تكرار (سلوك افتراضي بسيط)', () async {
    final src = fakeSource(List.generate(350, (i) => i));
    final result = await fetchAllPages<int>(fetchPage: src.fetch);
    expect(result.items.length, 350);
    expect(result.isComplete, isTrue);
  });
}
