/// An exception in MPush
class MPushException implements Exception {
  /// The cause of the exception
  final String cause;

  /// The status code
  final int statusCode;

  /// Initializes a new `MPushException`
  ///
  /// @param cause The cause of the exception
  /// @param statusCode The status code of the exception
  const MPushException(
    this.cause, {
    required this.statusCode,
  });

  @override
  String toString() {
    return cause;
  }
}
