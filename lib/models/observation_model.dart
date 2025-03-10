import 'dart:typed_data';

class Observation {
  final int? id;
  final String tag;
  final DateTime date;
  final double latitude;
  final double longitude;
  final String address;
  final Uint8List image;
  final Uint8List zoom;
  final int pixelColor;

  Observation({
    this.id,
    required this.tag,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.image,
    required this.zoom,
    required this.pixelColor,
  });

  factory Observation.fromJson(Map<String, dynamic> json) => Observation(
        id: json['id'],
        tag: json['tag'],
        date: DateTime.parse(json['date']),
        latitude: json['latitude'],
        longitude: json['longitude'],
        address: json['address'],
        image: json['image'],
        zoom: json['zoom'],
        pixelColor: json['pixelColor'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tag': tag,
        'date': date.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'image': image,
        'zoom': zoom,
        'pixelColor': pixelColor,
      };

  Observation copyWith({
    int? id,
    String? tag,
    DateTime? date,
    double? latitude,
    double? longitude,
    String? address,
    Uint8List? image,
    Uint8List? zoom,
    int? pixelColor,
  }) {
    return Observation(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      date: date ?? this.date,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      image: image ?? this.image,
      zoom: zoom ?? this.zoom,
      pixelColor: pixelColor ?? this.pixelColor,
    );
  }
}
