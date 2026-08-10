import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('renders the home screen app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const F1PortfolioApp());

    await tester.pump();

    expect(find.text('F1 Portfolio'), findsOneWidget);
  });
}
