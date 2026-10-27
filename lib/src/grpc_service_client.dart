import 'package:flutter/foundation.dart';
import 'package:flutter_grpc_kit/src/grpc_executor.dart';
import 'package:grpc/grpc.dart';

typedef GrpcStubFactory<TStub> =
    TStub Function(ClientChannel channel, {List<ClientInterceptor> interceptors});

typedef GrpcClientInterceptors = List<ClientInterceptor>;

/// Shared wiring for generated gRPC service clients.
abstract base class GrpcServiceClient<TStub> {
  GrpcServiceClient({
    required ClientChannel channel,
    required GrpcExecutor executor,
    GrpcClientInterceptors interceptors = const [],
    TStub? stub,
    required GrpcStubFactory<TStub> stubFactory,
  }) : _executor = executor,
       _stub = stub ?? stubFactory(channel, interceptors: interceptors);

  final GrpcExecutor _executor;
  final TStub _stub;

  @protected
  GrpcExecutor get executor => _executor;

  @protected
  TStub get stub => _stub;
}
