import 'package:flutter_test/flutter_test.dart';
import 'package:geovibe/services/emergency_alert_service.dart';

void main() {
  test('la alerta conserva el pico y la hora exacta de detección', () {
    final DateTime detectedAt = DateTime.utc(2026, 8, 26, 21, 0, 12);
    const double peak = 15.8;

    final EmergencyAlert alert = EmergencyAlert(
      peak: peak,
      detectedAt: detectedAt,
    );

    expect(alert.peak, peak);
    expect(alert.detectedAt, detectedAt);
  });

  test('la alarma se limita estrictamente a diez segundos', () {
    expect(EmergencyAlertService.alarmDuration, const Duration(seconds: 10));
  });
}
