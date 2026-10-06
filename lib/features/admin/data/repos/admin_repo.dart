import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../features/subscription/data/models/subscription_request_model.dart';
import '../models/admin_settings.dart';

abstract class AdminRepo {
  // Auth / access
  Future<bool> isAdmin();
  Stream<String?> watchUid();

  // Dashboard aggregates
  Future<int> countShops();
  Future<int> countActiveSubscriptions();
  Future<int> countTrialSubscriptions();
  Future<int> countExpiredSubscriptions();
  Future<int> countPendingRequests();
  Future<int> countProducts();
  Future<int> countSales();
  Future<int> countExpenses();
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingRequestsOnce();

  // Charts
  Future<Map<String, int>> subscriptionCountsByMonth({required int months});
  Future<Map<String, int>> shopsByMonth({required int months});
  Future<Map<String, int>> revenueByMonth({required int months});

  // Lists (paginated)
  Future<QuerySnapshot<Map<String, dynamic>>> getShopsPage({DocumentSnapshot? startAfter, String search = ''});
  Future<QuerySnapshot<Map<String, dynamic>>> getProductsPage({DocumentSnapshot? startAfter});
  Future<QuerySnapshot<Map<String, dynamic>>> getSalesPage({DocumentSnapshot? startAfter});
  Future<QuerySnapshot<Map<String, dynamic>>> getExpensesPage({DocumentSnapshot? startAfter});
  Future<QuerySnapshot<Map<String, dynamic>>> getSubscriptionsPage({DocumentSnapshot? startAfter, String? status});
  Future<QuerySnapshot<Map<String, dynamic>>> getRequestsPage({DocumentSnapshot? startAfter, String? status});

  // Details
  Future<DocumentSnapshot<Map<String, dynamic>>> getShop(String shopId);
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserSubscription(String userId);
  Future<SubscriptionRequestModel?> getRequest(String requestId);

  // Approve / reject
  Future<void> approveRequest(SubscriptionRequestModel request);
  Future<void> rejectRequest(SubscriptionRequestModel request, String reason);
  Future<void> appendActivity({required String action, required String description, Map<String, dynamic>? extra});

  // Settings
  Future<AdminSettings> getSettings();
  Future<void> saveSettings(AdminSettings settings);
}
