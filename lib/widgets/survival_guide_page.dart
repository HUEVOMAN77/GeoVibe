import 'package:flutter/material.dart';

class SurvivalGuidePage extends StatelessWidget {
  const SurvivalGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de Supervivencia'),
        backgroundColor: const Color(0xFF101B2A),
        foregroundColor: const Color(0xFFF1F6FB),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: const <Widget>[
          _GuideIntro(),
          SizedBox(height: 18),
          _GuideSection(
            icon: Icons.backpack_outlined,
            color: Color(0xFF56E6DC),
            title: 'Antes de un sismo',
            items: <String>[
              'Prepara una mochila de emergencia con agua, alimentos, linterna, radio, baterías, botiquín y documentos importantes.',
              'Identifica zonas seguras dentro de casa y acuerda un punto de reunión con tu familia.',
              'Asegura estantes, televisores y objetos pesados que puedan caer.',
            ],
          ),
          SizedBox(height: 14),
          _GuideSection(
            icon: Icons.shield_outlined,
            color: Color(0xFFF6B94A),
            title: 'Durante un sismo',
            items: <String>[
              'Agáchate, cúbrete y agárrate hasta que termine el movimiento.',
              'Aléjate de ventanas, vidrios, fachadas y objetos que puedan caer.',
              'No uses ascensores. Si estás en el exterior, busca un espacio abierto lejos de cables y estructuras.',
            ],
          ),
          SizedBox(height: 14),
          _GuideSection(
            icon: Icons.fact_check_outlined,
            color: Color(0xFFF05A67),
            title: 'Después de un sismo',
            items: <String>[
              'Revisa posibles fugas de gas, daños estructurales o cables caídos; no enciendas fuego si percibes olor a gas.',
              'Evita rumores: consulta únicamente a autoridades y fuentes oficiales.',
              'Cuando estés seguro, usa Estoy a Salvo para compartir tu estado y ubicación con tus contactos.',
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideIntro extends StatelessWidget {
  const _GuideIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF29475D)),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.offline_bolt_rounded, color: Color(0xFF56E6DC), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Contenido disponible sin internet para consultar después de una emergencia.',
              style: TextStyle(color: Color(0xFFD9E7F0), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF101B2A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: color),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ...items.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.check_circle_rounded, color: color, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFFC6D4DF),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
