/// Business rule violation with a user-facing (Russian) message.
class BusinessException implements Exception {
  BusinessException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}
