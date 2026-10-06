import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hesba/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// Hesba Admin Design System — single source of truth.
// Spacing: 4 / 8 / 12 / 16 / 20 / 24 / 32
// Radius: input 14 • button 14 • card 16 • dialog 24 • chip/badge 20
// ─────────────────────────────────────────────────────────────

/// Spacing scale — use only these values.
class AdminSpace {
  const AdminSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Corner-radius scale — use only these values.
class AdminRadius {
  const AdminRadius._();
  static const double pill = 8;
  static const double tag = 10;
  static const double thumb = 12;
  static const double tile = 12;
  static const double input = 14;
  static const double button = 14;
  static const double card = 16;
  static const double header = 20;
  static const double chip = 20;
  static const double badge = 20;
  static const double dialog = 24;
}

/// Semantic colors for the admin panel (light & dark aware where needed).
class AdminColors {
  const AdminColors._();

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : Colors.white;

  static Color surfaceAlt(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurfaceAlt : const Color(0xFFF6F7FB);

  static Color border(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? AppTheme.darkBorder
      : Colors.black.withValues(alpha: 0.06);

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : const Color(0xFF6B7280);

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : const Color(0xFF9CA3AF);

  static const Color success = AppTheme.successColor;
  static const Color warning = AppTheme.secondaryColor;
  static const Color error = AppTheme.errorColor;
  static const Color info = AppTheme.primaryColor;
}

/// Single status → (color, Arabic label, icon) mapping for the whole panel.
class AdminStatuses {
  const AdminStatuses._();

  static Color colorOf(String status) {
    return switch (status) {
      'active' || 'approved' => AdminColors.success,
      'trial' => AdminColors.info,
      'pending' => AdminColors.warning,
      'expired' => AdminColors.error,
      'rejected' => Colors.grey,
      _ => Colors.grey,
    };
  }

  static String labelOf(String status) {
    return switch (status) {
      'active' => 'نشط',
      'trial' => 'تجريبي',
      'pending' => 'معلق',
      'expired' => 'منتهي',
      'rejected' => 'مرفوض',
      'approved' => 'مقبول',
      'all' => 'الكل',
      '' => '-',
      _ => status,
    };
  }

  static IconData iconOf(String status) {
    return switch (status) {
      'active' || 'approved' => Icons.verified_outlined,
      'trial' => Icons.hourglass_bottom_outlined,
      'pending' => Icons.pending_actions_outlined,
      'expired' => Icons.cancel_outlined,
      'rejected' => Icons.block_outlined,
      _ => Icons.circle_outlined,
    };
  }
}

// ── Formatting (single formats everywhere) ───────────────────

class AdminFmt {
  const AdminFmt._();

  static const _months = [
    '',
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static DateTime? toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// "06 أكتوبر 2026"
  static String date(dynamic v) {
    final d = toDate(v);
    if (d == null) return '-';
    final m = (d.month >= 1 && d.month <= 12) ? _months[d.month] : '';
    return '${d.day.toString().padLeft(2, '0')} $m ${d.year}';
  }

  /// "2026-10-06" — compact, for dense rows.
  static String dateNum(dynamic v) {
    final d = toDate(v);
    if (d == null) return '-';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// "14:30"
  static String time(dynamic v) {
    final d = toDate(v);
    if (d == null) return '-';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  /// "06 أكتوبر 2026 • 14:30"
  static String dateTime(dynamic v) {
    final d = toDate(v);
    if (d == null) return '-';
    return '${date(d)} • ${time(d)}';
  }

  /// "1,249 ج"
  static String money(num? v) => '${number(v ?? 0)} ج';

  /// "1,249"
  static String number(num v) => NumberFormat('#,##0', 'en').format(v);

  /// "a82f92kd" (first [len] chars, no '#').
  static String shortId(String id, [int len = 8]) =>
      id.length > len ? id.substring(0, len) : id;
}

// ── Cards ────────────────────────────────────────────────────

/// Base card used by every admin page.
class AdminCard extends StatelessWidget {
  const AdminCard({super.key, required this.child, this.padding = const EdgeInsets.all(AdminSpace.lg), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AdminColors.surface(context),
        borderRadius: BorderRadius.circular(AdminRadius.card),
        border: Border.all(color: AdminColors.border(context)),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppTheme.cardShadow(context),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AdminRadius.card),
      child: InkWell(borderRadius: BorderRadius.circular(AdminRadius.card), onTap: onTap, child: body),
    );
  }
}

/// Card with a统一 title row: [icon] Title .... trailing
class AdminSection extends StatelessWidget {
  const AdminSection({super.key, required this.title, this.icon, this.trailing, this.leading, required this.child});

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Widget? leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AdminSpace.sm)],
              if (icon != null) ...[
                _IconTile(icon: icon!, color: AppTheme.primaryColor, size: 34),
                const SizedBox(width: AdminSpace.sm),
              ],
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: AdminSpace.md),
          child,
        ],
      ),
    );
  }
}

