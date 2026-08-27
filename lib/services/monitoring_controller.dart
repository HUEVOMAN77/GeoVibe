import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vibration_event.dart';
import 'background_monitor_handler.dart';
import 'detection_engine.dart';
import 'emergency_alert_service.dart';
import 'vibration_repository.dart';

class MonitoringController extends ChangeNotifier {
  MonitoringController({VibrationRepository? repository})
    : _repository =
          repository ?? VibrationRepository(FirebaseDatabase.instance);

  static const String _thresholdKey = 'geovibe.threshold';
  static const String _calibrationVersionKey = 'geovibe.calibration_version';
  static const String _deviceProfileKey = 'geovibe.calibration_device';
  static const String _historyStartedAtKey = 'geovibe.history_started_at';
  static const int _calibrationVersion = 3;
  static const String _cooldownKey = 'geovibe.cooldown_seconds';

  final VibrationRepository _repository;
  StreamSubscription<List<VibrationEvent>>? _historySubscription;
  Timer? _alertOverlayTimer;

  bool _isActive = false;
  bool _isReady = false;
  String _deviceProfile = 'Android';
  double _threshold = VibrationDetectionEngine.defaultStrongImpactThreshold;
  int _cooldownSeconds = 10;
  double _currentZ = 0;
  double _currentForce = 0;
  double _currentX = 0;
  double _currentY = 0;
  DateTime? _lastSampleAt;
  String? _message;
  EmergencyAlert? _emergencyAlert;
  bool _safetyCheckEnabled = false;
  List<VibrationEvent> _events = const <VibrationEvent>[];
  DateTime _historyStartedAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isActive => _isActive;
  bool get isReady => _isReady;
  String get deviceProfile => _deviceProfile;
  double get threshold => _threshold;
  int get cooldownSeconds => _cooldownSeconds;
  double get currentZ => _currentZ;
  double get currentForce => _currentForce;
  double get currentX => _currentX;
  double get currentY => _currentY;
  DateTime? get lastSampleAt => _lastSampleAt;
  String? get message => _message;
  EmergencyAlert? get emergencyAlert => _emergencyAlert;
  bool get safetyCheckEnabled => _safetyCheckEnabled;
  List<VibrationEvent> get events => List<VibrationEvent>.unmodifiable(_events);

