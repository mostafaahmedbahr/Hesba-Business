import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/core/router/app_routes.dart';
import 'package:hesba/core/services/user_role_service.dart';
import 'package:hesba/features/splash/presentation/views/splash_view.dart';
import 'package:hesba/features/auth/presentation/views/login_view.dart';
import 'package:hesba/features/auth/presentation/views/register_view.dart';
import 'package:hesba/features/main/presentation/views/main_layout.dart';

import '../../features/sales/presentation/views/add_sale_view.dart';
import '../../features/returns/presentation/views/add_return_view.dart';
import '../../features/returns/presentation/views/returns_view.dart';
import '../../features/expenses/presentation/views/expenses_view.dart';
import '../../features/expenses/presentation/views/add_expense_view.dart';
import '../../features/subscription/presentation/views/subscription_view.dart';
import '../../features/notifications/presentation/views/notifications_view.dart';
import '../../features/suppliers/presentation/views/suppliers_view.dart';
import '../../features/accounts/presentation/views/accounts_view.dart';
import '../../features/products/presentation/views/add_stock_purchase_view.dart';
import '../../features/sales/presentation/views/customer_sales_view.dart';
import '../../features/staff/presentation/views/staff_home_view.dart';
import '../../features/staff/presentation/views/staff_management_view.dart';

/// Root navigator used to route the user when they tap a notification while
/// the app is in the background or was terminated.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Route guard: protected screens require a signed-in user. Without this,
    // back-gesture/deep-link/notification taps could open them after logout
    // or with an expired token.
    if (_requiresAuth(settings.name) &&
        sl<FirebaseAuth>().currentUser == null) {
      return _buildRoute(const LoginView(), settings);
    }

    // أمان: مستخدم مسجّل لكن دوره غير معروف (فشل قراءة مستند users/{uid})
    // لا يفتح أي مسار محمي — شاشة البداية تقرر: إعادة المحاولة أو تسجيل الخروج.
    // (ممنوع افتراض دور "مالك" عند فشل القراءة).
    if (sl<FirebaseAuth>().currentUser != null &&
        !sl<UserRoleService>().isLoaded &&
        settings.name != AppRoutes.splash &&
        settings.name != AppRoutes.login &&
        settings.name != AppRoutes.register) {
      return _buildRoute(const SplashView(), settings);
    }

    // الحساب الفرعي محصور في شاشة الإدخال + فورمات الإضافة فقط.
    // أي مسار آخر (لوحة تحكم/تقارير/منتجات/حسابات/موردين) يُعاد توجيهه.
    if (sl<UserRoleService>().isStaff &&
        settings.name != null &&
        !_staffAllowedRoutes.contains(settings.name)) {
      return _buildRoute(const StaffHomeView(), settings);
    }

    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashView(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginView(), settings);

      case AppRoutes.register:
        return _buildRoute(const RegisterView(), settings);

      case AppRoutes.dashboard:
        final dArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          MainLayout(initialTab: dArgs?['initialTab'] as int?),
          settings,
        );
      case AppRoutes.addSaleView:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          AddSaleView(
            ownerId: args?['ownerId'] as String?,
            shopId: args?['shopId'] as String?,
          ),
          settings,
        );
      case AppRoutes.returnsView:
        return _buildRoute(const ReturnsView(), settings);
      case AppRoutes.addReturnView:
        final rArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          AddReturnView(
            ownerId: rArgs?['ownerId'] as String?,
            shopId: rArgs?['shopId'] as String?,
            originalSaleId: rArgs?['originalSaleId'] as String?,
          ),
          settings,
        );
      case AppRoutes.expensesView:
        final eArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ExpensesView(shopId: eArgs?['shopId'] as String? ?? ''),
          settings,
        );
      case AppRoutes.addExpenseView:
        final aeArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          AddExpenseView(
            ownerId: aeArgs?['ownerId'] as String?,
            shopId: aeArgs?['shopId'] as String?,
            shopName: aeArgs?['shopName'] as String?,
          ),
          settings,
        );
      case AppRoutes.subscription:
        return _buildRoute(const SubscriptionView(), settings);

      case AppRoutes.notifications:
        return _buildRoute(const NotificationsView(), settings);

      case AppRoutes.suppliersView:
        return _buildRoute(const SuppliersView(), settings);

      case AppRoutes.accountsView:
        return _buildRoute(const AccountsView(), settings);

      case AppRoutes.stockPurchaseView:
        return _buildRoute(const AddStockPurchaseView(), settings);

      case AppRoutes.customerSalesView:
        final csArgs = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          CustomerSalesView(
            personId: csArgs?['personId'] as String? ?? '',
            personName: csArgs?['personName'] as String? ?? '',
            personPhone: csArgs?['personPhone'] as String? ?? '',
            shopId: csArgs?['shopId'] as String? ?? '',
          ),
          settings,
        );

      case AppRoutes.staffHome:
        return _buildRoute(const StaffHomeView(), settings);

      case AppRoutes.staffManagement:
        return _buildRoute(const StaffManagementView(), settings);

      // case AppRoutes.resetPassword:
      //   return _buildRoute(const ResetPasswordScreen(), settings);

      default:
        return _buildRoute(const SplashView(), settings);
    }
  }

  /// المسارات الوحيدة المسموحة لحساب الموظف. أي شيء آخر يُحوَّل لشاشته.
  static const Set<String> _staffAllowedRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.staffHome,
    AppRoutes.addSaleView,
    AppRoutes.addReturnView,
    AppRoutes.addExpenseView,
    AppRoutes.stockPurchaseView,
  };

  static bool _requiresAuth(String? name) {
    switch (name) {
      case AppRoutes.staffHome:
      case AppRoutes.staffManagement:
      case AppRoutes.dashboard:
      case AppRoutes.addSaleView:
      case AppRoutes.returnsView:
      case AppRoutes.addReturnView:
      case AppRoutes.expensesView:
      case AppRoutes.addExpenseView:
      case AppRoutes.stockPurchaseView:
      case AppRoutes.subscription:
      case AppRoutes.notifications:
      case AppRoutes.suppliersView:
      case AppRoutes.accountsView:
      case AppRoutes.customerSalesView:
        return true;
      default:
        return false;
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
