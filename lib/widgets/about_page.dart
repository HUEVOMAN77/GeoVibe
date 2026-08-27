import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Acerca de',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Información, créditos y arquitectura de GeoVibe.',
            style: TextStyle(color: Color(0xFF9EAFBF), fontSize: 13),
          ),
          const SizedBox(height: 22),
          _AboutSurface(
            child: Column(
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF56E6DC).withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF56E6DC)),
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: Color(0xFF56E6DC),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'HUEVOMAN77',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Creador / Desarrollador independiente',
                  style: TextStyle(color: Color(0xFFB7C6D4)),
                ),
                const SizedBox(height: 14),
                const SelectableText(
                  'https://github.com/HUEVOMAN77',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF56E6DC),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ESPECIFICACIONES TÉCNICAS',
            style: TextStyle(
              color: Color(0xFF9EAFBF),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 9),
          const _AboutSurface(
            child: Column(
              children: <Widget>[
                _SpecRow(label: 'Versión de la app', value: 'v1.0.0'),
                Divider(color: Color(0xFF243C50), height: 22),
                _SpecRow(
                  label: 'Servicios en red',
                  value: 'Firebase Realtime & FCM',
                ),
                Divider(color: Color(0xFF243C50), height: 22),
                _SpecRow(label: 'Sensor', value: 'Acelerómetro multieje'),
                Divider(color: Color(0xFF243C50), height: 22),
                _SpecRow(
                  label: 'Alerta comunitaria',
                  value: 'Red de Alerta Temprana (EEW)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF17293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF29475D)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.shield_outlined, color: Color(0xFFF6B94A)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GeoVibe es una herramienta de apoyo comunitario. Ante una emergencia, sigue siempre las instrucciones oficiales de Protección Civil.',
                    style: TextStyle(color: Color(0xFFB7C6D4), height: 1.35),
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

class _AboutSurface extends StatelessWidget {
  const _AboutSurface({required this.child});

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
      ),
      child: child,
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF9EAFBF), fontSize: 12.5),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
