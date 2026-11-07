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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupplierFormView(existing: supplier)),
    );
    // القائمة ستريم فتعمل تحديث تلقائياً — لا حاجة لنتيجة الرجوع.
  }

  /// يفتح تفاصيل المورد.
  void _openDetails(BuildContext context, SupplierModel supplier) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailsView(supplierId: supplier.id),
      ),
    );
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
        // بيحمل.
        if (state.status == SuppliersStatus.loading &&
            state.suppliers.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(
              slivers: [
                SupplierListHeader(count: 0, onAdd: () => _openForm(context)),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SupplierListLoading(),
                ),
              ],
            ),
          );
        }
        // خطأ.
        if (state.status == SuppliersStatus.failure &&
            state.suppliers.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(
              slivers: [
                SupplierListHeader(count: 0, onAdd: () => _openForm(context)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SupplierListError(
                    message: translateError(state.errorMessage),
                    onRetry: () => context.read<SuppliersCubit>().refresh(),
                  ),
                ),
              ],
            ),
          );
        }
        final cubit = context.read<SuppliersCubit>();
        // فاضي خالص: زرار واحد بس.
        if (state.suppliers.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomScrollView(
              slivers: [
                SupplierListHeader(count: 0, onAdd: () => _openForm(context)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SupplierListEmpty(onAdd: () => _openForm(context)),
                ),
              ],
            ),
          );
        }
        // فيه داتا.
        final filtered = state.filtered;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'suppliers_fab',
            onPressed: () => _openForm(context),
            elevation: 0,
            backgroundColor: AppTheme.violetDeep,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'suppliersAdd'.tr(),
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
            ),
          ),
          body: RefreshIndicator(
            color: AppTheme.violetDeep,
            onRefresh: () => cubit.refresh(),
            child: CustomScrollView(
              // عشان RefreshIndicator يشتغل حتى لو المحتوى قصير.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SupplierListHeader(
                  count: state.suppliers.length,
                  onAdd: () => _openForm(context),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                    child: SupplierListSearch(
                      query: state.searchQuery,
                      onSearchChanged: cubit.setSearch,
                    ),
                  ),
                ),
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
                              // Directional عشان يشتغل صح في RTL.
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
                              confirmDismiss: (_) => _confirmDelete(
                                itemCtx,
                                supplier,
                              ).then((_) => false),
                              child: SupplierListCard(
                                supplier: supplier,
                                linkedCount: state.linkedCountOf(supplier.id),
                                onTap: () => _openDetails(itemCtx, supplier),
                                onCall: () => SupplierContact.call(
                                  itemCtx,
                                  supplier.phone,
                                ),
                                onWhatsApp: () => SupplierContact.whatsapp(
                                  itemCtx,
                                  supplier.phone,
                                ),
                              ),
                            )
                            .animate(delay: (50 * i).ms)
                            .fadeIn(duration: 320.ms)
                            .slideY(begin: 0.06, end: 0);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
