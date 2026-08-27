import 'package:flutter_test/flutter_test.dart';
import 'package:geovibe/services/detection_engine.dart';

void main() {
  group('VibrationDetectionEngine', () {
    test('calcula la fuerza neta descontando gravedad', () {
      expect(
        VibrationDetectionEngine.netAcceleration(
          xAxis: 0,
          yAxis: 0,
          zAxis: 9.8,
        ),
        0,
      );
      expect(
        VibrationDetectionEngine.netAcceleration(
          xAxis: 14.8,
          yAxis: 0,
          zAxis: 0,
        ),
        closeTo(5, 0.001),
      );
    });

    test('confirma vibración continua de 200 ms en cualquier eje', () {
      final VibrationDetectionEngine engine = VibrationDetectionEngine();
      final DateTime now = DateTime.utc(2026, 8, 27);

      expect(engine.threshold, 5.0);
      expect(
        engine.shouldCapture(xAxis: 15, yAxis: 0, zAxis: 0, timestamp: now),
        isFalse,
      );
      expect(
        engine.shouldCapture(
          xAxis: 0,
          yAxis: 15.5,
          zAxis: 0,
          timestamp: now.add(const Duration(milliseconds: 100)),
        ),
        isFalse,
      );
      expect(
        engine.shouldCapture(
          xAxis: 0,
          yAxis: 0,
          zAxis: 16,
          timestamp: now.add(const Duration(milliseconds: 200)),
        ),
        isTrue,
      );
    });

    test('descarta un pico aislado que termina en un milisegundo', () {
      final VibrationDetectionEngine engine = VibrationDetectionEngine();
      final DateTime now = DateTime.utc(2026, 8, 27);

      expect(
        engine.shouldCapture(xAxis: 20, yAxis: 0, zAxis: 0, timestamp: now),
        isFalse,
      );
      expect(
        engine.shouldCapture(
          xAxis: 0,
          yAxis: 0,
          zAxis: 9.8,
          timestamp: now.add(const Duration(milliseconds: 1)),
        ),
        isFalse,
      );
    });

    test('reinicia la confirmación cuando la fuerza baja antes de 200 ms', () {
      final VibrationDetectionEngine engine = VibrationDetectionEngine();
      final DateTime now = DateTime.utc(2026, 8, 27);

      expect(
        engine.shouldCapture(xAxis: 16, yAxis: 0, zAxis: 0, timestamp: now),
        isFalse,
      );
      expect(
        engine.shouldCapture(
          xAxis: 0,
          yAxis: 0,
          zAxis: 9.8,
          timestamp: now.add(const Duration(milliseconds: 150)),
        ),
        isFalse,
      );
      expect(
        engine.shouldCapture(
          xAxis: 16,
          yAxis: 0,
          zAxis: 0,
          timestamp: now.add(const Duration(milliseconds: 210)),
        ),
        isFalse,
      );
    });

    test('respeta el período de enfriamiento tras una detección', () {
      final VibrationDetectionEngine engine = VibrationDetectionEngine(
        cooldown: const Duration(seconds: 10),
      );
      final DateTime now = DateTime.utc(2026, 8, 27);

      for (final int milliseconds in <int>[0, 100, 200]) {
        engine.shouldCapture(
          xAxis: 16,
          yAxis: 0,
          zAxis: 0,
          timestamp: now.add(Duration(milliseconds: milliseconds)),
        );
      }
      expect(
        engine.shouldCapture(
          xAxis: 16,
          yAxis: 0,
          zAxis: 0,
          timestamp: now.add(const Duration(seconds: 2)),
        ),
        isFalse,
      );
    });

    test('mantiene la calibración entre 5 y 15 m/s²', () {
      final VibrationDetectionEngine low = VibrationDetectionEngine(
        threshold: 1,
      );
      final VibrationDetectionEngine high = VibrationDetectionEngine(
        threshold: 30,
      );

      expect(low.threshold, 5.0);
      expect(high.threshold, 15.0);
    });
  });
}
