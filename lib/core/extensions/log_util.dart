import 'package:flutter/foundation.dart';

void logError(String msg) {
  if (kDebugMode) debugPrint('\x1B[31m$msg\x1B[0m');
}

void logSuccess(String msg) {
  if (kDebugMode) debugPrint('\x1B[32m$msg\x1B[0m');
}

void logWarning(String msg) {
  if (kDebugMode) debugPrint('\x1B[33m$msg\x1B[0m');
}