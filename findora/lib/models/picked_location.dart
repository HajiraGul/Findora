/// A location chosen on the map picker — carries both a human-readable
/// address and the precise coordinates so posts can be queried by distance.
class PickedLocation {
  final String address;
  final double latitude;
  final double longitude;

  const PickedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  /// Shape the backend expects for an item's `location` field.
  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}
