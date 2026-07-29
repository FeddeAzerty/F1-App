import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/circuit.dart';
import 'package:mobile_app/models/constructor.dart';
import 'package:mobile_app/models/driver.dart';
import 'package:mobile_app/models/race.dart';
import 'package:mobile_app/models/race_detail.dart';
import 'package:mobile_app/models/race_result.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/screens/race_detail_screen.dart';
import 'package:mobile_app/services/api_client.dart';
import 'package:provider/provider.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this._detail);
  final RaceDetail _detail;

  @override
  Future<RaceDetail> fetchRaceDetail(int season, int round) async => _detail;
}

RaceDetail _sampleDetail() {
  const circuit = Circuit(
    circuitRef: 'albert_park',
    name: 'Albert Park Grand Prix Circuit',
    locality: 'Melbourne',
    country: 'Australia',
    latitude: -37.8497,
    longitude: 144.968,
  );
  final race = Race(
    season: 2026,
    round: 1,
    raceName: 'Australian Grand Prix',
    raceDate: DateTime.utc(2026, 3, 8),
    circuit: circuit,
  );
  const winnerDriver = Driver(
    driverRef: 'russell',
    givenName: 'George',
    familyName: 'Russell',
  );
  const mercedes = Constructor(constructorRef: 'mercedes', name: 'Mercedes');
  const winnerResult = RaceResult(
    position: 1,
    positionText: '1',
    points: 25,
    driver: winnerDriver,
    constructor: mercedes,
    finishTime: '1:23:06.801',
    fastestLapRank: 1,
    fastestLapTime: '1:22.670',
  );

  const secondDriver = Driver(
    driverRef: 'verstappen',
    givenName: 'Max',
    familyName: 'Verstappen',
  );
  const redBull = Constructor(constructorRef: 'red_bull', name: 'Red Bull');
  const secondResult = RaceResult(
    position: 2,
    positionText: '2',
    points: 18,
    driver: secondDriver,
    constructor: redBull,
    finishTime: '+2.974',
  );

  return RaceDetail(race: race, results: [winnerResult, secondResult]);
}

void main() {
  testWidgets('renders circuit and results from injected data, no network', (
    tester,
  ) async {
    // Tall viewport so every result row is mounted (a plain ListView still
    // only builds elements within the viewport + cache extent) rather than
    // needing to scroll to find off-screen rows.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final detail = _sampleDetail();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: RaceDetailScreen(
            season: 2026,
            round: 1,
            raceNameFallback: 'Australian Grand Prix',
            apiClient: _FakeApiClient(detail),
          ),
        ),
      ),
    );

    // Avoid pumpAndSettle: the embedded map can keep scheduling frames.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Albert Park Grand Prix Circuit'), findsOneWidget);
    expect(find.text('Melbourne, Australia'), findsOneWidget);

    // Winner banner
    expect(find.text('Winner'), findsOneWidget);
    // Winner's finish time appears twice: banner + results list row.
    expect(find.text('1:23:06.801'), findsNWidgets(2));
    expect(find.textContaining('Fastest lap: George Russell'), findsOneWidget);

    // Winner appears twice: once in the banner, once in the results list.
    expect(find.text('George Russell'), findsNWidgets(2));
    expect(find.text('Max Verstappen'), findsOneWidget);
    expect(find.text('+2.974'), findsOneWidget);
    expect(find.text('25 pts'), findsOneWidget);
    expect(find.text('18 pts'), findsOneWidget);
  });
}
