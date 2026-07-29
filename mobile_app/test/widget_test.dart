import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('renders the home screen app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const F1PortfolioApp());
    // Don't pumpAndSettle: the Home screen kicks off a real network call
    // on the first frame, which won't resolve in the test environment.
    await tester.pump();

    expect(find.text('F1 Portfolio'), findsOneWidget);
  });
}
