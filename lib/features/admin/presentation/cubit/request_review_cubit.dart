import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repos/admin_repo.dart';
import '../../../../features/subscription/data/models/subscription_request_model.dart';

abstract class RequestReviewState extends Equatable {
  const RequestReviewState();
  @override
  List<Object?> get props => [];
}

class ReviewIdle extends RequestReviewState {}

class ReviewLoading extends RequestReviewState {}

class ReviewDone extends RequestReviewState {
  const ReviewDone(this.approved);
  final bool approved;
  @override
  List<Object?> get props => [approved];
}

class ReviewError extends RequestReviewState {
  const ReviewError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class RequestReviewCubit extends Cubit<RequestReviewState> {
  RequestReviewCubit({required this.repo}) : super(ReviewIdle());
  final AdminRepo repo;

  Future<void> approve(SubscriptionRequestModel request) async {
    emit(ReviewLoading());
    try {
      await repo.approveRequest(request);
      emit(const ReviewDone(true));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> reject(SubscriptionRequestModel request, String reason) async {
    emit(ReviewLoading());
    try {
      await repo.rejectRequest(request, reason);
      emit(const ReviewDone(false));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }
}
