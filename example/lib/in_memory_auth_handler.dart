import 'package:flutter_grpc_kit/flutter_grpc_kit.dart';

/// Demo [AuthHandler] with an in-memory token you can edit in the UI.
final class InMemoryAuthHandler implements AuthHandler {
  InMemoryAuthHandler({String? token}) : _token = token;

  String? _token;

  void setToken(String? token) => _token = token;

  @override
  String? getToken() => _token;

  @override
  Future<String?> refreshToken() async {
    final current = _token;
    if (current == null || current.isEmpty) {
      return null;
    }
    _token = '$current-refreshed';
    return _token;
  }

  @override
  void clearToken() => _token = null;
}
