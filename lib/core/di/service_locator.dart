import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/repos/auth_repo.dart';
import '../../features/auth/data/repos_impl/auth_repo_impl.dart';
import '../../features/contact/data/repos/contact_repo.dart';
import '../../features/contact/data/repos_impl/contact_repo_impl.dart';
import '../../features/dashboard/data/repos/dashboard_repo.dart';
import '../../features/dashboard/data/repos_impl/dashboard_repo_impl.dart';
import '../../features/profile/data/repos/account_repo.dart';
import '../../features/profile/data/repos_impl/account_repo_impl.dart';
import '../../features/settings/data/repos/preferences_repo.dart';
import '../../features/settings/data/repos_impl/preferences_repo_impl.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  _initAuth();
  _initSettings();
  _initProfile();
  _initContact();
  _initDashboard();
}

void _initAuth() {
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  sl.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  );
}

void _initSettings() {
  sl.registerLazySingleton<PreferencesRepo>(
    () => PreferencesRepoImpl(sl<SharedPreferences>()),
  );
}

void _initProfile() {
  sl.registerLazySingleton<AccountRepo>(
    () => AccountRepoImpl(
      auth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
}

void _initContact() {
  sl.registerLazySingleton<ContactRepo>(
        () => ContactRepoImpl(
      auth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
}

void _initDashboard() {
  sl.registerLazySingleton<DashboardRepo>(
    () => DashboardRepoImpl(
      auth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
}