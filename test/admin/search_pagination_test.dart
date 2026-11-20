import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/utils/search_tokens.dart';
import 'package:hesba/features/admin/data/repos_impl/admin_search_repo_impl.dart';
import 'package:hesba/features/admin/presentation/cubit/global_search_cubit.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminSearchRepoImpl repo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    // 30 محل مطابق، كلهم بـ searchTokens مفهرسة — المطلوب في المركز 25.
    for (var i = 0; i < 30; i++) {
      await firestore.collection('shops').doc('shop_${i.toString().padLeft(3, '0')}').set({
        'shopName': 'TARGET محل $i',
        'searchTokens': SearchTokens.shop(shopName: 'TARGET محل $i'),
      });
    }
    repo = AdminSearchRepoImpl(
      firestore: firestore,
      batchSize: 10,
      pageSize: 10,
    );
  });

  test('indexed first page returns a bounded page and reports hasMore', () async {
    final page = await repo.searchPage('target');

    expect(page.hits, hasLength(10));
    expect(page.hasMore, isTrue);
    expect(page.nextCursor!.shops.scanned, 10);
  });

  test('pages continue from the cursor and reach a far document', () async {
    var page = await repo.searchPage('target');
    final ids = <String>[];
    var guard = 0;

    while (page.hasMore && !ids.contains('shop_025') && guard++ < 10) {
      ids.addAll(page.hits.map((h) => h.id));
      page = await repo.searchPage('target', cursor: page.nextCursor);
    }
    ids.addAll(page.hits.map((h) => h.id));

    expect(ids, contains('shop_025'));
  });

  test('cubit loadMore appends results without restarting the scan', () async {
    final cubit = GlobalSearchCubit(searchRepo: repo);
    cubit.search('target');
    await Future<void>.delayed(const Duration(milliseconds: 450));

    var state = cubit.state as SearchResults;
    expect(state.hits, hasLength(10));
    expect(state.hasMore, isTrue);

    await cubit.loadMore();
    state = cubit.state as SearchResults;
    expect(state.hits, hasLength(20));

    await cubit.close();
  });
}