/// Small colored icon tile used across cards/rows.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color, this.size = 40, this.iconSize = 20});

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AdminRadius.tile),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Public icon tile (rows, stats, dialogs).
class AdminIconTile extends StatelessWidget {
  const AdminIconTile({super.key, required this.icon, required this.color, this.size = 40, this.iconSize = 20});

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => _IconTile(icon: icon, color: color, size: size, iconSize: iconSize);
}

// ── Statistics ───────────────────────────────────────────────

/// Unified stat card: icon + label on top, big value, optional subtitle.
/// Same height/padding/radius/typography everywhere.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({super.key, required this.icon, required this.label, required this.value, this.color, this.subtitle, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return AdminCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              AdminIconTile(icon: icon, color: c),
              const SizedBox(width: AdminSpace.sm),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        )),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.sm),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.1)),
          if (subtitle != null) ...[
            const SizedBox(height: AdminSpace.xs),
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textMuted(context))),
          ],
        ],
      ),
    );
  }
}

// ── Page header / summary ────────────────────────────────────

/// Every list page starts with this: Title + description + optional actions.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({super.key, required this.title, required this.description, this.actions = const []});

  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AdminSpace.lg, AdminSpace.lg, AdminSpace.lg, AdminSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: AdminSpace.xs),
                Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary(context))),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[const SizedBox(width: AdminSpace.md), ...actions],
        ],
      ),
    );
  }
}

/// Gradient summary banner: icon • title/total • mini stats • refresh.
class AdminSummaryHeader extends StatelessWidget {
  const AdminSummaryHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.total,
    required this.unit,
    this.stats = const [],
    this.onRefresh,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final int total;
  final String unit;
  final List<String> stats;
  final VoidCallback? onRefresh;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.md, AdminSpace.md, AdminSpace.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AdminSpace.lg, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AdminRadius.header),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: AdminSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$total',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in stats)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(AdminRadius.chip),
                            ),
                            child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(width: AdminSpace.sm),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AdminRadius.tile),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AdminRadius.tile),
                  onTap: loading ? null : onRefresh,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 20),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Search / filters / pagination ────────────────────────────

/// Unified search field: icon + clear action.
class AdminSearchField extends StatelessWidget {
  const AdminSearchField({super.key, required this.controller, required this.hint, this.onChanged, this.enabled = true});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AdminSpace.md, AdminSpace.sm, AdminSpace.md, AdminSpace.xs),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
          filled: true,
          fillColor: isDark ? AppTheme.darkSurface : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: AdminSpace.lg, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadius.input),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminRadius.input),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
          ),
        ),
      ),
    );
  }
}

/// Unified horizontal filter chips with optional counts.
class AdminFilterChips extends StatelessWidget {
  const AdminFilterChips({super.key, required this.items, required this.selected, required this.onSelect});

