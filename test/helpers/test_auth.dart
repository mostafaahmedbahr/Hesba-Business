import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements User {}

/// حساب مسجّل دخول بـ uid ثابت.
FirebaseAuth signedInAuth(String uid) {
  final auth = MockFirebaseAuth();
  final user = MockFirebaseUser();
  when(() => user.uid).thenReturn(uid);
  when(() => auth.currentUser).thenReturn(user);
  return auth;
}

/// حساب غير مسجّل دخول.
FirebaseAuth signedOutAuth() {
  final auth = MockFirebaseAuth();
  when(() => auth.currentUser).thenReturn(null);
  return auth;
}
