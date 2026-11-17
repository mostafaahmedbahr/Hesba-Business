import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/cloudinary_image_service.dart';

/// Translates cubit error keys (`saleErr*`, `retErr*`, `purchaseErr*`,
/// `supplierErr*`) with their args.
///
/// Anything else (raw Firebase/SDK messages, Arabic legacy strings) passes
/// through untouched, so catch-all handlers never show a raw key.
String translateError(String? message, [Map<String, String>? args]) {
  if (message == null || message.isEmpty) return 'errorGeneric'.tr();
  if (message.startsWith('saleErr') ||
      message.startsWith('retErr') ||
      message.startsWith('purchaseErr') ||
      message.startsWith('supplierErr')) {
    return args == null || args.isEmpty
        ? message.tr()
        : message.tr(namedArgs: args);
  }
  // Codes emitted by friendlyError() are localization keys with Arabic text
  // baked in — return them as-is. Raw legacy strings also pass through.
  return _friendlyByCode(message.toLowerCase()) ?? message;
}

/// Converts a technical exception (Firebase / network / timeout / upload) into
/// a short, understandable Arabic message safe to show to end users.
///
/// Never includes the original `toString()`, stack trace, error codes or host
/// details — those belong in AppLogger, not on the screen.
String friendlyError(Object error) {
  // Translation keys emitted by cubits are already user-safe.
  if (error is String) return translateError(error);

  if (error is CloudinaryUploadException) {
    return switch (error.code) {
      'missing-configuration' || 'invalid-response' =>
        'تعذر رفع الصورة — إعدادات الرفع غير مكتملة.',
      'file-too-large' => 'الصورة كبيرة جداً، اختر صورة أصغر.',
      'invalid-file-type' => 'صيغة الصورة غير مدعومة، اختر صورة أخرى.',
      'upload-failed' || 'preset-not-found' || 'upload-rejected' =>
        'تعذر رفع الصورة، تحقق من الاتصال وحاول مرة أخرى.',
      _ => 'تعذر رفع الصورة، حاول مرة أخرى.',
    };
  }

  if (error is TimeoutException) {
    return 'انتهت مهلة الاتصال، تحقق من الإنترنت وحاول مرة أخرى.';
  }
  if (error is SocketException) {
    return 'لا يوجد اتصال بالإنترنت، تحقق من الشبكة وحاول مرة أخرى.';
  }

  // FirebaseAuthException extends FirebaseException — one case covers both.
  final code = switch (error) {
    FirebaseException e => e.code,
    _ => '',
  };
  final mapped = _friendlyByCode(code.toLowerCase());
  if (mapped != null) return mapped;

  // FirebaseAuthException codes not covered above get an auth-specific fallback.
  if (error is FirebaseAuthException) {
    return 'تعذر إتمام عملية الحساب، حاول مرة أخرى.';
  }
  if (error is FirebaseException) {
    return 'تعذر إتمام العملية، حاول مرة أخرى.';
  }

  // Plain Exceptions thrown by our own repos are mostly already user-facing
  // Arabic validation messages ("الكمية غير متوفرة...") — keep those. Anything
  // else is treated as internal detail and replaced with a generic message.
  final text = error.toString().replaceAll('Exception: ', '');
  final isArabic = text.runes.any((r) => r >= 0x0600 && r <= 0x06FF);
  final isTechnical = text.contains('cloud_firestore/') ||
      text.contains('firebase_auth/') ||
      text.contains('Stack') ||
      text.contains('errno');
  if (isArabic && !isTechnical) return text;
  return 'errorGeneric'.tr();
}

String? _friendlyByCode(String code) {
  if (code.contains('permission-denied') ||
      code.contains('permission denied') ||
      code.contains('insufficient permission')) {
    return 'الصلاحية مرفوضة: تأكد أن حساب الموظف مُفعّل ومرتبط بالمحل، وأن اشتراك صاحب المحل ساري.';
  }
  if (code.contains('unavailable') ||
      code.contains('network-request-failed') ||
      code.contains('connection failed') ||
      code.contains('failed to load')) {
    return 'لا يوجد اتصال، تحقق من الإنترنت وحاول مرة أخرى.';
  }
  if (code.contains('deadline-exceeded') || code.contains('timed out')) {
    return 'انتهت مهلة الاتصال، حاول مرة أخرى.';
  }
  if (code.contains('aborted')) {
    return 'تعذر الحفظ بسبب تعديل متزامن، حاول مرة أخرى.';
  }
  if (code.contains('unauthenticated') ||
      code.contains('session') ||
      code.contains('user-not-found') ||
      code.contains('invalid-credential') ||
      code.contains('wrong-password') ||
      code.contains('user-disabled')) {
    return 'انتهت جلسة الدخول، سجّل الدخول مرة أخرى.';
  }
  if (code.contains('already-in-use') || code.contains('email-already-in-use')) {
    return 'البريد الإلكتروني مستخدم بالفعل.';
  }
  if (code.contains('resource-exhausted') || code.contains('too-many-requests')) {
    return 'محاولات كثيرة، حاول مرة أخرى لاحقاً.';
  }
  if (code.contains('shop-not-resolved') || code.contains('invalid-id')) {
    return 'تعذر تحديد المحل، أعد فتح الشاشة وحاول مرة أخرى.';
  }
  return null;
}
