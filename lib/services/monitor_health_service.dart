import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

import 'monitoring_controller.dart';

class MonitorHealthService extends ChangeNotifier {
  MonitorHealthService({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _refreshTimer;

  int? _batteryLevel;
  BatteryState? _batteryState;
  bool? _batterySaverEnabled;
  DateTime? _lastUpdatedAt;

  int? get batteryLevel => _batteryLevel;
  BatteryState? get batteryState => _batteryState;
  bool? get batterySaverEnabled => _batterySaverEnabled;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  Future<void> initialize() async {
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
      BatteryState state,
    ) {
      _batteryState = state;
      _lastUpdatedAt = DateTime.now();
      notifyListeners();
    });
    await refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(refresh());
    });
  }

  Future<void> refresh() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _batteryState = await _battery.batteryState;
      _batterySaverEnabled = await _battery.isInBatterySaveMode;
      _lastUpdatedAt = DateTime.now();
      notifyListeners();
    } catch (_) {
      _lastUpdatedAt = DateTime.now();
      notifyListeners();
    }
  }

  String powerStatusLabel() {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Cargando';
      case BatteryState.full:
        return 'Carga completa';
      case BatteryState.discharging:
        return 'En descarga';
      case BatteryState.connectedNotCharging:
        return 'Conectado sin carga';
      case BatteryState.unknown:
        return 'Estado de energía desconocido';
      case null:
        return 'Sin datos';
    }
  }

  bool hasFreshSensorReading(MonitoringController controller) {
    final DateTime? lastSampleAt = controller.lastSampleAt;
    if (!controller.isActive || lastSampleAt == null) return false;
    return DateTime.now().difference(lastSampleAt) <=
        const Duration(seconds: 25);
  }

  String continuityLabel(MonitoringController controller) {
    if (!controller.isActive) return 'Monitor detenido';
    final DateTime? lastSampleAt = controller.lastSampleAt;
    if (lastSampleAt == null) return 'Esperando la primera lectura';
    final int seconds = DateTime.now().difference(lastSampleAt).inSeconds;
    if (seconds <= 25) return 'Lecturas en segundo plano activas';
    return 'Sin lectura reciente (${seconds}s)';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _batteryStateSubscription?.cancel();
    super.dispose();
  }
}
