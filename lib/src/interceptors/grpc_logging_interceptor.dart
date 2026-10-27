import 'dart:async';

import 'package:flutter_grpc_kit/src/interceptors/grpc_log_formatter.dart';
import 'package:grpc/grpc.dart';

final class GrpcLoggingInterceptor extends ClientInterceptor {
  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    final path = method.path;
    final started = DateTime.now();
    final logBuffer = GrpcCallLogBuffer()
      ..addRequest(path: path, metadata: options.metadata, payload: request);

    final response = invoker(method, request, options);

    unawaited(
      response
          .then((result) {
            logBuffer
              ..addResponse(
                path: path,
                elapsedMs: DateTime.now().difference(started).inMilliseconds,
                payload: result,
              )
              ..flush();
          })
          .catchError((Object error) {
            logBuffer
              ..addError(
                path: path,
                elapsedMs: DateTime.now().difference(started).inMilliseconds,
                error: error,
              )
              ..flush();
          }),
    );

    return response;
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) {
    logGrpcRequest(
      path: method.path,
      metadata: options.metadata,
      payload: null,
      kind: 'Stream Request',
    );

    final wrappedRequests = requests.map((request) {
      logGrpcRequest(path: method.path, payload: request, kind: 'Stream Message');
      return request;
    });

    return invoker(method, wrappedRequests, options);
  }
}
