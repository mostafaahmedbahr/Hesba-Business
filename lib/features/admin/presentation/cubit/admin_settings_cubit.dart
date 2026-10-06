import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/admin_settings.dart';
import '../../data/repos/admin_repo.dart';

abstract class AdminSettingsState extends Equatable {
  const AdminSettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsLoading extends AdminSettingsState {}

class SettingsLoaded extends AdminSettingsState {
  const SettingsLoaded(this.settings);
  final AdminSettings settings;
  @override
  List<Object?> get props => [settings];
}

class SettingsSaving extends AdminSettingsState {}

class SettingsSaved extends AdminSettingsState {
  const SettingsSaved(this.settings);
  final AdminSettings settings;
  @override
  List<Object?> get props => [settings];
}

class SettingsError extends AdminSettingsState {
  const SettingsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AdminSettingsCubit extends Cubit<AdminSettingsState> {
  AdminSettingsCubit({required this.repo}) : super(SettingsLoading());
  final AdminRepo repo;

  Future<void> load() async {
    emit(SettingsLoading());
    try {
      emit(SettingsLoaded(await repo.getSettings()));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> save(AdminSettings settings) async {
    emit(SettingsSaving());
    try {
      await repo.saveSettings(settings);
      emit(SettingsSaved(settings));
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
