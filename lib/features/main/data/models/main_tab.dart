/// Represents the main bottom navigation tabs (data layer) - 4 items only.
/// Sales+Returns grouped, Reports+Expenses grouped, rest moved to Drawer.
enum MainTab {
  home(0, 'navHome'),
  products(1, 'navProducts'),
  sales(2, 'navSales'),
  reports(3, 'navReports');

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