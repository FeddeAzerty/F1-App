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

String? trackMapAssetFor(String circuitRef, {bool dark = false}) {
  if (!circuitsWithTrackMap.contains(circuitRef)) return null;
  return dark
      ? 'assets/circuits/dark/$circuitRef.svg'
      : 'assets/circuits/$circuitRef.svg';
}
