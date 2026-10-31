import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_grpc_kit_example/main.dart';

void main() {
  testWidgets('shows SayHello button', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text('SayHello'), findsOneWidget);
    expect(find.text('GrpcServiceClient example'), findsOneWidget);
  });
}
