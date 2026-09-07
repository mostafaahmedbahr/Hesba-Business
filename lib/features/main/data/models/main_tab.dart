/// Represents the main bottom navigation tabs (data layer).
enum MainTab {
  home(0, 'الرئيسية'),
  products(1, 'المنتجات'),
  sales(2, 'المبيعات'),
  reports(3, 'التقارير'),
  more(4, 'المزيد');

  const MainTab(this.tabIndex, this.label);

  final int tabIndex;
  final String label;

  static MainTab fromIndex(int index) {
    return MainTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => MainTab.home,
    );
  }
}
