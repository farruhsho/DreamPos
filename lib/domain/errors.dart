/// Business rule violation with a user-facing message in the UI language
/// (built with `L.current`, see docs/L10N.md).
class BusinessException implements Exception {
  BusinessException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}
