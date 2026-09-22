abstract class CategoryRepo {
  Stream<List<String>> watchCustomCategories(String shopId);
  Future<List<String>> getCustomCategories(String shopId);
  Future<void> addCategory(String shopId, String category);
  Future<void> removeCategory(String shopId, String category);
}
