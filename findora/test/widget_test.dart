import 'package:flutter_test/flutter_test.dart';

import 'package:findora/main.dart';

void main() {
  testWidgets('Findora app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const FindoraApp());

    expect(find.text('Findora'), findsWidgets);
  });
}
