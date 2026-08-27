import 'package:flutter_test/flutter_test.dart';
import 'package:geovibe/models/eew_alert.dart';

void main() {
  test('convierte un aviso comunitario de evacuación en un evento EEW', () {
    final EewAlert alert = EewAlert.fromMap(<Object?, Object?>{
      'timestamp': '2026-08-26T22:00:00.000Z',
      'title': 'Sismo regional detectado',
      'instruction': 'Evacúa hacia una zona segura.',
      'severity': 'evacuate',
      'community_reports': 18,
      'department': 'San Salvador',
      'depth_km': 12.5,
      'acceleration_ms2': 5.8,
      'location': <Object?, Object?>{
        'latitude': -34.9011,
        'longitude': -56.1645,
        'accuracy_meters': 250,
      },
    }, id: 'eew-001');

    expect(alert.id, 'eew-001');
    expect(alert.isEvacuation, isTrue);
    expect(alert.communityReports, 18);
    expect(alert.location.latitude, -34.9011);
    expect(alert.locationName, 'San Salvador');
    expect(alert.depthKm, 12.5);
    expect(alert.accelerationMs2, 5.8);
  });

  test('reconoce únicamente los payloads de la red EEW', () {
    expect(EewAlert.isEewPayload(<String, dynamic>{'type': 'eew'}), isTrue);
    expect(
      EewAlert.isEewPayload(<String, dynamic>{'channel': 'geovibe_eew'}),
      isTrue,
    );
    expect(
      EewAlert.isEewPayload(<String, dynamic>{'type': 'ordinary'}),
      isFalse,
    );
  });
}
