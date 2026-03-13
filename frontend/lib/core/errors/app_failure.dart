class AppFailure implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const AppFailure({
    required this.message,
    this.code,
    this.cause,
  });

  @override
  String toString() => 'AppFailure(code: $code, message: $message)';
}
