import 'vibration_event.dart';

class EewAlert {
  const EewAlert({
    required this.id,
    required this.detectedAt,
    required this.title,
    required this.instruction,
    required this.severity,
    required this.location,
    required this.communityReports,
    this.locationName = 'Ubicación no especificada',
    this.depthKm = 0,
    this.accelerationMs2 = 0,
  });

  final String id;
  final DateTime detectedAt;
  final String title;
  final String instruction;
  final String severity;
  final ApproximateLocation location;
  final int communityReports;
  final String locationName;
  final double depthKm;
  final double accelerationMs2;

  bool get isEvacuation => severity.toLowerCase() == 'evacuate';

  factory EewAlert.fromMap(Map<Object?, Object?> raw, {String? id}) {
    final Object? rawLocation = raw['location'];
    final Map<Object?, Object?> location = rawLocation is Map
        ? rawLocation
        : <Object?, Object?>{
            'latitude': raw['latitude'],
            'longitude': raw['longitude'],
            'accuracy_meters': raw['accuracy_meters'],
          };
    final String fallbackId = DateTime.now().microsecondsSinceEpoch.toString();
    return EewAlert(
      id: id ?? raw['id']?.toString() ?? fallbackId,
      detectedAt:
          DateTime.tryParse(raw['timestamp']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      title: raw['title']?.toString() ?? 'Alerta temprana sísmica',
      instruction:
          raw['instruction']?.toString() ??
          raw['message']?.toString() ??
          'Busca resguardo y sigue indicaciones de emergencia.',
      severity: raw['severity']?.toString() ?? 'shelter',
      location: ApproximateLocation(
        latitude: _number(location['latitude']),
        longitude: _number(location['longitude']),
        accuracyMeters: _number(location['accuracy_meters']),
      ),
      communityReports: _integer(raw['community_reports']),
      locationName:
          raw['department']?.toString() ??
          raw['location_name']?.toString() ??
          raw['municipality']?.toString() ??
          raw['place']?.toString() ??
          'Ubicación no especificada',
      depthKm: _number(raw['depth_km'] ?? raw['depth']),
      accelerationMs2: _number(
        raw['acceleration_ms2'] ?? raw['acceleration'] ?? raw['vibration_peak'],
      ),
    );
  }

  static bool isEewPayload(Map<String, dynamic> data) =>
      data['type']?.toString() == 'eew' ||
      data['channel']?.toString() == 'geovibe_eew';

  static double _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  static int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}
