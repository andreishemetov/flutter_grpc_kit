/// Parsed host/port/TLS settings for a gRPC gateway URL.
final class GrpcEndpoint {
  const GrpcEndpoint({required this.host, required this.port, required this.useTls});

  final String host;
  final int port;
  final bool useTls;

  /// Parses an HTTP(S) gateway URL or bare `host[:port]` such as
  /// `https://grpc.example.com:443` or `grpc.example.com:8099`.
  ///
  /// Scheme-less values default to TLS. Use explicit `http://` for plaintext.
  factory GrpcEndpoint.fromGatewayUrl(String gatewayUrl) {
    final trimmed = gatewayUrl.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Invalid gRPC gateway URL: $gatewayUrl');
    }

    final uri = _parseGatewayUri(trimmed);
    final host = uri.host;
    if (host.isEmpty) {
      throw FormatException('Invalid gRPC gateway URL: $gatewayUrl');
    }

    final hasExplicitScheme = _hasAbsoluteUrlScheme(trimmed);
    final useTls = hasExplicitScheme
        ? uri.scheme == 'https' || uri.scheme == 'grpcs'
        : uri.port != 80;
    final port = uri.hasPort ? uri.port : (useTls ? 443 : 80);

    return GrpcEndpoint(host: host, port: port, useTls: useTls);
  }

  static bool _hasAbsoluteUrlScheme(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('grpcs://');
  }

  static Uri _parseGatewayUri(String value) {
    if (_hasAbsoluteUrlScheme(value)) {
      return Uri.parse(value);
    }
    return Uri.parse('//$value');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrpcEndpoint &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          port == other.port &&
          useTls == other.useTls;

  @override
  int get hashCode => Object.hash(host, port, useTls);
}
