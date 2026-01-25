class OfficeLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  
  OfficeLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });
  
  factory OfficeLocation.fromJson(Map<String, dynamic> json) {
    return OfficeLocation(
      id: json['id'],
      name: json['name'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radiusMeters: json['radius_meters'],
    );
  }
}
