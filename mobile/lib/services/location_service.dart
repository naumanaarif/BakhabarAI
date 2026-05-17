import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  factory LocationService() => instance;

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;
    
    try {
      // 1. Instantly try last known position to bypass GPS locking delay
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) return position;
      
      // 2. Fallback to quick low-accuracy request first to prevent timeouts
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 3),
      );
    } catch (_) {
      try {
        // 3. Final fallback
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.lowest,
          timeLimit: const Duration(seconds: 2),
        );
      } catch (e) {
        return null;
      }
    }
  }
}
