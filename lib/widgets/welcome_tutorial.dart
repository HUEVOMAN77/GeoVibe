import 'package:flutter/material.dart';

class WelcomeTutorial extends StatefulWidget {
  const WelcomeTutorial({required this.onCompleted, super.key});

  final Future<void> Function() onCompleted;

  @override
  State<WelcomeTutorial> createState() => _WelcomeTutorialState();
}

class _WelcomeTutorialState extends State<WelcomeTutorial> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const List<_TutorialStep> _steps = <_TutorialStep>[
    _TutorialStep(
      icon: Icons.waving_hand_rounded,
      title: 'Bienvenido a GeoVibe',
      description: 'Tu estación móvil para observar vibraciones, recibir alertas comunitarias y consultar información de Red EEW.',
      accent: Color(0xFF56E6DC),
      showElSalvador: true,
    ),
    _TutorialStep(
      icon: Icons.radar_rounded,
      title: 'Activa el monitor',
      description: 'En Monitor, toca Activar sensor. GeoVibe mantiene un servicio visible de Android para analizar el acelerómetro en segundo plano.',
      accent: Color(0xFF7B9CFF),
    ),
    _TutorialStep(
      icon: Icons.location_on_rounded,
      title: 'Ubicación aproximada',
      description: 'La ubicación solo se solicita al activar el monitor. Los eventos se envían con coordenadas redondeadas y precisión estimada.',
      accent: Color(0xFFF6B94A),
    ),
    _TutorialStep(
      icon: Icons.public_rounded,
      title: 'Red EEW y seguridad',
      description: 'Consulta alertas geográficas de la red colaborativa. Una alerta no sustituye las indicaciones oficiales de Protección Civil.',
      accent: Color(0xFFF05A67),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == _steps.length - 1) {
      await widget.onCompleted();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF07121D),
              Color(0xFF0A1725),
              Color(0xFF101B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (int value) => setState(() => _page = value),
                  itemBuilder: (BuildContext context, int index) =>
                      _TutorialPage(step: _steps[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(_steps.length, (
                        int index,
                      ) {
                        final bool selected = index == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: selected ? 26 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF56E6DC)
                                : const Color(0xFF294051),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _next,
                      icon: Icon(
                        _page == _steps.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _page == _steps.length - 1
                            ? 'Entrar a GeoVibe'
                            : 'Continuar',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: const Color(0xFF56E6DC),
                        foregroundColor: const Color(0xFF061014),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.step});

  final _TutorialStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: step.accent.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: step.accent.withValues(alpha: 0.55)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: step.accent.withValues(alpha: 0.24),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Icon(step.icon, color: step.accent, size: 55),
          ),
          if (step.showElSalvador) ...<Widget>[
            const SizedBox(height: 24),
            const Text('🇸🇻', style: TextStyle(fontSize: 38)),
            const SizedBox(height: 6),
            const Text(
              'EL SALVADOR',
              style: TextStyle(
                color: Color(0xFF9EAFBF),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 30),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF1F6FB),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB7C6D4),
              fontSize: 15.5,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    this.showElSalvador = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final bool showElSalvador;
}
