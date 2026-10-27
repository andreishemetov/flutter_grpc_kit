abstract interface class AuthHandler {
  String? getToken();
  Future<String?> refreshToken();
  void clearToken();
}
