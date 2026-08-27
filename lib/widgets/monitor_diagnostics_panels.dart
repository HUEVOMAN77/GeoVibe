import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

import '../services/monitor_health_service.dart';
import '../services/monitoring_controller.dart';

class CalibrationProfilePanel extends StatelessWidget {
  const CalibrationProfilePanel({required this.controller, super.key});

  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return _DiagnosticsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.tune_rounded, color: Color(0xFF56E6DC)),
              SizedBox(width: 10),
              Text(
                'CALIBRACIÓN POR DISPOSITIVO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            controller.deviceProfile,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'El perfil se guarda por modelo. Para probarlo, deja el teléfono inmóvil durante 30 segundos y ajusta el umbral solo si aparecen alertas falsas.',
            style: TextStyle(color: Color(0xFF9EAFBF), height: 1.35),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: controller.resetToRecommendedCalibration,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Restaurar recomendado · 5.0 m/s²'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF56E6DC),
              side: const BorderSide(color: Color(0xFF2F6670)),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonitorDiagnosticsPanel extends StatelessWidget {
  const MonitorDiagnosticsPanel({
    required this.controller,
    required this.monitorHealth,
    super.key,
  });

  final MonitoringController controller;
  final MonitorHealthService monitorHealth;

  @override
  Widget build(BuildContext context) {
    final bool fresh = monitorHealth.hasFreshSensorReading(controller);
    final Color serviceColor = fresh
        ? const Color(0xFF56E6DC)
        : const Color(0xFFF6B94A);
    final int? batteryLevel = monitorHealth.batteryLevel;
    final bool batterySaver = monitorHealth.batterySaverEnabled == true;
    return _DiagnosticsSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.battery_charging_full_rounded, color: serviceColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'SALUD DEL MONITOR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar diagnóstico',
                onPressed: monitorHealth.refresh,
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _DiagnosticChip(
                icon: _batteryIcon(monitorHealth.batteryState),
                label: batteryLevel == null
                    ? 'Batería sin datos'
                    : 'Batería $batteryLevel%',
                color: batteryLevel != null && batteryLevel <= 20
                    ? const Color(0xFFF6B94A)
                    : const Color(0xFF56E6DC),
              ),
              _DiagnosticChip(
                icon: fresh ? Icons.sensors : Icons.sensors_off_rounded,
                label: monitorHealth.continuityLabel(controller),
                color: serviceColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Energía: ${monitorHealth.powerStatusLabel()}${batterySaver ? ' · ahorro de batería activo' : ''}.',
            style: TextStyle(
              color: batterySaver
                  ? const Color(0xFFF6B94A)
                  : const Color(0xFF9EAFBF),
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          if (batterySaver) ...<Widget>[
            const SizedBox(height: 7),
            const Text(
              'Android puede limitar el servicio. Excluye GeoVibe de la optimización de batería si las lecturas se detienen.',
              style: TextStyle(
                color: Color(0xFFF6B94A),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _batteryIcon(BatteryState? state) {
    switch (state) {
      case BatteryState.charging:
        return Icons.battery_charging_full_rounded;
      case BatteryState.full:
        return Icons.battery_full_rounded;
      case BatteryState.discharging:
        return Icons.battery_std_rounded;
      case BatteryState.connectedNotCharging:
        return Icons.battery_alert_rounded;
      case BatteryState.unknown:
        return Icons.battery_unknown_rounded;
      case null:
        return Icons.battery_unknown_rounded;
    }
  }
}

class _DiagnosticsSurface extends StatelessWidget {
  const _DiagnosticsSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF132235), Color(0xFF0E1928)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF233C52)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DiagnosticChip extends StatelessWidget {
  const _DiagnosticChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11.5)),
        ],
      ),
    );
  }
}
