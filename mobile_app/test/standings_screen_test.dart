import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/constructor.dart';
import 'package:mobile_app/models/driver.dart';
import 'package:mobile_app/models/standings.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/screens/standings_screen.dart';
import 'package:mobile_app/services/api_client.dart';
import 'package:provider/provider.dart';

class _FakeApiClient extends ApiClient {
  @override
  Future<List<DriverStanding>> fetchDriverStandings(int season) async => const [
    DriverStanding(
      position: 1,
      positionText: '1',
      points: 25,
      wins: 1,
      driver: Driver(
        driverRef: 'piastri',
        givenName: 'Oscar',
        familyName: 'Piastri',
      ),
      constructor: Constructor(constructorRef: 'mclaren', name: 'McLaren'),
    ),
  ];

  @override
  Future<List<ConstructorStanding>> fetchConstructorStandings(
    int season,
  ) async => const [
    ConstructorStanding(
      position: 1,
      positionText: '1',
      points: 43,
      wins: 1,
      constructor: Constructor(constructorRef: 'mclaren', name: 'McLaren'),
    ),
  ];
}

void main() {
  testWidgets('standings screen shows drivers, switches to teams', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(home: StandingsScreen(apiClient: _FakeApiClient())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Oscar Piastri'), findsOneWidget);
    expect(find.text('25 pts'), findsOneWidget);

    await tester.tap(find.text('Teams'));
    await tester.pump();

    expect(find.text('43 pts'), findsOneWidget);
  });
}
