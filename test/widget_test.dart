import 'package:flutter_test/flutter_test.dart';
import 'package:hex_cascade/main.dart';

void main() {
  testWidgets('Smoke test - Main menu loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HexCascadeApp());
    expect(find.text('HEX\nCASCADE'), findsOneWidget);
    expect(find.text('NOVA PARTIDA'), findsOneWidget);
  });
}
