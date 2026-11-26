import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../../../../common_imports.dart';
import '../../../../core/utils/error_message.dart';
import '../../data/models/supplier_model.dart';
import '../cubit/suppliers_cubit.dart';
import '../states/suppliers_state.dart';
import '../widgets/supplier_contact.dart';
import '../widgets/supplier_delete_dialog.dart';
import '../widgets/supplier_list_card.dart';
import '../widgets/supplier_list_header.dart';
import '../widgets/supplier_list_placeholders.dart';
import '../widgets/supplier_list_search.dart';
import 'supplier_details_view.dart';
import 'supplier_form_view.dart';
import '../../../subscription/presentation/subscription_gate.dart';

/// شاشة الموردين (عرض بس — اللوجيك في Cubit).
class SuppliersView extends StatelessWidget {
  const SuppliersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuppliersCubit(repo: sl())..init(),
      child: const _SuppliersBody(),
    );
  }
}

/// هيكل الشاشة (FAB + حالات + محتوى).
class _SuppliersBody extends StatelessWidget {
  const _SuppliersBody();

  /// يفتح نموذج إضافة/تعديل مورد.
  Future<void> _openForm(
    BuildContext context, [
    SupplierModel? supplier,
  ]) async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    final saved = await Navigator.push<SupplierModel>(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormView(existing: supplier)),
    );
    if (saved == null || !context.mounted) return;
    AppToast.success(
      context,
      (supplier == null ? 'supplierAdded' : 'supplierUpdated').tr(),
    );
    // القائمة قراءة واحدة (مش ستريم) — نضيف المورد فوراً ونعمل refresh.
    await context.read<SuppliersCubit>().applySavedSupplier(saved);
  }

  /// يفتح تفاصيل المورد، ولو اتعمل تعديل أو حذف نحدّث القائمة بعد الرجوع.
  Future<void> _openDetails(BuildContext context, SupplierModel supplier) async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailsView(supplierId: supplier.id),
      ),
    );
    if (!context.mounted) return;
    final cubit = context.read<SuppliersCubit>();
    if (result is SupplierModel) {
      // تعديل: نحدّث الصف فوراً ثم refresh (الرسالة اتعرضت هنا).
      AppToast.success(context, 'supplierUpdated'.tr());
      await cubit.applySavedSupplier(result);
    } else if (result is String) {
      // حذف من التفاصيل: الرسالة اتعرضت هناك، نشيله فوراً ونعمل refresh.
      await cubit.applyDeletedSupplier(result);
    }
  }

  /// تأكيد ثم حذف.
  Future<void> _confirmDelete(
    BuildContext context,
    SupplierModel supplier,
  ) async {
    if (!await SubscriptionGate.ensureCanModify(context)) return;
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => SupplierDeleteDialog(name: supplier.displayName),
    );
    if (ok != true || !context.mounted) return;

    final cubit = context.read<SuppliersCubit>();
    final deleted = await cubit.deleteSupplier(supplier.id);
    if (!context.mounted) return;
    if (deleted) {
      AppToast.success(context, 'supplierDeleted'.tr());
    } else {
      // رسالة واضحة (مثلاً: المورد مرتبط بمنتجات).
      AppToast.error(context, translateError(cubit.state.errorMessage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SuppliersCubit, SuppliersState>(
      listener: (context, state) {
        if (state.status == SuppliersStatus.failure &&
            state.suppliers.isEmpty &&
            state.errorMessage != null) {
          AppToast.error(context, translateError(state.errorMessage));
        }
      },
      builder: (context, state) {
        final cubit = context.read<SuppliersCubit>();
        final isLoading = state.status == SuppliersStatus.loading && state.suppliers.isEmpty;
        final isError = state.status == SuppliersStatus.failure && state.suppliers.isEmpty;
        final isEmpty = state.suppliers.isEmpty && !isLoading && !isError;
        final filtered = state.filtered;

        Widget body;
        if (isLoading) {
          body = const SliverFillRemaining(
            hasScrollBody: false,
            child: SupplierListLoading(),
          );
        } else if (isError) {
          body = SliverFillRemaining(
            hasScrollBody: false,
            child: SupplierListError(
              message: translateError(state.errorMessage),
              onRetry: cubit.refresh,
            ),
          );
        } else if (isEmpty) {
          body = SliverFillRemaining(
            hasScrollBody: false,
            child: SupplierListEmpty(onAdd: () => _openForm(context)),
          );
        } else {
          body = SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
              child: SupplierListSearch(
                query: state.searchQuery,
                onSearchChanged: cubit.setSearch,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            color: AppTheme.violetDeep,
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SupplierListHeader(
                  count: state.suppliers.length,
                  onAdd: () => _openForm(context),
                ),
                body,
                if (!isLoading && !isError && !isEmpty) ...[
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: SupplierListNoResults(
                        onClear: () => cubit.setSearch(''),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 110.h),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10.h),
                        itemBuilder: (itemCtx, i) {
                          final supplier = filtered[i];
                          return Dismissible(
                                key: ValueKey(supplier.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: AlignmentDirectional.centerEnd,
                                  padding: EdgeInsetsDirectional.only(end: 20.w),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                    size: 26.sp,
                                  ),
                                ),
                                confirmDismiss: (_) =>
                                    _confirmDelete(itemCtx, supplier)
                                        .then((_) => false),
                                child: SupplierListCard(
                                  supplier: supplier,
                                  linkedCount: state.linkedCountOf(supplier.id),
                                  onTap: () => _openDetails(itemCtx, supplier),
                                  onCall: () => SupplierContact.call(itemCtx, supplier.phone),
                                  onWhatsApp: () => SupplierContact.whatsapp(itemCtx, supplier.phone),
                                ),
                              )
                              .animate(delay: (50 * i).ms)
                              .fadeIn(duration: 320.ms)
                              .slideY(begin: 0.06, end: 0);
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
