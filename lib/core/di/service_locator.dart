import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/auth/data/repos/auth_repo.dart';
import '../../features/auth/data/repos_impl/auth_repo_impl.dart';

final sl = GetIt.instance;

void initDependencies() {
  _initAuth();
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
