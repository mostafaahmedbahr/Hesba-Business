import 'package:easy_localization/easy_localization.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../data/models/supplier_model.dart';
import '../cubit/supplier_details_cubit.dart';
import '../states/supplier_details_state.dart';
import '../widgets/supplier_delete_dialog.dart';
import 'supplier_form_view.dart';
import '../../../subscription/presentation/subscription_gate.dart';
import '../widgets/supplier_details/action_buttons.dart';
import '../widgets/supplier_details/details_app_bar.dart';
import '../widgets/supplier_details/error_body.dart';
import '../widgets/supplier_details/info_card.dart';
import '../widgets/supplier_details/linked_products_section.dart';
import '../widgets/supplier_details/notes_section.dart';

/// شاشة تفاصيل المورد: البيانات + المنتجات المرتبطة + الملاحظات + الأزرار.
class SupplierDetailsView extends StatelessWidget {
  final String supplierId;
  const SupplierDetailsView({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupplierDetailsCubit(repo: sl())..load(supplierId),
      child: const _SupplierDetailsBody(),
    );
  }
}

class _SupplierDetailsBody extends StatelessWidget {
  const _SupplierDetailsBody();

  Future<void> _openEdit(BuildContext context) async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final supplier = context.read<SupplierDetailsCubit>().state.supplier;
    if (supplier == null) return;
    final updated = await Navigator.push<SupplierModel>(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormView(existing: supplier)),
    );
    if (updated != null && context.mounted) {
      await context.read<SupplierDetailsCubit>().load(supplier.id);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<SupplierDetailsCubit>();
    final supplier = cubit.state.supplier;
    if (supplier == null) return;
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => SupplierDeleteDialog(name: supplier.displayName),
    );
    if (ok != true || !context.mounted) return;

    final deleted = await cubit.delete();
    if (!context.mounted) return;
    if (deleted) {
      AppToast.success(context, 'supplierDeleted'.tr());
      Navigator.pop(context, true);
    } else {
      // عادةً: المورد مرتبط بمنتجات ولا يمكن حذفه.
      AppToast.error(context, translateError(cubit.state.errorMessage));
    }
  }

  Future<void> _saveNotes(BuildContext context, String notes) async {
    final cubit = context.read<SupplierDetailsCubit>();
    if (cubit.state.busy) return;
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final saved = await cubit.saveNotes(notes);
    if (!context.mounted) return;
    if (saved) {
      AppToast.success(context, 'supplierNotesSaved'.tr());
    } else {
      AppToast.error(context, translateError(cubit.state.errorMessage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierDetailsCubit, SupplierDetailsState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (state.status == SupplierDetailsStatus.loading) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: SupplierDetailsAppBar(
              supplier: null,
              onEdit: () {},
              onDelete: () {},
            ),
            body: const LoadingWidget(),
          );
        }
        final supplier = state.supplier;
        if (supplier == null || state.status == SupplierDetailsStatus.failure) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: SupplierDetailsAppBar(
              supplier: null,
              onEdit: () {},
              onDelete: () {},
            ),
            body: SupplierDetailsErrorBody(
              errorMessage: state.errorMessage,
              onRetry: () => context
                  .read<SupplierDetailsCubit>()
                  .load(supplier?.id ?? ''),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: SupplierDetailsAppBar(
            supplier: supplier,
            onEdit: () => _openEdit(context),
            onDelete: () => _confirmDelete(context),
          ),
          body: RefreshIndicator(
            color: AppTheme.violetDeep,
            onRefresh: () =>
                context.read<SupplierDetailsCubit>().load(supplier.id),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SupplierInfoCard(supplier: supplier, isDark: isDark),
                  SizedBox(height: 14.h),
                  SupplierLinkedProductsSection(state: state, isDark: isDark),
                  SizedBox(height: 14.h),
                  SupplierNotesSection(
                    state: state,
                    isDark: isDark,
                    onSave: (notes) => _saveNotes(context, notes),
                  ),
                  SizedBox(height: 18.h),
                  SupplierActionButtons(
                    supplier: supplier,
                    isDark: isDark,
                    onEdit: () => _openEdit(context),
                    onDelete: () => _confirmDelete(context),
                    busy: state.busy,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
