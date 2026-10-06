import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hesba/core/di/service_locator.dart';
import 'package:hesba/features/admin/presentation/views/admin_ui.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:hesba/features/admin/data/repos/admin_repo.dart';
import 'package:hesba/features/admin/presentation/cubit/admin_list_cubit.dart';
import 'package:hesba/features/subscription/data/models/subscription_plan.dart';

class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
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
      key: ValueKey(_status),
      create: (_) => AdminListCubit(
        fetch: (startAfter) => sl<AdminRepo>().getSubscriptionsPage(
          startAfter: startAfter,
          status: _status == 'all' ? null : _status,
        ),
      )..firstPage(),
      child: BlocBuilder<AdminListCubit, AdminListState>(
        builder: (context, state) {
          if (state.loading && state.docs.isEmpty) {
            return Column(
              children: [
                _summarySkeleton(context),
                _searchBar(context, enabled: false),
                Expanded(child: adminSkeletonList(context)),
              ],
            );
          }
          if (state.error != null && state.docs.isEmpty) {
            return adminError(state.error!, () => context.read<AdminListCubit>().firstPage());
          }
          if (state.docs.isEmpty && _query.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => context.read<AdminListCubit>().firstPage(),
              child: ListView(
                children: [
                  _summaryHeader(context, docs: const [], loading: false),
                  _searchBar(context, enabled: false),
                  _statusChips(context, const []),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: adminEmpty(Icons.workspace_premium_outlined, 'لا توجد اشتراكات'),
                  ),
                ],
              ),
            );
          }

          final filtered = _applySearch(state.docs);

          return RefreshIndicator(
            onRefresh: () => context.read<AdminListCubit>().firstPage(),
            child: Column(
              children: [
                _summaryHeader(context, docs: state.docs, loading: state.loading),
                _searchBar(context, enabled: true),
                _statusChips(context, state.docs),
                if (_query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Row(
                      children: [
                        Text('نتائج البحث: ${filtered.length}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey[600])),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _query = '';
                            _searchCtrl.clear();
                          }),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('مسح البحث', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? adminEmpty(Icons.search_off_outlined, 'لا توجد نتائج مطابقة لبحثك')
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            if (wide) {
                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth >= 1100 ? 3 : 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 168,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) => _SubCard(
                                  doc: filtered[i],
                                  onTap: () => _openDetails(context, filtered[i]),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: _SubCard(
                                  doc: filtered[i],
                                  onTap: () => _openDetails(context, filtered[i]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (state.hasMore)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: state.loading ? null : () => context.read<AdminListCubit>().nextPage(),
                          icon: state.loading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.expand_more, size: 20),
                          label: Text(state.loading ? 'جاري التحميل...' : 'تحميل المزيد (${state.docs.length} معروض)'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applySearch(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final q = _query.trim();
    if (q.isEmpty) return docs;
    return docs.where((d) {
      final data = d.data();
      final haystack = [
        data['userId'],
        data['plan'],
        data['status'],
        d.id,
      ].whereType<String>().join(' ');
      return haystack.contains(q);
    }).toList();
  }

  Widget _summarySkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Container(
        height: 96,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _summaryHeader(BuildContext context, {required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, required bool loading}) {
    int count(String s) => docs.where((d) => (d.data()['status'] as String?) == s).length;
    final active = count('active');
    final trial = count('trial');
    final expired = count('expired');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إجمالي الاشتراكات', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${docs.length}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Text('اشتراك', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _miniStat('نشط $active', Colors.white),
                      _miniStat('تجريبي $trial', Colors.white70),
                      _miniStat('منتهي $expired', Colors.white70),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: loading ? null : () => context.read<AdminListCubit>().firstPage(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }

  Widget _searchBar(BuildContext context, {required bool enabled}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchCtrl,
        enabled: enabled,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'ابحث برقم المستخدم أو الباقة...',
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() {
                    _query = '';
                    _searchCtrl.clear();
                  }),
                ),
          filled: true,
          fillColor: isDark ? AppTheme.darkSurface : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _statusChips(BuildContext context, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    int count(String s) => s == 'all' ? docs.length : docs.where((d) => (d.data()['status'] as String?) == s).length;
    final items = [
      ('all', 'الكل'),
      ('active', 'نشط'),
      ('trial', 'تجريبي'),
      ('expired', 'منتهي'),
      ('pending', 'معلق'),
      ('rejected', 'مرفوض'),
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final key = items[i].$1;
          final label = items[i].$2;
          final selected = key == _status;
          final color = _statusColor(key == 'all' ? 'active' : key);
          return ChoiceChip(
            label: Text('$label • ${count(key)}',
                style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
            selected: selected,
            onSelected: (_) => setState(() => _status = key),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(color: selected ? Colors.white : null),
            avatar: selected ? null : Icon(Icons.circle, size: 10, color: color),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  void _openDetails(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubDetailsSheet(data: doc.data(), docId: doc.id),
    );
  }
}

// ── Card ────────────────────────────────────────────────

class _SubCard extends StatelessWidget {
  const _SubCard({required this.doc, required this.onTap});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final status = (data['status'] as String?) ?? '';
    final planId = (data['plan'] as String?) ?? '';
    final userId = (data['userId'] as String?) ?? doc.id;
    final isTrial = (data['isTrial'] as bool?) ?? (status == 'trial');
    final endDate = _toDate(data['endDate']);
    final startDate = _toDate(data['startDate']);
    final remaining = endDate?.difference(DateTime.now()).inDays;

    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.black.withValues(alpha: 0.06);
    final subColor = isDark ? AppTheme.darkTextSecondary : Colors.grey[600];
    final statusColor = _statusColor(status);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: isDark ? null : AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(status), color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_planLabel(planId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('user: ${userId.length > 10 ? '${userId.substring(0, 10)}…' : userId}',
                            style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  AdminStatusBadge(label: _statusLabel(status), color: statusColor),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _pill(Icons.calendar_month_outlined, _fmtDate(startDate), subColor, isDark),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_back, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  _pill(Icons.event_outlined, _fmtDate(endDate), subColor, isDark),
                  const Spacer(),
                  if (remaining != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (remaining <= 0 ? Colors.redAccent : remaining <= 7 ? Colors.orange : AppTheme.successColor)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        remaining <= 0 ? 'انتهى' : 'متبقي $remaining يوم',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: remaining <= 0
                              ? Colors.redAccent
                              : remaining <= 7
                                  ? Colors.orange
                                  : AppTheme.successColor,
                        ),
                      ),
                    ),
                ],
              ),
              if (isTrial)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.timelapse_outlined, size: 13, color: subColor),
                      const SizedBox(width: 4),
                      Text('فترة تجريبية', style: TextStyle(fontSize: 11.5, color: subColor, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('اضغط للتفاصيل', style: TextStyle(fontSize: 11, color: subColor)),
                      const Icon(Icons.chevron_left_rounded, size: 18, color: Colors.black26),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color? color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Details sheet ───────────────────────────────────────

class _SubDetailsSheet extends StatelessWidget {
  const _SubDetailsSheet({required this.data, required this.docId});
  final Map<String, dynamic> data;
  final String docId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = (data['status'] as String?) ?? '';
    final planId = (data['plan'] as String?) ?? '';
    final userId = (data['userId'] as String?) ?? docId;
    final isTrial = (data['isTrial'] as bool?) ?? false;
    final start = _toDate(data['startDate']);
    final end = _toDate(data['endDate']);
    final updated = _toDate(data['updatedAt']);
    final remaining = end?.difference(DateTime.now()).inDays;
    final statusColor = _statusColor(status);

    SubscriptionPlan? plan;
    try {
      plan = SubscriptionPlan.fromId(planId);
    } catch (_) {
      plan = null;
    }

    double? progress;
    if (start != null && end != null && end.isAfter(start)) {
      final total = end.difference(start).inDays.clamp(1, 10000);
      final left = (remaining ?? 0).clamp(0, total);
      progress = left / total;
    }

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(_statusIcon(status), color: statusColor, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_planLabel(planId), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text('اشتراك ${_statusLabel(status)}', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                AdminStatusBadge(label: _statusLabel(status), color: statusColor),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: (isDark ? AppTheme.darkBorder : Colors.grey[200]),
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (remaining ?? 0) <= 0 ? 'انتهت المدة' : 'متبقي ${remaining ?? 0} يوم من أصل ${end!.difference(start!).inDays} يوم',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 14),
            _detailRow(context, Icons.person_outline, 'المستخدم', userId, copyable: true),
            _detailRow(context, Icons.workspace_premium_outlined, 'الباقة', '${_planLabel(planId)} (${plan?.days ?? '-'} يوم • ${plan?.price ?? '-'} ج)'),
            _detailRow(context, Icons.timelapse_outlined, 'تجريبي', isTrial ? 'نعم' : 'لا'),
            _detailRow(context, Icons.play_arrow_outlined, 'البدء', _fmtDateFull(start)),
            _detailRow(context, Icons.stop_outlined, 'الانتهاء', _fmtDateFull(end)),
            _detailRow(context, Icons.update_outlined, 'آخر تحديث', _fmtDateFull(updated)),
            _detailRow(context, Icons.badge_outlined, 'معرف المستند', docId, copyable: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value, {bool copyable = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : Colors.grey[600])),
                const SizedBox(height: 1),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 17),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم النسخ'), duration: Duration(seconds: 1)),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────

Color _statusColor(String status) {
  return switch (status) {
    'active' => AppTheme.successColor,
    'trial' => AppTheme.primaryColor,
    'pending' => AppTheme.secondaryColor,
    'expired' => Colors.redAccent,
    'rejected' => Colors.grey,
    _ => Colors.grey,
  };
}

IconData _statusIcon(String status) {
  return switch (status) {
    'active' => Icons.verified_outlined,
    'trial' => Icons.hourglass_bottom_outlined,
    'expired' => Icons.cancel_outlined,
    'pending' => Icons.pending_actions_outlined,
    'rejected' => Icons.block_outlined,
    _ => Icons.workspace_premium_outlined,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'active' => 'نشط',
    'trial' => 'تجريبي',
    'expired' => 'منتهي',
    'pending' => 'معلق',
    'rejected' => 'مرفوض',
    'all' => 'الكل',
    _ => status.isEmpty ? '-' : status,
  };
}

String _planLabel(String id) {
  return switch (id) {
    'monthly' => 'شهري',
    'threeMonths' => '3 شهور',
    'sixMonths' => '6 شهور',
    'yearly' => 'سنوي',
    '' => '-',
    _ => id,
  };
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _fmtDateFull(DateTime? d) {
  if (d == null) return '-';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
