class TodoServiceException implements Exception {
  final String message;
  final dynamic originalError;

  TodoServiceException(this.message, {this.originalError});

  @override
  String toString() {
    if (originalError != null) {
      return 'TodoServiceException: $message (Original Error: $originalError)';
    }
    return 'TodoServiceException: $message';
  }
}
