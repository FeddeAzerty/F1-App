import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/circuit.dart';
import 'package:mobile_app/models/constructor.dart';
import 'package:mobile_app/models/driver.dart';
import 'package:mobile_app/models/race.dart';
import 'package:mobile_app/models/race_result.dart';
import 'package:mobile_app/widgets/race_grid_card.dart';

const _circuit = Circuit(circuitRef: 'monza', name: 'Monza', country: 'Italy');

const _podium = [
  RaceResult(
    position: 1,
    positionText: '1',
    points: 25,
    driver: Driver(driverRef: 'verstappen', givenName: 'Max', familyName: 'Verstappen', code: 'VER'),
    constructor: Constructor(constructorRef: 'red_bull', name: 'Red Bull'),
  ),
];

Race _race({required DateTime date}) => Race(
  season: date.year,
  round: 1,
  raceName: 'Test Grand Prix',
  raceDate: date,
  circuit: _circuit,
);

void main() {
  testWidgets('past race with podium data shows the podium', (tester) async {
    final race = _race(date: DateTime.now().toUtc().subtract(const Duration(days: 7)));
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RaceGridCard(race: race, podium: _podium))),
    );
    expect(find.text('VER'), findsOneWidget);
    expect(find.text('Upcoming'), findsNothing);
  });

  testWidgets('future race hides podium data and shows Upcoming', (tester) async {
    // Even though podium data is supplied (the data source may carry
    // projected results), a future-dated race must read as Upcoming.
    final race = _race(date: DateTime.now().toUtc().add(const Duration(days: 30)));
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RaceGridCard(race: race, podium: _podium))),
    );
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('VER'), findsNothing);
  });
}
