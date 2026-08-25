class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});

  final String placeId;
  final String description;

  @override
  String toString() => description;
}

class PlaceDetails {
  const PlaceDetails({
    required this.name,
    required this.address,
    required this.openingHoursText,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final String openingHoursText;
  final double? latitude;
  final double? longitude;
}
