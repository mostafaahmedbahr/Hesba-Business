import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../contact/data/models/feedback_entry.dart';
import '../../data/repos/admin_repo.dart';
import '../cubit/admin_list_cubit.dart';
import 'admin_ds.dart';

/// إدارة ملاحظات المستخدمين (شكاوى / اقتراحات / استفسارات).
///
/// الملاحظات بتيجي من "تواصل معنا" داخل التطبيق (collection `feedback`).
/// الأدمن يقدر يقرأ كل الملاحظات، يعلّمها "تم التعامل معها" أو يرجعها
/// "جديدة"، أو يحذفها — مفيش رد مباشر داخل اللوحة.
class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  /// 'all' | 'new' | 'handled'
  String _status = 'all';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminListCubit(
        fetch: (startAfter) =>
            sl<AdminRepo>().getFeedbackPage(startAfter: startAfter),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) {
            return Column(
              children: [
                AdminSearchField(controller: _searchCtrl, hint: 'ابحث بالعنوان أو التفاصيل أو البريد...', enabled: false),
                const Expanded(child: LoadingWidget()),
              ],
            );
          }
          if (state.error != null && state.docs.isEmpty) {
            return adminError(state.error!, () => context.read<AdminListCubit>().firstPage());
          }

          final ordered = _ordered(state.docs);
          final filtered = _applySearch(_applyFilter(ordered));
          final searching = _query.isNotEmpty;
          final newCount = ordered.where((e) => !e.handled).length;
          final handledCount = ordered.length - newCount;

          return RefreshIndicator(
            onRefresh: () => context.read<AdminListCubit>().firstPage(),
            child: Column(
              children: [
                const AdminPageHeader(
                  title: 'الملاحظات والشكاوى',
                  description: 'شكاوى واقتراحات واستفسارات المستخدمين — علّمها كمُعالجة أو احذفها',
                ),
                AdminSummaryHeader(
                  icon: Icons.mark_email_unread_outlined,
                  title: 'ملاحظات جديدة',
                  total: newCount,
                  unit: 'جديدة',
                  stats: [
                    'إجمالي المعروض: ${ordered.length}',
                    'تم التعامل معها: $handledCount',
                  ],
                  loading: state.loading,
                  onRefresh: () => context.read<AdminListCubit>().firstPage(),
                ),
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'ابحث بالعنوان أو التفاصيل أو البريد...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                AdminFilterChips(
                  selected: _status,
                  onSelect: (k) => setState(() => _status = k),
                  items: [
                    const AdminChipItem('all', 'الكل'),
                    AdminChipItem('new', 'جديدة', dot: AdminColors.warning),
                    AdminChipItem('handled', 'تم التعامل معها', dot: AdminColors.success),
                  ],
                ),
                if (searching)
                  AdminResultCount(
                    count: filtered.length,
                    clearLabel: 'مسح البحث',
                    onClear: () => setState(() {
                      _query = '';
                      _searchCtrl.clear();
                    }),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? adminEmpty(
                          Icons.feedback_outlined,
                          searching
                              ? 'لا توجد نتائج مطابقة لبحثك'
                              : _status == 'new'
                                  ? 'لا توجد ملاحظات جديدة'
                                  : _status == 'handled'
                                      ? 'لا توجد ملاحظات تم التعامل معها'
                                      : 'لا توجد ملاحظات بعد',
                          searching ? null : 'أي ملاحظة تصل عبر "تواصل معنا" هتظهر هنا',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(0, AdminSpace.xs, 0, AdminSpace.lg),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AdminSpace.sm),
                          itemBuilder: (context, i) {
                            final entry = filtered[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AdminSpace.md),
                              child: _FeedbackCard(
                                entry: entry,
                                onTap: () => _openDetails(context, entry),
                              ),
                            );
                          },
                        ),
                ),
                if (state.hasMore)
                  AdminLoadMore(
                    loading: state.loading,
                    label: 'تحميل المزيد (${state.docs.length} معروض)',
                    onLoad: () => context.read<AdminListCubit>().nextPage(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<FeedbackEntry> _ordered(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list = docs.map((d) => FeedbackEntry.fromMap(d.id, d.data())).toList();
    // createdAt desc (السيرفر بيرتب فعلاً — ده احتياطي للمستندات بلا حقل)
    list.sort((a, b) {
      final da = a.createdAt, db = b.createdAt;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  List<FeedbackEntry> _applyFilter(List<FeedbackEntry> list) {
    return switch (_status) {
      'new' => list.where((e) => !e.handled).toList(),
      'handled' => list.where((e) => e.handled).toList(),
      _ => list,
    };
  }

  List<FeedbackEntry> _applySearch(List<FeedbackEntry> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((e) {
      final haystack = [e.title, e.description, e.userEmail, e.userId, e.type, e.id]
          .join(' ')
          .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Future<void> _openDetails(BuildContext context, FeedbackEntry entry) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _FeedbackDetailsDialog(
        entry: entry,
        onToggleHandled: (handled) => _setHandled(context, entry, handled),
        onDelete: () => _delete(context, entry),
      ),
    );
    if (context.mounted) context.read<AdminListCubit>().firstPage();
  }

  Future<void> _setHandled(BuildContext context, FeedbackEntry entry, bool handled) async {
    try {
      await sl<AdminRepo>().setFeedbackHandled(entry.id, handled);
      if (!context.mounted) return;
      AppToast.success(context, handled ? 'تم تعليم الملاحظة كـ "تم التعامل معها"' : 'رجعت الملاحظة "جديدة"');
      context.read<AdminListCubit>().firstPage();
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(context, 'تعذر تحديث الملاحظة');
    }
  }

  Future<bool> _delete(BuildContext context, FeedbackEntry entry) async {
    final ok = await showAdminConfirm(
      context,
      title: 'حذف الملاحظة',
      message: 'هيتم حذف الملاحظة نهائيًا. هل أنت متأكد؟',
      confirmLabel: 'حذف',
      danger: true,
    );
    if (!ok) return false;
    try {
      await sl<AdminRepo>().deleteFeedback(entry.id);
      if (!context.mounted) return true;
      AppToast.success(context, 'تم حذف الملاحظة');
      context.read<AdminListCubit>().firstPage();
      return true;
    } catch (_) {
      if (!context.mounted) return true;
      AppToast.error(context, 'تعذر حذف الملاحظة');
      return true;
    }
  }
}

// ── Card ────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.entry, required this.onTap});
  final FeedbackEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final (typeLabel, typeIcon, typeColor) = FeedbackEntry.typeMeta(e.type);
    return AdminCard(
      padding: const EdgeInsets.all(AdminSpace.md),
      onTap: onTap,
      child: Row(
        children: [
          AdminIconTile(icon: typeIcon, color: typeColor, size: 52),
          const SizedBox(width: AdminSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.title.isEmpty ? '(بدون عنوان)' : e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AdminStatusBadge(label: typeLabel, color: typeColor),
                    if (!e.handled) ...[
                      const SizedBox(width: 6),
                      AdminStatusBadge(label: 'جديدة', color: AdminColors.warning, dot: true),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  e.userEmail.isEmpty ? 'مستخدم بدون بريد' : e.userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  e.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AdminColors.textMuted(context), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  AdminFmt.dateTime(e.createdAt),
                  style: TextStyle(fontSize: 10.5, color: AdminColors.textMuted(context)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left_rounded, color: AdminColors.textMuted(context), size: 22),
        ],
      ),
    );
  }
}

// ── Details dialog ───────────────────────────────────────

class _FeedbackDetailsDialog extends StatefulWidget {
  const _FeedbackDetailsDialog({
    required this.entry,
    required this.onToggleHandled,
    required this.onDelete,
  });

  final FeedbackEntry entry;

  /// ينفّذ تعليم الملاحظة/إرجاعها للأب؛ الإجراء نفسه ينفذ في الـ view
  /// (الديالوج ما بيستدعيش الـ repo بنفسه).
  final Future<void> Function(bool handled) onToggleHandled;
  final Future<bool> Function() onDelete;

  @override
  State<_FeedbackDetailsDialog> createState() => _FeedbackDetailsDialogState();
}

class _FeedbackDetailsDialogState extends State<_FeedbackDetailsDialog> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final (typeLabel, typeIcon, typeColor) = FeedbackEntry.typeMeta(e.type);
    return AdminDialogShell(
      title: 'تفاصيل الملاحظة',
      subtitle: typeLabel,
      actions: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _confirmDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminColors.error,
            side: BorderSide(color: AdminColors.error),
          ),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('حذف'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _toggleHandled,
          icon: Icon(e.handled ? Icons.mark_email_unread_outlined : Icons.check_circle_outline, size: 18),
          label: Text(e.handled ? 'ارجعها جديدة' : 'تم التعامل معها'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminIconTile(icon: typeIcon, color: typeColor, size: 44),
              const SizedBox(width: AdminSpace.sm),
              AdminStatusBadge(label: typeLabel, color: typeColor),
              const SizedBox(width: 6),
              AdminStatusBadge(
                label: e.handled ? 'تم التعامل معها' : 'جديدة',
                color: e.handled ? AdminColors.success : AdminColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.md),
          Text(
            e.title.isEmpty ? '(بدون عنوان)' : e.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: AdminSpace.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AdminSpace.md),
            decoration: BoxDecoration(
              color: AdminColors.surfaceAlt(context),
              borderRadius: BorderRadius.circular(AdminRadius.card),
            ),
            child: SelectableText(
              e.description,
              style: const TextStyle(fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: AdminSpace.md),
          AdminInfoRow(
            icon: Icons.alternate_email,
            label: 'البريد',
            value: e.userEmail.isEmpty ? '-' : e.userEmail,
            copyable: e.userEmail.isNotEmpty,
          ),
          const SizedBox(height: AdminSpace.sm),
          AdminInfoRow(
            icon: Icons.schedule_outlined,
            label: 'تاريخ الإرسال',
            value: AdminFmt.dateTime(e.createdAt),
          ),
          if (e.handled && e.handledAt != null) ...[
            const SizedBox(height: AdminSpace.sm),
            AdminInfoRow(
              icon: Icons.check_circle_outline,
              label: 'تاريخ التعامل معها',
              value: AdminFmt.dateTime(e.handledAt),
            ),
          ],
          const SizedBox(height: AdminSpace.md),
          CopyableId(id: e.id, full: true, label: 'معرّف الملاحظة'),
          const SizedBox(height: 6),
          CopyableId(id: e.userId, full: true, label: 'معرّف المستخدم'),
        ],
      ),
    );
  }

  Future<void> _toggleHandled() async {
    setState(() => _busy = true);
    await widget.onToggleHandled(!widget.entry.handled);
    if (mounted) {
      setState(() => _busy = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete() async {
    setState(() => _busy = true);
    final deleted = await widget.onDelete();
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }
}
