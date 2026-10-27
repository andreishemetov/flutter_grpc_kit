import 'package:flutter_grpc_kit/src/grpc_endpoint.dart';
import 'package:grpc/grpc.dart';

/// Creates and owns [ClientChannel] instances for gRPC gateways.
final class GrpcChannelFactory {
  GrpcChannelFactory({required String gatewayUrl})
    : _endpoint = GrpcEndpoint.fromGatewayUrl(gatewayUrl);

  final GrpcEndpoint _endpoint;
  ClientChannel? _channel;

  GrpcEndpoint get endpoint => _endpoint;

  ClientChannel get channel {
    return _channel ??= ClientChannel(
      _endpoint.host,
      port: _endpoint.port,
      options: ChannelOptions(
        credentials: _endpoint.useTls
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
      ),
    );
  }

  Future<void> dispose() async {
    final active = _channel;
    _channel = null;
    if (active != null) {
      await active.shutdown();
    }
  }
}
