import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/utils/search_tokens.dart';
import 'package:hesba/features/admin/data/repos_impl/admin_search_repo_impl.dart';

void main() {
  group('SearchTokens', () {
    test('normalizes Arabic and Persian numerals to Latin', () {
      expect(SearchTokens.normalize('٠١٢ ۳۴۵'), '012 345');
    });

    test('generates substrings of the whole text and each word', () {
      final tokens = SearchTokens.of('محل النور');

      expect(tokens, contains('محل'));
      expect(tokens, contains('النور'));
      expect(tokens, contains('محل النور'));
      expect(tokens, contains('نور'));
    });

    test('generates phone digits after normalization', () {
      expect(SearchTokens.phone('٠١٠-٢٣٤٥٦٧٨'), contains('0102345678'));
    });
  });

  group('indexed search', () {
    late FakeFirebaseFirestore firestore;
    late AdminSearchRepoImpl repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = AdminSearchRepoImpl(firestore: firestore);
    });

    test('finds a shop by a token stored at write time', () async {
      await firestore.collection('shops').doc('s1').set({
        'shopName': 'محل النور',
        'searchTokens': SearchTokens.shop(
          shopName: 'محل النور',
          phone: '٠١٠٢٣٤٥٦٧٨',
        ),
      });

      final byName = await repo.searchPage('النور');
      final byPhone = await repo.searchPage('010234');

      expect(byName.hits.single.id, 's1');
      expect(byPhone.hits.single.id, 's1');
    });

    test('backfill adds tokens to legacy documents only once', () async {
      await firestore.collection('shops').doc('old').set({'shopName': 'محل قديم'});

      final first = await repo.backfillSearchTokens();
      final second = await repo.backfillSearchTokens();

      expect(first, 1);
      expect(second, 0);
      final doc = await firestore.collection('shops').doc('old').get();
      expect(doc.data()?['searchTokens'], contains('قديم'));
    });
  });
}
