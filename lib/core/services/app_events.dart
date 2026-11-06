import 'dart:async';

enum AppEventType {
  saleCreated,
  returnCreated,
  expenseCreated,
  expenseUpdated,
  expenseDeleted,
  productAdded,
  productUpdated,
  productDeleted,
  productChanged,
}

/// Simple global event bus for cross-feature refresh.
/// No external dependency, singleton + broadcast.
class AppEvents {
  AppEvents._();
  static final AppEvents instance = AppEvents._();

  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEventType type, [Map<String, dynamic>? data]) {
    if (!_controller.isClosed) {
      _controller.add(AppEvent(type, data));
    }
  }

  // Convenience helpers.
  // كل حدث بياخد `data` اختياري عشان سجل العمليات والإشعار يعرضوا تفاصيل
  // حقيقية (اسم المنتج، السعر، المكسب) بدل نص عام.
  void saleCreated([Map<String, dynamic>? data]) =>
      emit(AppEventType.saleCreated, data);
  void returnCreated([Map<String, dynamic>? data]) =>
      emit(AppEventType.returnCreated, data);
  void expenseCreated([Map<String, dynamic>? data]) =>
      emit(AppEventType.expenseCreated, data);
  void expenseUpdated([Map<String, dynamic>? data]) =>
      emit(AppEventType.expenseUpdated, data);
  void expenseDeleted([Map<String, dynamic>? data]) =>
      emit(AppEventType.expenseDeleted, data);
  void productAdded([Map<String, dynamic>? data]) =>
      emit(AppEventType.productAdded, data);
  void productUpdated([Map<String, dynamic>? data]) =>
      emit(AppEventType.productUpdated, data);
  void productDeleted([Map<String, dynamic>? data]) =>
      emit(AppEventType.productDeleted, data);
  void productChanged() => emit(AppEventType.productChanged);

  void dispose() {
    _controller.close();
  }
}

class AppEvent {
  final AppEventType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  AppEvent(this.type, [this.data]) : timestamp = DateTime.now();
}
