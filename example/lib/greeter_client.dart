import 'package:flutter_grpc_kit/flutter_grpc_kit.dart';

import 'src/generated/helloworld.pbgrpc.dart';

final class ExampleGreeterClient extends GrpcServiceClient<GreeterClient> {
  ExampleGreeterClient({
    required super.channel,
    required super.executor,
    super.interceptors = const [],
  }) : super(stubFactory: GreeterClient.new);

  Future<Result<String, Exception>> sayHello(String name) {
    return executor.run(
      (options) => stub.sayHello(HelloRequest(name: name), options: options),
      transform: (reply) => reply.message,
    );
  }
}
