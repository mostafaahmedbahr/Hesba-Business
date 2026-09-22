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

  // Convenience helpers
  void saleCreated() => emit(AppEventType.saleCreated);
  void returnCreated() => emit(AppEventType.returnCreated);
  void expenseCreated() => emit(AppEventType.expenseCreated);
  void expenseUpdated() => emit(AppEventType.expenseUpdated);
  void expenseDeleted() => emit(AppEventType.expenseDeleted);
  void productAdded() => emit(AppEventType.productAdded);
  void productUpdated() => emit(AppEventType.productUpdated);
  void productDeleted() => emit(AppEventType.productDeleted);
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
