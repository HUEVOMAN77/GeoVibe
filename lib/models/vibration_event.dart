class ApproximateLocation {
  const ApproximateLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_meters': accuracyMeters,
  };

  factory ApproximateLocation.fromMap(Map<dynamic, dynamic> data) {
    return ApproximateLocation(
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (data['accuracy_meters'] as num?)?.toDouble() ?? 0,
    );
  }
}

class VibrationEvent {
  const VibrationEvent({
    required this.timestamp,
    required this.vibrationPeak,
    this.id,
    this.location,
  });

  final String? id;
  final DateTime timestamp;
  final double vibrationPeak;
  final ApproximateLocation? location;

  Map<String, dynamic> toFirebaseJson() => <String, dynamic>{
    'timestamp': timestamp.toUtc().toIso8601String(),
    'timestamp_ms': timestamp.toUtc().millisecondsSinceEpoch,
    'vibration_peak': vibrationPeak,
    'location': location?.toJson(),
  };

  factory VibrationEvent.fromMap(Map<dynamic, dynamic> data, {String? id}) {
    final Object? locationData = data['location'];
    return VibrationEvent(
      id: id,
      timestamp:
          DateTime.tryParse(data['timestamp']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      vibrationPeak: (data['vibration_peak'] as num?)?.toDouble() ?? 0,
      location: locationData is Map
          ? ApproximateLocation.fromMap(locationData)
          : null,
    );
  }
}
