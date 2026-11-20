import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesba/core/services/cloudinary_image_service.dart';
import 'package:hesba/core/utils/error_message.dart';

/// User-facing error text must be understandable Arabic, never raw SDK codes
/// or internal details.
void main() {
  test('maps Firestore unavailable to a network message', () {
    final msg = friendlyError(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
    expect(msg, contains('اتصال'));
    expect(msg, isNot(contains('cloud_firestore')));
    expect(msg, isNot(contains('unavailable')));
  });

  test('maps deadline-exceeded to a timeout message', () {
    final msg = friendlyError(
      FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded'),
    );
    expect(msg, contains('مهلة'));
    expect(msg, isNot(contains('deadline-exceeded')));
  });

  test('maps permission-denied to the existing Arabic explanation', () {
    final msg = friendlyError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    expect(msg, contains('الصلاحية مرفوضة'));
    //Must not assume the caller is a staff account — owners see this too.
    expect(msg, isNot(contains('الموظف')));
    expect(msg, isNot(contains('صاحب المحل')));
  });

  test('maps auth session expiry without leaking the code', () {
    final msg = friendlyError(
      FirebaseAuthException(code: 'user-disabled'),
    );
    expect(msg, contains('جلسة'));
    expect(msg, isNot(contains('user-disabled')));
  });

  test('maps network and timeout exceptions', () {
    expect(friendlyError(const SocketException('failed')), contains('اتصال'));
    expect(
      friendlyError(TimeoutException('too slow', const Duration(seconds: 1))),
      contains('مهلة'),
    );
  });

  test('maps Cloudinary upload errors by code', () {
    expect(
      friendlyError(const CloudinaryUploadException('upload-failed', 'raw body')),
      contains('رفع الصورة'),
    );
    expect(
      friendlyError(const CloudinaryUploadException('missing-configuration')),
      isNot(contains('CLOUDINARY')),
    );
  });

  test('keeps repository-authored Arabic validation messages', () {
    final arabic = Exception('الكمية المطلوبة غير متوفرة (المتاح: 2)');
    expect(friendlyError(arabic), arabic.toString().replaceAll('Exception: ', ''));
  });

  test('hides generic technical exception text', () {
    final msg = friendlyError(Exception('boom: [cloud_firestore/x] null'));
    expect(msg, isNot(contains('boom')));
    expect(msg, isNot(contains('cloud_firestore')));
  });

  test('translateError still handles localization keys', () {
    expect(translateError('permission-denied'), contains('الصلاحية مرفوضة'));
    expect(translateError('unavailable'), contains('اتصال'));
  });
}
