import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Asks for location (the OS shows its own prompt the first time).
/// Used only to work out distance bands — exact location is never shown
/// to anyone. Returns whether access was granted.
Future<bool> askLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  } catch (e) {
    debugPrint('[location] $e'); // tests / unsupported platforms
    return false;
  }
}
