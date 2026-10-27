import 'package:flutter_grpc_kit/flutter_grpc_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GrpcEndpoint.fromGatewayUrl', () {
    test('parses http loopback URL as insecure with explicit port', () {
      final endpoint = GrpcEndpoint.fromGatewayUrl('http://127.0.0.1:1080');

      expect(endpoint.host, '127.0.0.1');
      expect(endpoint.port, 1080);
      expect(endpoint.useTls, isFalse);
    });

    test('parses https host without port as TLS on 443', () {
      final endpoint = GrpcEndpoint.fromGatewayUrl('https://host');

      expect(endpoint.host, 'host');
      expect(endpoint.port, 443);
      expect(endpoint.useTls, isTrue);
    });

    test('parses bare host:port without scheme as TLS', () {
      final endpoint = GrpcEndpoint.fromGatewayUrl('host:8099');

      expect(endpoint.host, 'host');
      expect(endpoint.port, 8099);
      expect(endpoint.useTls, isTrue);
    });

    test('throws for empty gateway URL', () {
      expect(() => GrpcEndpoint.fromGatewayUrl(''), throwsA(isA<FormatException>()));
    });
  });
}
