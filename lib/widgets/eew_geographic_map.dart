import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/eew_alert.dart';

class EewGeographicMap extends StatefulWidget {
  const EewGeographicMap({required this.alerts, super.key});

  static const LatLng _elSalvadorCenter = LatLng(13.79, -88.89);

  final List<EewAlert> alerts;

  @override
  State<EewGeographicMap> createState() => _EewGeographicMapState();
}

class _EewGeographicMapState extends State<EewGeographicMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  String? _selectedAlertId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant EewGeographicMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool selectionExists = widget.alerts.any(
      (EewAlert alert) => alert.id == _selectedAlertId,
    );
    if (!selectionExists) _selectedAlertId = null;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<EewAlert> plotted = widget.alerts
        .where(_hasValidCoordinates)
        .take(12)
        .toList();
    final EewAlert? selected = _selectedAlert(plotted);
    return SizedBox(
      height: 342,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: <Widget>[
            FlutterMap(
              options: const MapOptions(
                initialCenter: EewGeographicMap._elSalvadorCenter,
                initialZoom: 8.35,
                minZoom: 7.5,
                maxZoom: 18,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.geovibe.geovibe',
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: plotted
                      .map((EewAlert alert) => _mapMarker(alert, selected))
                      .toList(),
                ),
                RichAttributionWidget(
                  attributions: <SourceAttribution>[
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _MapLabel(
                text: plotted.isEmpty
                    ? 'EL SALVADOR · BASE EEW'
                    : 'EL SALVADOR · ${plotted.length} EPICENTRO${plotted.length == 1 ? '' : 'S'}',
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: _EpicenterCard(alert: selected),
            ),
          ],
        ),
      ),
    );
  }

  EewAlert? _selectedAlert(List<EewAlert> plotted) {
    if (plotted.isEmpty) return null;
    return plotted
            .where((EewAlert alert) => alert.id == _selectedAlertId)
            .firstOrNull ??
        plotted.first;
  }

  bool _hasValidCoordinates(EewAlert alert) {
    final double latitude = alert.location.latitude;
    final double longitude = alert.location.longitude;
    return latitude != 0 &&
        longitude != 0 &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  Marker _mapMarker(EewAlert alert, EewAlert? selected) {
    final bool isSelected = alert.id == selected?.id;
    return Marker(
      point: LatLng(alert.location.latitude, alert.location.longitude),
      width: 58,
      height: 58,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedAlertId = alert.id),
        child: _AnimatedEpicenterMarker(
          animation: _pulseController,
          selected: isSelected,
        ),
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xE5091420),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF36546B)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF1F6FB),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.75,
        ),
      ),
    );
  }
}

class _AnimatedEpicenterMarker extends StatelessWidget {
  const _AnimatedEpicenterMarker({
    required this.animation,
    required this.selected,
  });

  final Animation<double> animation;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double pulseValue = animation.value;
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: (1 - pulseValue) * (selected ? 0.78 : 0.44),
                child: Transform.scale(
                  scale: 0.7 + (pulseValue * (selected ? 1.25 : 0.75)),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0x55F04152),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF04152),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: selected ? 30 : 25,
                height: selected ? 30 : 25,
                decoration: BoxDecoration(
                  color: const Color(0xFFF04152),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: selected ? 2 : 1.2,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0xAA7C101C), blurRadius: 10),
                  ],
                ),
                child: Icon(
                  selected ? Icons.location_on_rounded : Icons.circle,
                  color: Colors.white,
                  size: selected ? 18 : 9,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EpicenterCard extends StatelessWidget {
  const _EpicenterCard({required this.alert});

  final EewAlert? alert;

  @override
  Widget build(BuildContext context) {
    if (alert == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: _decoration,
        child: const Text(
          'Base fija en El Salvador. El epicentro y sus detalles aparecerán aquí al recibir una alerta comunitaria.',
          style: TextStyle(
            color: Color(0xFFD5E1EA),
            fontSize: 11.5,
            height: 1.3,
          ),
        ),
      );
    }
    final String location = alert!.locationName == 'Ubicación no especificada'
        ? alert!.title
        : alert!.locationName;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.touch_app_rounded,
                color: Color(0xFFF05A67),
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF9FCFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                child: _Detail(
                  icon: Icons.layers_outlined,
                  label: 'PROFUNDIDAD',
                  value: alert!.depthKm > 0
                      ? '${alert!.depthKm.toStringAsFixed(1)} km'
                      : 'N/D',
                ),
              ),
              Expanded(
                child: _Detail(
                  icon: Icons.graphic_eq_rounded,
                  label: 'ACELERACIÓN',
                  value: alert!.accelerationMs2 > 0
                      ? '${alert!.accelerationMs2.toStringAsFixed(1)} m/s²'
                      : 'N/D',
                ),
              ),
              Expanded(
                child: _Detail(
                  icon: Icons.access_time_rounded,
                  label: 'HORA',
                  value: _formatTime(alert!.detectedAt),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static BoxDecoration get _decoration => BoxDecoration(
    color: const Color(0xED091521),
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: const Color(0xFF3A566C)),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x88000000), blurRadius: 12),
    ],
  );

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: const Color(0xFFF05A67), size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF89A0B4),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF1F6FB),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
