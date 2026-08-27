import 'package:flutter/material.dart';

import '../services/critical_alert_settings_service.dart';

class CriticalAlertSettingsPanel extends StatefulWidget {
  const CriticalAlertSettingsPanel({super.key});

  @override
  State<CriticalAlertSettingsPanel> createState() =>
      _CriticalAlertSettingsPanelState();
}

class _CriticalAlertSettingsPanelState
    extends State<CriticalAlertSettingsPanel> {
  bool _checking = true;
  bool _policyAccess = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final bool granted =
        await CriticalAlertSettingsService.hasNotificationPolicyAccess();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _policyAccess = granted;
    });
  }

  Future<void> _requestPolicyAccess() async {
    await CriticalAlertSettingsService.requestNotificationPolicyAccess();
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _policyAccess ? 'Acceso de política de notificaciones habilitado.' : 'Activa GeoVibe en la pantalla de acceso a No Molestar y vuelve a comprobar.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _policyAccess
        ? const Color(0xFF56E6DC)
        : const Color(0xFFF6B94A);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF17293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.notifications_active_rounded, color: statusColor),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Alertas críticas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              if (_checking)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  _policyAccess ? 'ACTIVO' : 'REQUIERE ACCESO',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'GeoVibe usa prioridad máxima, canal de alarma y pantalla completa. Para permitir la omisión de No Molestar, Android exige que concedas este acceso expresamente.',
            style: TextStyle(
              color: Color(0xFFB7C6D4),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _checking ? null : _requestPolicyAccess,
            icon: const Icon(Icons.settings_applications_outlined),
            label: Text(
              _policyAccess
                  ? 'Comprobar acceso de No Molestar'
                  : 'Configurar acceso de No Molestar',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: statusColor,
              side: BorderSide(color: statusColor.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
