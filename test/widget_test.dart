import 'package:flutter_test/flutter_test.dart';
import 'package:synapse_runner/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SynapseRunnerApp());
    await tester.pumpAndSettle();

    expect(find.text('Synapse Runner'), findsOneWidget);
    expect(find.text('Foundation setup complete'), findsOneWidget);
  });
}
