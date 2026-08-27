import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'models/eew_alert.dart';
import 'models/vibration_event.dart';
import 'services/emergency_alert_service.dart';
import 'services/eew_controller.dart';
import 'services/monitor_health_service.dart';
import 'services/monitoring_controller.dart';
import 'widgets/acceleration_meter.dart';
import 'widgets/about_page.dart';
import 'widgets/critical_alert_settings_panel.dart';
import 'widgets/eew_geographic_map.dart';
import 'widgets/monitor_diagnostics_panels.dart';
import 'widgets/safety_share_sheet.dart';
import 'widgets/survival_guide_page.dart';

class GeoVibeShell extends StatefulWidget {
  const GeoVibeShell({
    required this.controller,
    required this.eewController,
    required this.monitorHealth,
    super.key,
  });

  final MonitoringController controller;
  final EewController eewController;
  final MonitorHealthService monitorHealth;

  @override
  State<GeoVibeShell> createState() => _GeoVibeShellState();
}

class _GeoVibeShellState extends State<GeoVibeShell> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.controller,
        widget.eewController,
        widget.monitorHealth,
      ]),
      builder: (BuildContext context, Widget? child) {
        final List<Widget> pages = <Widget>[
          MonitorPage(controller: widget.controller),
          HistoryPage(controller: widget.controller),
          EewNetworkPage(controller: widget.eewController),
          SettingsPage(
            controller: widget.controller,
            monitorHealth: widget.monitorHealth,
          ),
          const AboutPage(),
        ];
        return Scaffold(
          backgroundColor: const Color(0xFF070B12),
          body: SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) =>
                            FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.02, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_page),
                      child: pages[_page],
                    ),
                  ),
                ),
                if (widget.controller.emergencyAlert case EmergencyAlert alert)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: _EmergencyOverlay(
                      alert: alert,
                      onDismiss: widget.controller.dismissEmergencyAlert,
                    ),
                  ),
                if (widget.eewController.activeAlert case EewAlert alert)
                  Positioned.fill(
                    child: _EewEvacuationOverlay(
                      alert: alert,
                      onDismiss: widget.eewController.dismissActiveAlert,
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NavigationBarTheme(
                  data: const NavigationBarThemeData(
                    indicatorColor: Color(0xFF1A4B52),
                    labelTextStyle: WidgetStatePropertyAll<TextStyle>(
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                  child: NavigationBar(
                    height: 68,
                    selectedIndex: _page,
                    onDestinationSelected: (int value) =>
                        setState(() => _page = value),
                    backgroundColor: const Color(0xFF101B2A),
                    destinations: const <NavigationDestination>[
                      NavigationDestination(
                        icon: Icon(Icons.radar_outlined),
                        selectedIcon: Icon(Icons.radar),
                        label: 'Monitor',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.history_outlined),
                        selectedIcon: Icon(Icons.history),
                        label: 'Historial',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.public_outlined),
                        selectedIcon: Icon(Icons.public),
                        label: 'Red EEW',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.tune_outlined),
                        selectedIcon: Icon(Icons.tune),
                        label: 'Ajustes',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.info_outline_rounded),
                        selectedIcon: Icon(Icons.info_rounded),
                        label: 'Acerca de',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MonitorPage extends StatelessWidget {
  const MonitorPage({required this.controller, super.key});

  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _Header(),
          const SizedBox(height: 18),
          _MonitorHero(controller: controller),
          const SizedBox(height: 14),
          _StatusPanel(controller: controller),
          const SizedBox(height: 12),
          _SilenceAlarmButton(controller: controller),
          if (controller.safetyCheckEnabled) ...<Widget>[
            const SizedBox(height: 10),
            const _SafetyStatusButton(),
          ],
          const SizedBox(height: 18),
          _Panel(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const _Overline('TELEMETRÍA EN VIVO'),
                    Text(
                      'UMBRAL ${controller.threshold.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Color(0xFFF6B94A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                AccelerationMeter(
                  force: controller.currentForce,
                  threshold: controller.threshold,
                ),
                Row(
                  children: <Widget>[
                    _AxisReading(label: 'X', value: controller.currentX),
                    const SizedBox(width: 10),
                    _AxisReading(label: 'Y', value: controller.currentY),
                    const SizedBox(width: 10),
                    _AxisReading(label: 'Z', value: controller.currentZ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _RecentActivity(events: controller.events),
          if (controller.message != null) ...<Widget>[
            const SizedBox(height: 14),
            _InfoBanner(message: controller.message!),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: controller.isReady ? controller.toggleMonitoring : null,
            icon: Icon(
              controller.isActive
                  ? Icons.stop_circle_outlined
                  : Icons.play_arrow_rounded,
            ),
            label: Text(
              controller.isActive ? 'Detener monitor' : 'Activar sensor',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: controller.isActive
                  ? const Color(0xFF233346)
                  : const Color(0xFF56E6DC),
              foregroundColor: controller.isActive
                  ? const Color(0xFFF1F6FB)
                  : const Color(0xFF061014),
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EewNetworkPage extends StatefulWidget {
  const EewNetworkPage({required this.controller, super.key});

  final EewController controller;

  @override
  State<EewNetworkPage> createState() => _EewNetworkPageState();
}

class _EewNetworkPageState extends State<EewNetworkPage> {
  String _department = 'Todos';

  @override
  Widget build(BuildContext context) {
    final List<EewAlert> alerts = widget.controller.alerts;
    final List<String> departments =
        alerts
            .map((EewAlert alert) => alert.locationName)
            .where(
              (String name) =>
                  name.trim().isNotEmpty && name != 'Ubicación no especificada',
            )
            .toSet()
            .toList()
          ..sort();
    final String selectedDepartment = departments.contains(_department)
        ? _department
        : 'Todos';
    final List<EewAlert> visibleAlerts = selectedDepartment == 'Todos'
        ? alerts
        : alerts
              .where(
                (EewAlert alert) => alert.locationName == selectedDepartment,
              )
              .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Red EEW',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Alerta temprana colaborativa · señales verificadas por la red',
            style: TextStyle(color: Color(0xFF8DA0B4), fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          _EewConnectionCard(controller: widget.controller),
          const SizedBox(height: 18),
          const _Overline('FILTRAR POR DEPARTAMENTO'),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _DepartmentFilterChip(
                  label: 'Todos',
                  selected: selectedDepartment == 'Todos',
                  onSelected: () => setState(() => _department = 'Todos'),
                ),
                ...departments.map(
                  (String department) => _DepartmentFilterChip(
                    label: department,
                    selected: selectedDepartment == department,
                    onSelected: () => setState(() => _department = department),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _Overline('MAPA DE ALERTAS RECIENTES'),
          const SizedBox(height: 8),
          EewGeographicMap(alerts: visibleAlerts),
          const SizedBox(height: 20),
          const _Overline('EVENTOS MASIVOS DE LA COMUNIDAD'),
          const SizedBox(height: 8),
          if (visibleAlerts.isEmpty)
            const _Panel(
              child: Text(
                'No hay alertas para este departamento. El mapa se actualizará cuando Red EEW reciba una señal.',
                style: TextStyle(color: Color(0xFF8DA0B4), height: 1.4),
              ),
            )
          else
            _EewEventList(alerts: visibleAlerts),
        ],
      ),
    );
  }
}

class _DepartmentFilterChip extends StatelessWidget {
  const _DepartmentFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: const Color(0xFF1A4B52),
        backgroundColor: const Color(0xFF132235),
        side: BorderSide(
          color: selected ? const Color(0xFF56E6DC) : const Color(0xFF29475D),
        ),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF56E6DC) : const Color(0xFFB7C6D4),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

class _EewConnectionCard extends StatelessWidget {
  const _EewConnectionCard({required this.controller});

  final EewController controller;

  @override
  Widget build(BuildContext context) {
    final bool connected = controller.isConnected;
    return _Panel(
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFF123C3D)
                  : const Color(0xFF42271B),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: connected
                  ? const Color(0xFF37D4D1)
                  : const Color(0xFFF6B94A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  connected ? 'CANAL EEW CONECTADO' : 'CONECTANDO RED EEW',
                  style: TextStyle(
                    color: connected
                        ? const Color(0xFF37D4D1)
                        : const Color(0xFFF6B94A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  controller.connectionDetail ??
                      'Preparando la suscripción del dispositivo.',
                  style: const TextStyle(
                    color: Color(0xFFB5C4D1),
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _EewMap extends StatelessWidget {
  const _EewMap({required this.alerts});

  final List<EewAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final List<EewAlert> plotted = alerts.take(12).toList();
    final List<double> latitudes = plotted
        .map((EewAlert alert) => alert.location.latitude)
        .where((double value) => value != 0)
        .toList();
    final List<double> longitudes = plotted
        .map((EewAlert alert) => alert.location.longitude)
        .where((double value) => value != 0)
        .toList();
    final double minLat = latitudes.isEmpty ? -1 : latitudes.reduce(math.min);
    final double maxLat = latitudes.isEmpty ? 1 : latitudes.reduce(math.max);
    final double minLng = longitudes.isEmpty ? -1 : longitudes.reduce(math.min);
    final double maxLng = longitudes.isEmpty ? 1 : longitudes.reduce(math.max);

    return SizedBox(
      height: 230,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _TacticalMapPainter())),
            if (plotted.isEmpty)
              const Center(
                child: Text(
                  'SIN SEÑALES DE RED',
                  style: TextStyle(
                    color: Color(0xFF8DA0B4),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            for (final EewAlert alert in plotted)
              _EewMapMarker(
                alert: alert,
                alignment: Alignment(
                  _normalise(alert.location.longitude, minLng, maxLng) * 1.5,
                  -_normalise(alert.location.latitude, minLat, maxLat) * 1.25,
                ),
              ),
            const Positioned(
              left: 14,
              top: 12,
              child: Text(
                'COORDENADAS APROXIMADAS',
                style: TextStyle(
                  color: Color(0xFF8DA0B4),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _normalise(double value, double lower, double upper) {
    if (value == 0 || lower == upper) return 0;
    return ((value - lower) / (upper - lower)) * 2 - 1;
  }
}

class _TacticalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0C1A25),
    );
    final Paint grid = Paint()
      ..color = const Color(0xFF245060)
      ..strokeWidth = 0.7;
    for (double x = 0; x <= size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final Paint range = Paint()
      ..color = const Color(0x4437D4D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 38, range);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 78, range);
  }

  @override
  bool shouldRepaint(covariant _TacticalMapPainter oldDelegate) => false;
}

class _EewMapMarker extends StatelessWidget {
  const _EewMapMarker({required this.alert, required this.alignment});

  final EewAlert alert;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final Color color = alert.isEvacuation
        ? const Color(0xFFF04152)
        : const Color(0xFFF6B94A);
    return Align(
      alignment: alignment,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(Icons.warning_rounded, color: color, size: 15),
      ),
    );
  }
}

class _EewEventList extends StatelessWidget {
  const _EewEventList({required this.alerts});

  final List<EewAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: alerts.take(8).map((EewAlert alert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.warning_amber_rounded,
                  color: alert.isEvacuation
                      ? const Color(0xFFF04152)
                      : const Color(0xFFF6B94A),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        alert.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${alert.communityReports} reportes · ${_formatDate(alert.detectedAt)}',
                        style: const TextStyle(
                          color: Color(0xFF8DA0B4),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.controller, super.key});

  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final List<VibrationEvent> events = controller.events;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Historial remoto',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Últimos registros sincronizados con Firebase.'),
          const SizedBox(height: 20),
          Expanded(
            child: events.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) =>
                        _EventTile(event: events[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.controller,
    required this.monitorHealth,
    super.key,
  });

  final MonitoringController controller;
  final MonitorHealthService monitorHealth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ajustes de captura',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Los cambios se guardan localmente y se aplican al monitor activo.',
          ),
          const SizedBox(height: 24),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Umbral de fuerza neta',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${controller.threshold.toStringAsFixed(1)} m/s²',
                      style: const TextStyle(
                        color: Color(0xFF37D4D1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: controller.threshold,
                  min: 5,
                  max: 15,
                  divisions: 20,
                  onChanged: controller.updateThreshold,
                ),
                const Text(
                  'La alerta confirma fuerza neta continua durante 200 ms con tres lecturas; reconoce vibración en cualquier dirección.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Período de enfriamiento',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${controller.cooldownSeconds} s',
                      style: const TextStyle(
                        color: Color(0xFF37D4D1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: controller.cooldownSeconds.toDouble(),
                  min: 3,
                  max: 60,
                  divisions: 19,
                  onChanged: (double value) =>
                      controller.updateCooldownSeconds(value.round()),
                ),
                const Text(
                  'Evita duplicar registros mientras persiste el mismo movimiento.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CalibrationProfilePanel(controller: controller),
          const SizedBox(height: 16),
          MonitorDiagnosticsPanel(
            controller: controller,
            monitorHealth: monitorHealth,
          ),
          const SizedBox(height: 16),
          const CriticalAlertSettingsPanel(),
          const SizedBox(height: 16),
          _Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF56E6DC),
              ),
              title: const Text(
                'Guía de Supervivencia',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                'Contenido local disponible sin internet.',
                style: TextStyle(color: Color(0xFF9EAFBF), fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const SurvivalGuidePage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _Panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.privacy_tip_outlined, color: Color(0xFF37D4D1)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GeoVibe redondea la coordenada a cuatro decimales antes de enviarla y conserva su precisión estimada.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitorHero extends StatelessWidget {
  const _MonitorHero({required this.controller});

  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final bool active = controller.isActive;
    final Color accent = active
        ? const Color(0xFF56E6DC)
        : const Color(0xFFF6B94A);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            active ? const Color(0xFF15424A) : const Color(0xFF302817),
            const Color(0xFF101B2A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 18),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              active ? Icons.graphic_eq_rounded : Icons.sensors_outlined,
              color: accent,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  active ? 'Monitoreo protegido' : 'Centro de monitoreo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  active
                      ? 'Sensor local y Red EEW preparados.'
                      : 'Activa el sensor cuando estés listo.',
                  style: const TextStyle(
                    color: Color(0xFFB7C6D4),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF07121D).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'GEO\nVIBE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9EAFBF),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF1D5358), Color(0xFF113944)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x5537D4D1), blurRadius: 14),
            ],
          ),
          child: const Icon(Icons.waves_rounded, color: Color(0xFF37D4D1)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'GEOVIBE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                'NODO MÓVIL · ANDROID',
                style: TextStyle(
                  color: Color(0xFF8DA0B4),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF142A35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF295161)),
          ),
          child: const Icon(
            Icons.cloud_sync_outlined,
            color: Color(0xFF56E6DC),
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.controller});

  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final bool active = controller.isActive;
    final Color accent = active
        ? const Color(0xFF37D4D1)
        : const Color(0xFFF6B94A);
    return _Panel(
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              active ? Icons.sensors : Icons.radar_outlined,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  active ? 'Sensor activo' : 'Buscando señal',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  active
                      ? 'Acelerómetro y sincronización en primer plano.'
                      : 'Activa el sensor para iniciar la lectura local.',
                  style: const TextStyle(
                    color: Color(0xFF8DA0B4),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(active ? Icons.check_circle : Icons.more_horiz, color: accent),
        ],
      ),
    );
  }
}

class _SilenceAlarmButton extends StatelessWidget {
  const _SilenceAlarmButton({required this.controller});

  final MonitoringController controller;

  @override
  Widget build(BuildContext context) {
    final bool alarmActive = controller.emergencyAlert != null;
    return FilledButton.icon(
      onPressed: alarmActive ? controller.dismissEmergencyAlert : null,
      icon: const Icon(Icons.volume_off_rounded),
      label: Text(
        alarmActive ? 'SILENCIAR ALARMA AHORA' : 'ALARMA SIN ACTIVAR',
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: const Color(0xFFF04152),
        foregroundColor: const Color(0xFFFFFFFF),
        disabledBackgroundColor: const Color(0xFF263444),
        disabledForegroundColor: const Color(0xFF8DA0B4),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SafetyStatusButton extends StatelessWidget {
  const _SafetyStatusButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => showSafetyShareSheet(context),
      icon: const Icon(Icons.verified_rounded),
      label: const Text('ESTOY A SALVO'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: const Color(0xFF177D6B),
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.events});

  final List<VibrationEvent> events;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _Overline('ACTIVIDAD RECIENTE'),
          const SizedBox(height: 14),
          if (events.isEmpty)
            const Text(
              'Sin retumbos registrados. El historial aparecerá aquí al detectar un pico.',
            )
          else
            ...events
                .take(3)
                .map(
                  (VibrationEvent event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EventSummary(event: event),
                  ),
                ),
        ],
      ),
    );
  }
}

class _EventSummary extends StatelessWidget {
  const _EventSummary({required this.event});

  final VibrationEvent event;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.bolt_rounded, color: Color(0xFFFF5C6A), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _formatDate(event.timestamp),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${event.vibrationPeak.toStringAsFixed(2)} m/s²',
          style: const TextStyle(
            color: Color(0xFF37D4D1),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final VibrationEvent event;

  @override
  Widget build(BuildContext context) {
    final ApproximateLocation? location = event.location;
    return _Panel(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.bolt_rounded, color: Color(0xFFFF5C6A), size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _formatDate(event.timestamp),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  location == null
                      ? 'Ubicación no disponible'
                      : '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)} · ±${location.accuracyMeters.round()} m',
                  style: const TextStyle(
                    color: Color(0xFF8DA0B4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            event.vibrationPeak.toStringAsFixed(2),
            style: const TextStyle(
              color: Color(0xFF37D4D1),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF8DA0B4)),
          SizedBox(height: 12),
          Text('Aún no hay registros sincronizados.'),
        ],
      ),
    );
  }
}

class _AxisReading extends StatelessWidget {
  const _AxisReading({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1724),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF1D3448)),
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8DA0B4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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

class _Overline extends StatelessWidget {
  const _Overline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8DA0B4),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF132A3E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF244761)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, color: Color(0xFF348BFF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _EmergencyOverlay extends StatelessWidget {
  const _EmergencyOverlay({required this.alert, required this.onDismiss});

  final EmergencyAlert alert;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF04152),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0xAAFF5C6A),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'ALERTA DE EMERGENCIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Pico ${alert.peak.toStringAsFixed(2)} m/s² · ${_formatDate(alert.detectedAt)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text(
                'SILENCIAR',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EewEvacuationOverlay extends StatelessWidget {
  const _EewEvacuationOverlay({required this.alert, required this.onDismiss});

  final EewAlert alert;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE80D1119),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF04152),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xAAFF5C6A),
                    blurRadius: 36,
                    spreadRadius: 7,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ALERTA TEMPRANA DE SISMOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    alert.isEvacuation ? 'EVACUAR AHORA' : 'BUSCAR RESGUARDO',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alert.instruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.volume_off_rounded),
                    label: const Text('SILENCIAR ALARMA'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => showSafetyShareSheet(context),
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('ESTOY A SALVO'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFC91E33),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'La alarma se apagará automáticamente a los 10 segundos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFFFDDE0), fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime timestamp) {
  final String date =
      '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
  final String time =
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  return '$date · $time';
}
