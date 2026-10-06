import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'subscription_plan.dart';

/// The five states the app cares about. Everything else is derived from dates.
enum SubscriptionStatus {
  trial('trial'),
  active('active'),
  expired('expired'),
  pending('pending'),
  rejected('rejected');

  const SubscriptionStatus(this.id);

  final String id;

  static SubscriptionStatus fromId(String? id) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.id == id,
      orElse: () => SubscriptionStatus.expired,
    );
  }
}

/// The `users/{userId}/subscription` document.
///
/// The status is stored, but [effectiveStatus] re-derives it from the dates on
/// every read so a trial or a paid period flips to `expired` by itself without
/// needing a background job.
class SubscriptionModel extends Equatable {
  /// Free period handed to every new account, in days.
  static const int trialDays = 7;

  const SubscriptionModel({
    this.status = SubscriptionStatus.expired,
    this.plan,
    this.startDate,
    this.endDate,
    this.isTrial = false,
    this.trialStartDate,
    this.trialEndDate,
    this.lastRequestId,
    this.updatedAt,
    this.cachedAt,
  });

  final SubscriptionStatus status;
  final SubscriptionPlan? plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isTrial;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;

  /// The subscription request currently driving this account (pending or the
  /// last one reviewed), so the app can check whether it was approved.
  final String? lastRequestId;
  final DateTime? updatedAt;

  /// Client-only: when this object was fetched, used to expire the in-memory
  /// cache the guard reads from. Never written to Firestore.
  final DateTime? cachedAt;

  /// A brand new account: 7 days starting at creation, and the free trial can
  /// never be claimed a second time.
  factory SubscriptionModel.trialFor({required DateTime createdAt}) {
    final end = createdAt.add(const Duration(days: trialDays));
    return SubscriptionModel(
      status: SubscriptionStatus.trial,
      isTrial: true,
      startDate: createdAt,
      endDate: end,
      trialStartDate: createdAt,
      trialEndDate: end,
      updatedAt: createdAt,
    );
  }

  /// The status as it really is right now: a live trial or paid period past its
  /// end date reads as `expired`, everything else is whatever was stored.
  SubscriptionStatus get effectiveStatus {
    final stored = status;
    if (stored == SubscriptionStatus.pending ||
        stored == SubscriptionStatus.rejected) {
      return stored;
    }
    final end = endDate;
    if (end == null || !end.isAfter(DateTime.now())) {
      return SubscriptionStatus.expired;
    }
    return stored;
  }

  /// The single check the whole app asks before any Add / Edit / Delete.
  ///
  /// Only a trial or a paid period that has not ended may change data.
  /// `expired`, `pending` and `rejected` are read-only: the app still opens,
  /// the data stays visible, but the write must be redirected to the
  /// subscription screen.
  bool get canModifyData {
    final current = effectiveStatus;
    return current == SubscriptionStatus.trial ||
        current == SubscriptionStatus.active;
  }

  /// Why the user is blocked, so the UI can say the right thing.
  String get blockedMessageKey => switch (effectiveStatus) {
        SubscriptionStatus.pending => 'subscriptionPendingBlocked',
        SubscriptionStatus.rejected => 'subscriptionRejectedBlocked',
        _ => 'subscriptionExpiredBlocked',
      };

  int get remainingDays {
    final end = endDate;
    if (end == null) return 0;
    final days = end.difference(DateTime.now()).inHours ~/ 24;
    return days < 0 ? 0 : days;
  }

  bool get hasLivedPeriod => endDate != null || trialEndDate != null;

  bool get isCurrentTrial =>
      isTrial && effectiveStatus == SubscriptionStatus.trial;

  DateTime? get livePeriodEnd => endDate ?? trialEndDate;

  /// Days before the period ends the app is meant to remind about.
  ///
  /// Nothing schedules these yet — this is the shape the notification work
  /// will consume. See [reminderOffsetsOn].
  static const List<int> reminderOffsetsDays = [7, 3, 1];

  /// Which of [reminderOffsetsDays] fall on [day], i.e. which reminders are
  /// due today. Empty when there is no period to count down from.
  List<int> reminderOffsetsOn(DateTime day) {
    final end = livePeriodEnd;
    if (end == null) return const [];
    return [
      for (final offset in reminderOffsetsDays)
        if (_sameDay(end.subtract(Duration(days: offset)), day)) offset,
    ];
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      status: SubscriptionStatus.fromId(json['status'] as String?),
      plan: json['plan'] == null
          ? null
          : SubscriptionPlan.fromId(json['plan'] as String?),
      startDate: _date(json['startDate']),
      endDate: _date(json['endDate']),
      isTrial: json['isTrial'] as bool? ?? false,
      trialStartDate: _date(json['trialStartDate']),
      trialEndDate: _date(json['trialEndDate']),
      lastRequestId: json['lastRequestId'] as String?,
      updatedAt: _date(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.id,
      'plan': plan?.id,
      'startDate': startDate == null ? null : Timestamp.fromDate(startDate!),
      'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
      'isTrial': isTrial,
      'trialStartDate': trialStartDate == null
          ? null
          : Timestamp.fromDate(trialStartDate!),
      'trialEndDate':
          trialEndDate == null ? null : Timestamp.fromDate(trialEndDate!),
      'lastRequestId': lastRequestId,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  SubscriptionModel copyWith({
    SubscriptionStatus? status,
    SubscriptionPlan? plan,
    DateTime? startDate,
    DateTime? endDate,
    bool? isTrial,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    String? lastRequestId,
    DateTime? updatedAt,
    DateTime? cachedAt,
  }) {
    return SubscriptionModel(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isTrial: isTrial ?? this.isTrial,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      lastRequestId: lastRequestId ?? this.lastRequestId,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        status,
        plan,
        startDate,
        endDate,
        isTrial,
        trialStartDate,
        trialEndDate,
        lastRequestId,
        updatedAt,
        cachedAt,
      ];
}