  Future<void> initialize() async {
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool isNewInstallation = !preferences.containsKey(_thresholdKey);
    _deviceProfile = await _resolveDeviceProfile();
    final int installedCalibrationVersion =
        preferences.getInt(_calibrationVersionKey) ?? 0;
    final String? storedDeviceProfile = preferences.getString(
      _deviceProfileKey,
    );
    final bool changedDevice =
        storedDeviceProfile != null && storedDeviceProfile != _deviceProfile;
    _threshold =
        installedCalibrationVersion < _calibrationVersion || changedDevice
        ? VibrationDetectionEngine.defaultStrongImpactThreshold
        : VibrationDetectionEngine.normalizeThreshold(
            preferences.getDouble(_thresholdKey) ??
                VibrationDetectionEngine.defaultStrongImpactThreshold,
          );
    await preferences.setDouble(_thresholdKey, _threshold);
    await preferences.setInt(_calibrationVersionKey, _calibrationVersion);
    await preferences.setString(_deviceProfileKey, _deviceProfile);
    final int historyStartedAtMilliseconds =
        preferences.getInt(_historyStartedAtKey) ??
        (isNewInstallation ? DateTime.now().millisecondsSinceEpoch : 0);
    _historyStartedAt = DateTime.fromMillisecondsSinceEpoch(
      historyStartedAtMilliseconds,
      isUtc: true,
    );
    await preferences.setInt(
      _historyStartedAtKey,
      historyStartedAtMilliseconds,
    );
    _cooldownSeconds = preferences.getInt(_cooldownKey) ?? 10;
    _isActive = await FlutterForegroundTask.isRunningService;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'geovibe_monitor',
        channelName: 'Monitor GeoVibe',
        channelDescription: 'Indica que GeoVibe analiza vibraciones.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _historySubscription = _repository.watchRecent().listen(
      (List<VibrationEvent> values) {
        _events = values
            .where(
              (VibrationEvent event) =>
                  !event.timestamp.isBefore(_historyStartedAt),
            )
            .toList();
        notifyListeners();
      },
      onError: (Object error) {
        _message = 'No se pudo cargar el historial remoto: $error';
        notifyListeners();
      },
    );
    _isReady = true;
    notifyListeners();
  }

  Future<void> toggleMonitoring() async {
    if (_isActive) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    _message = null;
    notifyListeners();

    if (!await _ensureLocationPermission()) return;
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    await EmergencyAlertService.initialize(requestPermission: true);

    await FlutterForegroundTask.saveData(key: _thresholdKey, value: _threshold);
    await FlutterForegroundTask.saveData(
      key: _cooldownKey,
      value: _cooldownSeconds,
    );
    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
          serviceId: 1049,
          serviceTypes: <ForegroundServiceTypes>[
            ForegroundServiceTypes.location,
          ],
          notificationTitle: 'GeoVibe · monitor activo',
          notificationText: 'Analizando vibraciones del dispositivo',
          callback: startGeoVibeMonitoringTask,
        );

    if (result is ServiceRequestFailure) {
      _message = 'No fue posible iniciar el monitor: ${result.error}';
    } else {
      _isActive = true;
      _message = 'Sensor activo. El monitor se mantiene con una notificación.';
      FlutterForegroundTask.sendDataToTask(<String, dynamic>{
        'threshold': _threshold,
        'cooldownSeconds': _cooldownSeconds,
      });
    }
    notifyListeners();
  }

  Future<void> stop() async {
    final ServiceRequestResult result =
        await FlutterForegroundTask.stopService();
    if (result is ServiceRequestFailure) {
      _message = 'No fue posible detener el monitor: ${result.error}';
    } else {
      _isActive = false;
      _alertOverlayTimer?.cancel();
      _emergencyAlert = null;
      await EmergencyAlertService.dismiss();
      _message = 'Monitor detenido.';
    }
    notifyListeners();
  }

  Future<void> updateThreshold(double value) async {
    _threshold = VibrationDetectionEngine.normalizeThreshold(value);
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_thresholdKey, _threshold);
    await FlutterForegroundTask.saveData(key: _thresholdKey, value: _threshold);
    if (_isActive) {
      FlutterForegroundTask.sendDataToTask(<String, dynamic>{
        'threshold': _threshold,
      });
    }
    notifyListeners();
  }

  Future<void> resetToRecommendedCalibration() async {
    await updateThreshold(
      VibrationDetectionEngine.defaultStrongImpactThreshold,
    );
    _message =
        'Calibración recomendada de 5.0 m/s² restaurada para este dispositivo.';
    notifyListeners();
  }

  Future<void> updateCooldownSeconds(int value) async {
    _cooldownSeconds = value;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_cooldownKey, value);
    await FlutterForegroundTask.saveData(key: _cooldownKey, value: value);
    if (_isActive) {
      FlutterForegroundTask.sendDataToTask(<String, dynamic>{
        'cooldownSeconds': value,
      });
    }
    notifyListeners();
  }

  Future<void> dismissEmergencyAlert() async {
    _alertOverlayTimer?.cancel();
    _alertOverlayTimer = null;
    _emergencyAlert = null;
    await EmergencyAlertService.dismiss();
    _message = 'Alarma silenciada manualmente.';
    notifyListeners();
  }

  void _scheduleAutomaticAlarmDismissal() {
    _alertOverlayTimer?.cancel();
    _alertOverlayTimer = Timer(EmergencyAlertService.alarmDuration, () {
      _emergencyAlert = null;
      _message = 'Alarma silenciada automáticamente tras 10 segundos.';
      unawaited(EmergencyAlertService.dismiss());
      notifyListeners();
    });
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _message = 'Activa el servicio de ubicación para adjuntar la posición aproximada.';
      notifyListeners();
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _message = permission == LocationPermission.deniedForever
          ? 'La ubicación está bloqueada. Habilítala desde Ajustes de Android.'
          : 'Se necesita permiso de ubicación para registrar cada evento.';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<String> _resolveDeviceProfile() async {
    try {
      final AndroidDeviceInfo device = await DeviceInfoPlugin().androidInfo;
      final List<String> parts = <String>[device.manufacturer, device.model]
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toSet()
          .toList();
      return parts.isEmpty ? 'Android' : parts.join(' · ');
    } catch (_) {
      return 'Android';
    }
  }

  void _onTaskData(Object rawData) {
    if (rawData is! Map) return;
    final Map<String, dynamic> data = rawData.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
    switch (data['kind']) {
      case 'service':
        _isActive = data['active'] == true;
        break;
      case 'reading':
        _currentX = (data['x'] as num?)?.toDouble() ?? 0;
        _currentY = (data['y'] as num?)?.toDouble() ?? 0;
        _currentZ = (data['z'] as num?)?.toDouble() ?? 0;
        _currentForce = (data['force'] as num?)?.toDouble() ?? 0;
        _lastSampleAt = DateTime.tryParse(data['timestamp']?.toString() ?? '')
            ?.toLocal();
        break;
      case 'event':
        final Object? rawEvent = data['event'];
        if (rawEvent is Map) {
          final VibrationEvent event = VibrationEvent.fromMap(
            rawEvent,
            id: data['id']?.toString(),
          );
          _events = <VibrationEvent>[event, ..._events]
            ..sort(
              (VibrationEvent a, VibrationEvent b) =>
                  b.timestamp.compareTo(a.timestamp),
            );
        }
        _message = 'Pico registrado y enviado a Firebase.';
        break;
      case 'emergency':
        _emergencyAlert = EmergencyAlert(
          peak: (data['peak'] as num?)?.toDouble() ?? 0,
          detectedAt:
              DateTime.tryParse(data['timestamp']?.toString() ?? '')
                  ?.toLocal() ??
              DateTime.now(),
        );
        _scheduleAutomaticAlarmDismissal();
        _safetyCheckEnabled = true;
        _message = 'Alerta de emergencia activada por un pico de vibración.';
        break;
      case 'error':
        _message = data['message']?.toString();
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _alertOverlayTimer?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _historySubscription?.cancel();
    super.dispose();
  }
}
