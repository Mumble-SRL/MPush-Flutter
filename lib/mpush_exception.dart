import 'package:flutter/foundation.dart';

class MPushException implements Exception {
  String cause;

  int statusCode;

  MPushException(
      this.cause, {
        this.statusCode,
      });

  @override
  String toString() {
    return cause;
  }
}
