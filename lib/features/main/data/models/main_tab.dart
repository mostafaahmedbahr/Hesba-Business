/// Represents the main bottom navigation tabs (data layer).
enum MainTab {
  home(0, 'navHome'),
  products(1, 'navProducts'),
  sales(2, 'navSales'),
  reports(3, 'navReports'),
  more(4, 'navMore');

  const MainTab(this.tabIndex, this.labelKey);

  final int tabIndex;

  /// Translation key for the tab label.
  final String labelKey;

  static MainTab fromIndex(int index) {
    return MainTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => MainTab.home,
    );
  }
}