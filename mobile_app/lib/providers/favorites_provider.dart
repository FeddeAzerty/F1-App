import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists starred drivers and constructors locally (shared_preferences),
/// so favorites survive app restarts. Kept intentionally simple: two sets
/// of refs, no backend involvement.
class FavoritesProvider extends ChangeNotifier {
  static const _driversKey = 'favorite_drivers';
  static const _constructorsKey = 'favorite_constructors';

  Set<String> _drivers = {};
  Set<String> _constructors = {};
  SharedPreferences? _prefs;

  Set<String> get driverRefs => _drivers;
  Set<String> get constructorRefs => _constructors;

  bool isDriverFavorite(String ref) => _drivers.contains(ref);
  bool isConstructorFavorite(String ref) => _constructors.contains(ref);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _drivers = (_prefs!.getStringList(_driversKey) ?? const []).toSet();
    _constructors = (_prefs!.getStringList(_constructorsKey) ?? const []).toSet();
    notifyListeners();
  }

  Future<void> toggleDriver(String ref) async {
    _drivers.contains(ref) ? _drivers.remove(ref) : _drivers.add(ref);
    await _prefs?.setStringList(_driversKey, _drivers.toList());
    notifyListeners();
  }

  Future<void> toggleConstructor(String ref) async {
    _constructors.contains(ref)
        ? _constructors.remove(ref)
        : _constructors.add(ref);
    await _prefs?.setStringList(_constructorsKey, _constructors.toList());
    notifyListeners();
  }
}
