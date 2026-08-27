import 'dart:math' as math;

class VibrationDetectionEngine {
  VibrationDetectionEngine({
    double threshold = defaultStrongImpactThreshold,
    this.cooldown = const Duration(seconds: 10),
  }) : threshold = normalizeThreshold(threshold);

  static const double minimumStrongImpactThreshold = 5.0;
  static const double maximumStrongImpactThreshold = 15.0;
  static const double defaultStrongImpactThreshold = 5.0;
  static const Duration sustainedDuration = Duration(milliseconds: 200);
  static const int minimumSustainedSamples = 3;
  static const double _earthGravity = 9.8;

  double threshold;
  Duration cooldown;
  DateTime? _lastDetection;
  DateTime? _sustainedStartedAt;
  int _sustainedSamples = 0;

  static double normalizeThreshold(double value) => value
      .clamp(minimumStrongImpactThreshold, maximumStrongImpactThreshold)
      .toDouble();

  /// Fuerza neta sin gravedad, derivada de la lectura directa del acelerómetro.
  static double netAcceleration({
    required double xAxis,
    required double yAxis,
    required double zAxis,
  }) {
    final double magnitude = math.sqrt(
      (xAxis * xAxis) + (yAxis * yAxis) + (zAxis * zAxis),
    );
    return math.max(0, magnitude - _earthGravity);
  }

  void configure({double? threshold, Duration? cooldown}) {
    if (threshold != null) this.threshold = normalizeThreshold(threshold);
    if (cooldown != null) this.cooldown = cooldown;
  }

  /// Confirma fuerza neta continua sobre el umbral en cualquier dirección.
  /// Un único pico o una caída que se extingue enseguida reinicia el conteo.
  bool shouldCapture({
    required double xAxis,
    required double yAxis,
    required double zAxis,
    required DateTime timestamp,
  }) {
    if (_lastDetection != null &&
        timestamp.difference(_lastDetection!) < cooldown) {
      _resetSustain();
      return false;
    }

    final double force = netAcceleration(
      xAxis: xAxis,
      yAxis: yAxis,
      zAxis: zAxis,
    );
    if (force <= threshold) {
      _resetSustain();
      return false;
    }

    if (_sustainedStartedAt == null ||
        timestamp.isBefore(_sustainedStartedAt!)) {
      _sustainedStartedAt = timestamp;
      _sustainedSamples = 1;
      return false;
    }

    _sustainedSamples += 1;
    final Duration duration = timestamp.difference(_sustainedStartedAt!);
    if (duration < sustainedDuration ||
        _sustainedSamples < minimumSustainedSamples) {
      return false;
    }

    _lastDetection = timestamp;
    _resetSustain();
    return true;
  }

  void _resetSustain() {
    _sustainedStartedAt = null;
    _sustainedSamples = 0;
  }
}
