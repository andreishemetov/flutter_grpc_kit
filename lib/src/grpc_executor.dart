import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_grpc_kit/src/auth_handler.dart';
import 'package:flutter_grpc_kit/src/result.dart';
import 'package:grpc/grpc.dart';

typedef TransformRpcResultFunc<R, D> = R Function(D data);

typedef RpcCall<D> = Future<D> Function(CallOptions options);

/// Runs unary RPCs with auth metadata, optional extra headers, and token refresh on UNAUTHENTICATED.
final class GrpcExecutor {
  GrpcExecutor({this.authHandler, this.metadata = const {}});

  final AuthHandler? authHandler;
  final Map<String, String> metadata;

  Future<String?>? _refreshTokenFuture;

  CallOptions buildCallOptions() => _buildOptions();

  Future<Result<R, Exception>> run<R, D>(
    RpcCall<D> call, {
    required TransformRpcResultFunc<R, D> transform,
  }) async {
    try {
      final result = await _run<R, D>(call, transform);
      return Success(result);
    } catch (ex, stackTrace) {
      dev.log(
        'GrpcExecutor error',
        error: ex,
        stackTrace: stackTrace,
        name: 'flutter_grpc_kit.GrpcExecutor',
      );
      var exception = Exception('Undefined RpcExecutor error: $ex');
      if (ex is GrpcError) {
        exception = ex;
        if (authHandler != null && ex.code == StatusCode.unauthenticated) {
          final refreshed = await _refreshToken();
          if (refreshed != null) {
            try {
              return Success(await _run<R, D>(call, transform));
            } catch (retryEx, retryStackTrace) {
              dev.log(
                'GrpcExecutor retry error',
                error: retryEx,
                stackTrace: retryStackTrace,
                name: 'flutter_grpc_kit.GrpcExecutor',
              );
              if (retryEx is GrpcError && retryEx.code == StatusCode.unauthenticated) {
                authHandler!.clearToken();
              } else if (retryEx is Exception) {
                exception = retryEx;
              }
            }
          } else {
            authHandler!.clearToken();
          }
        }
      } else if (ex is Exception) {
        exception = ex;
      }

      return Failure(exception);
    }
  }

  Future<T> _run<T, D>(RpcCall<D> call, TransformRpcResultFunc<T, D> transform) async {
    final options = _buildOptions();
    final data = await call(options);
    return transform(data);
  }

  CallOptions _buildOptions() {
    final token = authHandler?.getToken();
    return CallOptions(
      metadata: {
        ...metadata,
        if (token != null && token.isNotEmpty) 'token': token,
      },
    );
  }

  Future<String?> _refreshToken() {
    if (authHandler == null) return Future.value(null);

    final existing = _refreshTokenFuture;
    if (existing != null) return existing;

    final future = authHandler!.refreshToken();
    _refreshTokenFuture = future;

    unawaited(
      future.whenComplete(() {
        if (identical(_refreshTokenFuture, future)) {
          _refreshTokenFuture = null;
        }
      }),
    );
    return future;
  }
}
