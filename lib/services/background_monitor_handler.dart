import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../firebase_options.dart';
import '../models/vibration_event.dart';
import 'detection_engine.dart';
import 'emergency_alert_service.dart';
import 'vibration_repository.dart';

@pragma('vm:entry-point')
void startGeoVibeMonitoringTask() {
  FlutterForegroundTask.setTaskHandler(GeoVibeMonitoringTask());
}

class GeoVibeMonitoringTask extends TaskHandler {
  static const String _thresholdKey = 'geovibe.threshold';
  static const String _cooldownKey = 'geovibe.cooldown_seconds';

  final VibrationDetectionEngine _detector = VibrationDetectionEngine();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  VibrationRepository? _repository;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _repository = VibrationRepository(FirebaseDatabase.instance);
      await EmergencyAlertService.initialize();

      final double? storedThreshold =
          await FlutterForegroundTask.getData<double>(key: _thresholdKey);
      final int? storedCooldown = await FlutterForegroundTask.getData<int>(
        key: _cooldownKey,
      );
      _detector.configure(
        threshold: storedThreshold,
        cooldown: storedCooldown == null
            ? null
            : Duration(seconds: storedCooldown),
      );

      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onAccelerometerReading, onError: _onSensorError);
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'kind': 'service',
        'active': true,
      });
    } catch (error) {
      _sendError('No se pudo iniciar el monitor: $error');
    }
  }

  void _onAccelerometerReading(AccelerometerEvent event) {
    final DateTime now = DateTime.now().toUtc();
    final double force = VibrationDetectionEngine.netAcceleration(
      xAxis: event.x,
      yAxis: event.y,
      zAxis: event.z,
    );
    FlutterForegroundTask.sendDataToMain(<String, dynamic>{
      'kind': 'reading',
      'x': event.x,
      'y': event.y,
      'z': event.z,
      'force': force,
      'timestamp': now.toIso8601String(),
    });

    if (_detector.shouldCapture(
      xAxis: event.x,
      yAxis: event.y,
      zAxis: event.z,
      timestamp: now,
    )) {
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'kind': 'emergency',
        'peak': force,
        'timestamp': now.toIso8601String(),
      });
      unawaited(EmergencyAlertService.trigger(peak: force));
      unawaited(_publishPeak(force, now));
    }
  }

  void _onSensorError(Object error, StackTrace stackTrace) {
    _sendError('El acelerómetro no está disponible: $error');
  }

  Future<void> _publishPeak(double peak, DateTime timestamp) async {
    try {
      final ApproximateLocation? location = await _getApproximateLocation();
      final VibrationEvent event = VibrationEvent(
        timestamp: timestamp,
        vibrationPeak: peak,
        location: location,
      );
      final String id = await _repository!.publish(event);
      await FlutterForegroundTask.updateService(
        notificationTitle: 'GeoVibe · pico registrado',
        notificationText: '${peak.toStringAsFixed(2)} m/s² enviado',
      );
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'kind': 'event',
        'id': id,
        'event': event.toFirebaseJson(),
      });
    } catch (error) {
      _sendError('El pico se detectó, pero no pudo sincronizarse: $error');
    }
  }

  Future<ApproximateLocation?> _getApproximateLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return ApproximateLocation(
        latitude: double.parse(position.latitude.toStringAsFixed(4)),
        longitude: double.parse(position.longitude.toStringAsFixed(4)),
        accuracyMeters: position.accuracy,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final Object? threshold = data['threshold'];
    final Object? cooldownSeconds = data['cooldownSeconds'];
    _detector.configure(
      threshold: threshold is num ? threshold.toDouble() : null,
      cooldown: cooldownSeconds is num
          ? Duration(seconds: cooldownSeconds.toInt())
          : null,
    );
  }

  void _sendError(String message) {
    FlutterForegroundTask.sendDataToMain(<String, dynamic>{
      'kind': 'error',
      'message': message,
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
