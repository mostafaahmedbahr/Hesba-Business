import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/log_util.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/repos/accounts_repo.dart';
import '../states/debt_details_state.dart';

/// يدير شاشة كشف الحساب: ستريم المديونية وسجل الدفعات،
/// وتسجيل دفعة جديدة داخل transaction.
class DebtDetailsCubit extends Cubit<DebtDetailsState> {
  final AccountsRepo _repo;
  final String debtId;

  StreamSubscription<DebtModel?>? _debtSub;
  StreamSubscription<List<PaymentModel>>? _paymentsSub;

  DebtDetailsCubit({required this._repo, required this.debtId})
      : super(const DebtDetailsState());

  /// يشترك في المديونية وسجل الدفعات.
  void init({DebtModel? initial}) {
    if (initial != null) {
      emit(state.copyWith(status: DebtDetailsStatus.success, debt: initial));
    }

    _debtSub ??= _repo.watchDebt(debtId).listen(
      (debt) {
        if (debt == null) {
          // السجل الأصلي يفضل محفوظًا دائمًا — لو اختفى يبقى خطأ واضح.
          emit(state.copyWith(
            status: DebtDetailsStatus.failure,
            errorMessage: 'تعذر قراءة الحساب',
          ));
          return;
        }
        emit(state.copyWith(
          status: DebtDetailsStatus.success,
          debt: debt,
          clearError: true,
        ));
      },
      onError: (Object e) => emit(state.copyWith(
        status: DebtDetailsStatus.failure,
        errorMessage: '$e',
      )),
    );

    _paymentsSub ??= _repo.watchPayments(debtId).listen(
      (list) => emit(state.copyWith(payments: list)),
      onError: (Object e) => logWarning('[DebtDetailsCubit] payments: $e'),
    );
  }

  /// تسجيل دفعة (جزئي أو كامل) — يرجع true عند النجاح.
  Future<bool> addPayment({required double amount, String note = ''}) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.addPayment(debtId: debtId, amount: amount, note: note);
      emit(state.copyWith(saving: false));
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      logWarning('[DebtDetailsCubit] payment failed: $msg');
      emit(state.copyWith(saving: false, errorMessage: msg));
      return false;
    }
  }

  @override
  Future<void> close() {
    _debtSub?.cancel();
    _paymentsSub?.cancel();
    return super.close();
  }
}
