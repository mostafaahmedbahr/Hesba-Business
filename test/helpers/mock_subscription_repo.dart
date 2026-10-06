import 'package:image_picker/image_picker.dart';

import 'package:hesba/features/subscription/data/models/subscription_model.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';
import 'package:hesba/features/subscription/data/models/subscription_request_model.dart';
import 'package:hesba/features/subscription/data/repos/subscription_repo.dart';

/// In-memory [SubscriptionRepo] so the cubit can be driven without Firebase.
class MockSubscriptionRepo implements SubscriptionRepo {
  MockSubscriptionRepo({SubscriptionModel? initial})
      : _subscription = initial ?? SubscriptionModel.trialFor(
          createdAt: DateTime.now(),
        );

  SubscriptionModel _subscription;
  SubscriptionRequestModel? lastRequest;

  int getCalls = 0;
  int uploadCalls = 0;
  bool failLoad = false;
  bool failUpload = false;
  bool failSubmit = false;
  bool uploadReturnsNull = false;

  @override
  SubscriptionModel? get cached => _subscription;

  @override
  Future<SubscriptionModel> getSubscription({bool refresh = false}) async {
    getCalls++;
    if (failLoad) throw Exception('offline');
    return _subscription;
  }

  @override
  Stream<SubscriptionModel> watchSubscription() async* {
    yield _subscription;
  }

  @override
  Future<void> startTrialForNewUser({
    required String userId,
    required DateTime createdAt,
  }) async {
    _subscription = SubscriptionModel.trialFor(createdAt: createdAt);
  }

  @override
  Future<String?> uploadPaymentReceipt({required ImageSource source}) async {
    uploadCalls++;
    if (failUpload) throw Exception('upload failed');
    if (uploadReturnsNull) return null;
    return 'https://res.cloudinary.com/demo/image/upload/v1/receipt.jpg';
  }

  @override
  Future<SubscriptionRequestModel> submitRequest({
    required SubscriptionPlan plan,
    required SubscriptionPaymentMethod paymentMethod,
    required String paymentProofUrl,
  }) async {
    if (failSubmit) throw Exception('submit failed');
    final request = SubscriptionRequestModel(
      requestId: 'req_1',
      userId: 'uid_1',
      ownerName: 'Owner',
      shopName: 'Shop',
      phone: '01000000000',
      plan: plan,
      amount: plan.price,
      paymentMethod: paymentMethod.id,
      paymentProofUrl: paymentProofUrl,
      status: SubscriptionRequestModel.statusPending,
      createdAt: DateTime.now(),
    );
    lastRequest = request;
    _subscription = _subscription.copyWith(
      status: SubscriptionStatus.pending,
      lastRequestId: request.requestId,
    );
    return request;
  }

  @override
  Future<SubscriptionRequestModel?> getRequest(String requestId) async {
    return lastRequest;
  }

  void setSubscription(SubscriptionModel subscription) {
    _subscription = subscription;
  }
}
