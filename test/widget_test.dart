// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:geovibe/models/vibration_event.dart';

void main() {
  test('el payload de un retumbo conserva los campos requeridos', () {
    final VibrationEvent event = VibrationEvent(
      timestamp: DateTime.utc(2026, 8, 26, 20, 0),
      vibrationPeak: 14.2,
      location: const ApproximateLocation(
        latitude: -34.9011,
        longitude: -56.1645,
        accuracyMeters: 82,
      ),
    );

    final Map<String, dynamic> payload = event.toFirebaseJson();

    expect(payload['timestamp'], '2026-08-26T20:00:00.000Z');
    expect(payload['vibration_peak'], 14.2);
    expect(payload['location']['latitude'], -34.9011);
  });
}
