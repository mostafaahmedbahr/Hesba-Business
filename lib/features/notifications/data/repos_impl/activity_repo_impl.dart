import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_model.dart';
import '../repos/activity_repo.dart';

class ActivityRepoImpl implements ActivityRepo {
  final SharedPreferences _prefs;
  static const _kKey = 'activity_notifications_v1';
  final _controller = StreamController<List<ActivityModel>>.broadcast();

  ActivityRepoImpl(this._prefs) {
    // push initial
    Future.microtask(() => _controller.add(_loadSync()));
  }

  List<ActivityModel> _loadSync() {
    final raw = _prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => ActivityModel.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivityModel>> _load() async => _loadSync();

  Future<void> _save(List<ActivityModel> list) async {
    await _prefs.setString(_kKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    if (!_controller.isClosed) _controller.add(List.of(list));
  }

  @override
  Future<List<ActivityModel>> getActivities() async => _load();

  @override
  Future<int> getUnreadCount() async {
    final list = await _load();
    return list.where((e) => !e.isRead).length;
  }

  @override
  Stream<List<ActivityModel>> watchActivities() async* {
    yield await _load();
    yield* _controller.stream;
  }

  @override
  Stream<int> watchUnreadCount() async* {
    yield await getUnreadCount();
    await for (final list in _controller.stream) {
      yield list.where((e) => !e.isRead).length;
    }
  }

  @override
  Future<void> addActivity({required ActivityType type, required String title, required String body}) async {
    final list = await _load();
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final item = ActivityModel(id: id, type: type, title: title, body: body, createdAt: now, isRead: false);
    final updated = [item, ...list];
    // keep last 100
    final trimmed = updated.length > 100 ? updated.sublist(0, 100) : updated;
    await _save(trimmed);
  }

  @override
  Future<void> markAllRead() async {
    final list = await _load();
    final updated = list.map((e) => e.copyWith(isRead: true)).toList();
    await _save(updated);
  }
}
