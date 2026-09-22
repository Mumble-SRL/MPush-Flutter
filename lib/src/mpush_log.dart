import 'package:flutter/foundation.dart';

/// Whether verbose plugin logs are enabled.
///
/// Mirrored by `MPush.isLogEnabled`. Kept here, rather than on `MPush`
/// itself, so both `mpush.dart` and `mpush_api.dart` can log without either
/// importing the other.
bool mpushLogEnabled = false;

/// Logs only where a log belongs.
///
/// `debugPrint` survives into release builds, and these lines carry device
/// tokens and whole request bodies — so they are gated on the debug build, and
/// the ones that would print a token print only its tail.
void mpushLog(String message) {
  if (kDebugMode && mpushLogEnabled) debugPrint(message);
}

/// A token, short enough to tell two apart and too short to use.
String mpushRedact(Object? token) {
  String text = token?.toString() ?? '';

  return text.length <= 8 ? '<token>' : '…${text.substring(text.length - 6)}';
}
