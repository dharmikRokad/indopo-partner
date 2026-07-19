class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'A server error occurred. Please try again.']);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication failed. Please check your credentials.']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection. Please check your network.']);

  @override
  String toString() => message;
}
