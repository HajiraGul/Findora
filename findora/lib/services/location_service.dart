import 'package:geolocator/geolocator.dart';

/// Outcome of a device-location request.
enum LocationStatus { ok, serviceDisabled, denied, deniedForever, error }

class LocationResult {
  final LocationStatus status;
  final double? latitude;
  final double? longitude;

  const LocationResult(this.status, {this.latitude, this.longitude});

  bool get isOk => status == LocationStatus.ok;
}

/// Thin wrapper around [Geolocator] that handles the permission flow and
/// returns a typed result so screens can fall back gracefully.
class LocationService {
  const LocationService();

  Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(
        LocationStatus.ok,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationResult(LocationStatus.error);
    }
  }
}
