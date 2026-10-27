import 'package:flutter_grpc_kit/flutter_grpc_kit.dart';
import 'package:flutter_grpc_kit/src/logging/pretty_box_log_printer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('maskGrpcMetadata', () {
    test('masks authorization metadata', () {
      expect(maskGrpcMetadata({'token': 'secret', 'language': 'en'}), {
        'token': '***',
        'language': 'en',
      });
    });
  });

  group('GrpcCallLogBuffer', () {
    test('buffers request before response', () {
      final buffer = GrpcCallLogBuffer()
        ..addRequest(
          path: '/demo.Service/Do',
          metadata: {'language': 'en'},
          payload: {'foo': 'bar'},
        )
        ..addResponse(path: '/demo.Service/Do', elapsedMs: 12, payload: {'ok': true});

      final lines = buffer.bufferedLines;
      final requestIndex = lines.indexWhere((line) => line.contains('╔╣ Request ║ gRPC'));
      final responseIndex = lines.indexWhere((line) => line.contains('╔╣ Response ║ gRPC'));

      expect(requestIndex, isNot(-1));
      expect(responseIndex, isNot(-1));
      expect(requestIndex, lessThan(responseIndex));
    });
  });

  group('PrettyBoxLogPrinter', () {
    test('prints REST-style boxed output', () {
      final lines = <String>[];

      PrettyBoxLogPrinter(logPrint: lines.add)
        ..printBoxed(header: 'Request ║ gRPC ', text: '/demo.Service/Do')
        ..printMapAsTable({'language': 'en'}, header: 'Metadata')
        ..printBody({'foo': 'bar'});

      expect(lines.any((line) => line.contains('╔╣ Request ║ gRPC')), isTrue);
      expect(lines.any((line) => line.contains('╔ Body')), isTrue);
    });
  });
}
