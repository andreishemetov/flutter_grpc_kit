import 'package:flutter_grpc_kit/flutter_grpc_kit.dart';

import 'src/generated/helloworld.pbgrpc.dart';

/// Application-facing API for the generated [GreeterClient] stub.
///
/// Widgets use this class instead of protobuf requests and responses directly.
final class GreeterGrpcClient extends GrpcServiceClient<GreeterClient> {
  GreeterGrpcClient({
    required super.channel,
    required super.executor,
    super.interceptors = const [],
  }) : super(stubFactory: GreeterClient.new);

  Future<Result<String, Exception>> sayHello({required String name}) {
    return executor.run(
      (options) => stub
          .sayHello(HelloRequest(name: name), options: options)
          .timeout(const Duration(seconds: 10)),
      transform: (reply) => reply.message,
    );
  }
}
