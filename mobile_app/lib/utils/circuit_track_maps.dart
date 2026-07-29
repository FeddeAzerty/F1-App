/// Jolpica `circuit_ref` values that have a bundled track outline SVG in
/// `assets/circuits/{circuit_ref}.svg`. Sourced from f1db/f1db (CC BY 4.0) -
/// see `assets/circuits/LICENSE.md`. Only covers circuits on recent/current
/// calendars; anything missing here just falls back to the live map.
const Set<String> circuitsWithTrackMap = {
  'albert_park',
  'shanghai',
  'suzuka',
  'miami',
  'villeneuve',
  'monaco',
  'catalunya',
  'red_bull_ring',
  'silverstone',
  'spa',
  'hungaroring',
  'zandvoort',
  'monza',
  'baku',
  'marina_bay',
  'americas',
  'rodriguez',
  'interlagos',
  'vegas',
  'losail',
  'yas_marina',
  'bahrain',
  'jeddah',
};

/// Track outline asset for a circuit. `dark: true` returns the
/// white-line variant (for dark backgrounds); the default is the
/// black-line variant. Returns null if we have no diagram for this circuit.
String? trackMapAssetFor(String circuitRef, {bool dark = false}) {
  if (!circuitsWithTrackMap.contains(circuitRef)) return null;
  return dark
      ? 'assets/circuits/dark/$circuitRef.svg'
      : 'assets/circuits/$circuitRef.svg';
}