  final List<AdminChipItem> items;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AdminSpace.md, vertical: 6),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AdminSpace.sm),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = item.key == selected;
          return ChoiceChip(
            label: Text(
              item.count == null ? item.label : '${item.label} • ${item.count}',
              style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600),
            ),
            selected: isSelected,
            onSelected: (_) => onSelect(item.key),
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(color: isSelected ? Colors.white : null),
            avatar: isSelected || item.dot == null ? null : Icon(Icons.circle, size: 10, color: item.dot),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.chip)),
          );
        },
      ),
    );
  }
}

class AdminChipItem {
  const AdminChipItem(this.key, this.label, {this.count, this.dot});
  final String key;
  final String label;
  final int? count;
  final Color? dot;
}

/// Unified "load more" footer for all paginated lists.
class AdminLoadMore extends StatelessWidget {
  const AdminLoadMore({super.key, required this.loading, required this.label, required this.onLoad});

  final bool loading;
  final String label;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AdminSpace.lg, 0, AdminSpace.lg, AdminSpace.lg),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.input)),
            ),
            onPressed: loading ? null : onLoad,
            icon: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.expand_more, size: 20),
            label: Text(loading ? 'جاري التحميل...' : label),
          ),
        ),
      ),
    );
  }
}

/// "X نتيجة" + clear-filter row shown under search when filtering.
class AdminResultCount extends StatelessWidget {
  const AdminResultCount({super.key, required this.count, required this.onClear, this.clearLabel = 'مسح الفلتر'});

  final int count;
  final VoidCallback onClear;
  final String clearLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpace.lg, vertical: AdminSpace.xs),
      child: Row(
        children: [
          Text('نتائج البحث: $count',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AdminColors.textSecondary(context), fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: 16),
            label: Text(clearLabel, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ─────────────────────────────────────────────

/// Unified status badge: colored dot + Arabic label.
class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.label, required this.color, this.dot = true});

  /// Build from a raw status id ('active', 'trial', ...). Arabic label applied.
  factory AdminStatusBadge.status(String status) {
    return AdminStatusBadge(label: AdminStatuses.labelOf(status), color: AdminStatuses.colorOf(status));
  }

  final String label;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(AdminRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── IDs ──────────────────────────────────────────────────────

/// The ONLY way IDs are displayed in the admin panel.
/// Short mode (rows/tables): truncated id + tiny copy button.
/// Full mode (details): label + full id + copy button.
/// Always copies the FULL id and shows "تم نسخ الـ ID".
class CopyableId extends StatelessWidget {
  const CopyableId({super.key, required this.id, this.full = false, this.label});

  final String id;
  final bool full;
  final String? label;

  static void copy(BuildContext context, String id) {
    if (id.isEmpty) return;
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الـ ID'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (id.isEmpty) return const Text('-');
    if (!full) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              AdminFmt.shortId(id),
              style: TextStyle(fontSize: 11, color: AdminColors.textMuted(context), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => copy(context, id),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.copy_outlined, size: 13, color: AdminColors.textMuted(context)),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: TextStyle(fontSize: 11, color: AdminColors.textSecondary(context), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
        ],
        Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Text(id,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: AdminSpace.sm),
            Material(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AdminRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AdminRadius.pill),
                onTap: () => copy(context, id),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_outlined, size: 14, color: AppTheme.primaryColor),
                      SizedBox(width: 4),
                      Text('نسخ', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Info rows / thumbnails ───────────────────────────────────

/// Unified icon + label + value row for details screens.
class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow({super.key, required this.icon, required this.label, required this.value, this.copyable = false});

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AdminIconTile(icon: icon, color: AppTheme.primaryColor, size: 34, iconSize: 18),
        const SizedBox(width: AdminSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: AdminColors.textSecondary(context), fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (copyable && value != '-')
          IconButton(
            tooltip: 'نسخ',
            icon: const Icon(Icons.copy_outlined, size: 17),
            onPressed: () => CopyableId.copy(context, value),
          ),
      ],
    );
  }
}

/// Unified image thumbnail with icon fallback.
class AdminThumbnail extends StatelessWidget {
  const AdminThumbnail({super.key, required this.url, this.size = 62, this.icon = Icons.image_outlined, this.radius});

  final String url;
  final double size;
  final IconData icon;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AdminRadius.thumb;
    if (url.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(r)),
        child: Icon(icon, color: AppTheme.primaryColor, size: size * 0.45),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(r)),
          child: Icon(icon, color: AppTheme.primaryColor, size: size * 0.45),
        ),
      ),
    );
  }
}

