import 'package:flutter/foundation.dart';
import 'package:flutter_grpc_kit/src/logging/pretty_box_log_printer.dart';
import 'package:protobuf/protobuf.dart';

const _sensitiveMetadataKeys = {'authorization', 'token'};

final PrettyBoxLogPrinter _grpcPrettyLogger = PrettyBoxLogPrinter(
  logPrint: (message) => debugPrint(message),
);

/// Serializes complete gRPC call logs so request/response stay paired.
final class GrpcLogQueue {
  GrpcLogQueue._();

  static Future<void> _tail = Future<void>.value();

  static void enqueue(void Function() printFn) {
    _tail = _tail.then((_) {
      printFn();
    });
  }
}

/// Collects request/response output for one gRPC call and prints it atomically.
final class GrpcCallLogBuffer {
  GrpcCallLogBuffer();

  final List<String> _lines = [];
  late final PrettyBoxLogPrinter _printer = PrettyBoxLogPrinter(logPrint: _lines.add);

  void addRequest({
    required String path,
    Map<String, String>? metadata,
    Object? payload,
    String kind = 'Request',
  }) {
    _printer.printBoxed(header: '$kind ║ gRPC ', text: path);
    final maskedMetadata = maskGrpcMetadata(metadata ?? const {});
    if (maskedMetadata.isNotEmpty) {
      _printer.printMapAsTable(maskedMetadata, header: 'Metadata');
    }
    if (payload != null) {
      _printer.printBody(grpcPayloadToLogData(payload));
    }
  }

  void addResponse({
    required String path,
    required int elapsedMs,
    Object? payload,
    String status = 'OK',
  }) {
    _printer.printBoxed(
      header: 'Response ║ gRPC ║ Status: $status ║ Time: $elapsedMs ms',
      text: path,
    );
    _printer.printBody(grpcPayloadToLogData(payload));
  }

  void addError({required String path, required int elapsedMs, required Object error}) {
    _printer.printBoxed(header: 'gRPC Error ║ Time: $elapsedMs ms', text: path);
    _printer.printBody(error.toString());
  }

  void flush() {
    if (_lines.isEmpty) {
      return;
    }

    final lines = List<String>.from(_lines);
    GrpcLogQueue.enqueue(() {
      for (final line in lines) {
        debugPrint(line);
      }
    });
  }

  @visibleForTesting
  List<String> get bufferedLines => List<String>.unmodifiable(_lines);
}

Map<String, String> maskGrpcMetadata(Map<String, String> metadata) {
  if (metadata.isEmpty) {
    return const {};
  }

  return {
    for (final entry in metadata.entries)
      entry.key: _sensitiveMetadataKeys.contains(entry.key.toLowerCase()) ? '***' : entry.value,
  };
}

dynamic grpcPayloadToLogData(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is GeneratedMessage) {
    return value.toProto3Json();
  }
  return value;
}

void logGrpcRequest({
  required String path,
  Map<String, String>? metadata,
  Object? payload,
  String kind = 'Request',
}) {
  _grpcPrettyLogger.printBoxed(header: '$kind ║ gRPC ', text: path);
  final maskedMetadata = maskGrpcMetadata(metadata ?? const {});
  if (maskedMetadata.isNotEmpty) {
    _grpcPrettyLogger.printMapAsTable(maskedMetadata, header: 'Metadata');
  }
  if (payload != null) {
    _grpcPrettyLogger.printBody(grpcPayloadToLogData(payload));
  }
}