// ── Dialogs & sheets ─────────────────────────────────────────

/// Unified dialog shell: rounded 24, title row with close, content, actions.
class AdminDialogShell extends StatelessWidget {
  const AdminDialogShell({super.key, required this.title, this.subtitle, required this.child, this.actions = const []});

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.dialog)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpace.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          if (subtitle != null) ...[
                            const SizedBox(height: AdminSpace.xs),
                            Text(subtitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AdminColors.textSecondary(context))),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
                const SizedBox(height: AdminSpace.md),
                child,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AdminSpace.xl),
                  Row(children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: AdminSpace.sm),
                      Expanded(child: actions[i]),
                    ],
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified confirm dialog. Returns true when confirmed.
Future<bool> showAdminConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AdminDialogShell(
      title: title,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: danger ? ElevatedButton.styleFrom(backgroundColor: AdminColors.error) : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
      child: Text(message),
    ),
  );
  return result ?? false;
}

/// Unified bottom-sheet shell with drag handle + title.
class AdminSheetShell extends StatelessWidget {
  const AdminSheetShell({super.key, required this.title, this.subtitle, required this.child, this.actions = const []});

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.fromLTRB(AdminSpace.lg, AdminSpace.sm, AdminSpace.lg, AdminSpace.xxl),
      decoration: BoxDecoration(
        color: AdminColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AdminRadius.dialog)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary(context))),
                      ],
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
              ],
            ),
            const SizedBox(height: AdminSpace.md),
            child,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AdminSpace.lg),
              Row(children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: AdminSpace.sm),
                  Expanded(child: actions[i]),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

Future<T?> showAdminSheet<T>(BuildContext context, Widget sheet) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}

// ── States (loading / empty / error) ─────────────────────────

/// Empty state with an icon and a friendly (non-technical) message.
Widget adminEmpty(IconData icon, String message, [String? hint]) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(AdminSpace.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(AdminRadius.header)),
            child: Icon(icon, size: 36, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: AdminSpace.md),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          if (hint != null) ...[
            const SizedBox(height: AdminSpace.xs),
            Text(hint, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12.5)),
          ],
        ],
      ),
    ),
  );
}

/// Error state with a short message and a retry button (no stack traces).
Widget adminError(String message, VoidCallback onRetry) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(AdminSpace.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
                color: AdminColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AdminRadius.header)),
            child: const Icon(Icons.error_outline, size: 36, color: AdminColors.error),
          ),
          const SizedBox(height: AdminSpace.md),
          const Text('حدث خطأ أثناء تحميل البيانات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: AdminSpace.xs),
          Text(message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: AdminSpace.lg),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
}

/// A lightweight skeleton row for lists (no package dependency).
Widget adminSkeleton(BuildContext context) {
  final base = Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurfaceAlt : Colors.grey[200];
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: AdminSpace.lg, vertical: AdminSpace.md),
    child: Row(
      children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(AdminRadius.tile))),
        const SizedBox(width: AdminSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 12, width: 160, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: AdminSpace.sm),
              Container(height: 10, width: 100, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget adminSkeletonList(BuildContext context, {int count = 6}) {
  return ListView.builder(
    itemCount: count,
    itemBuilder: (_, _) => adminSkeleton(context),
  );
}
