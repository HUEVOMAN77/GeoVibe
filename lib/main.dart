import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'geovibe_dashboard.dart';
import 'services/eew_controller.dart';
import 'services/eew_messaging_service.dart';
import 'services/monitor_health_service.dart';
import 'services/monitoring_controller.dart';
import 'widgets/welcome_tutorial.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseEewBackgroundHandler);
  runApp(const GeoVibeApp());
}

class GeoVibeApp extends StatefulWidget {
  const GeoVibeApp({super.key});

  @override
  State<GeoVibeApp> createState() => _GeoVibeAppState();
}

class _GeoVibeAppState extends State<GeoVibeApp> {
  static const String _tutorialCompletedKey = 'geovibe.tutorial_completed';

  late final MonitoringController _controller;
  late final EewController _eewController;
  late final MonitorHealthService _monitorHealth;
  Timer? _introTimer;
  _LaunchStage _stage = _LaunchStage.intro;
  bool _introCompleted = false;
  bool? _isFirstUse;

  @override
  void initState() {
    super.initState();
    _controller = MonitoringController();
    _controller.initialize();
    _eewController = EewController();
    _eewController.initialize();
    _monitorHealth = MonitorHealthService();
    _monitorHealth.initialize();
    _loadFirstUseState();
    _introTimer = Timer(const Duration(seconds: 5), () {
      _introCompleted = true;
      _advanceAfterIntro();
    });
  }

  Future<void> _loadFirstUseState() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _isFirstUse = !(preferences.getBool(_tutorialCompletedKey) ?? false);
    _advanceAfterIntro();
  }

  void _advanceAfterIntro() {
    if (!mounted || !_introCompleted || _isFirstUse == null) return;
    setState(() {
      _stage = _isFirstUse! ? _LaunchStage.tutorial : _LaunchStage.dashboard;
    });
  }

  Future<void> _finishTutorial() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_tutorialCompletedKey, true);
    if (mounted) setState(() => _stage = _LaunchStage.dashboard);
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _controller.dispose();
    _eewController.dispose();
    _monitorHealth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoVibe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF070B12),
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF56E6DC),
          secondary: Color(0xFF7B9CFF),
          surface: Color(0xFF101B2A),
          onSurface: Color(0xFFF1F6FB),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: Color(0xFFF1F6FB),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          bodyMedium: TextStyle(color: Color(0xFFF1F6FB)),
          bodySmall: TextStyle(color: Color(0xFF9EAFBF)),
        ),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: switch (_stage) {
          _LaunchStage.intro => const GeoVibeIntroScreen(
            key: ValueKey<String>('intro'),
          ),
          _LaunchStage.tutorial => WelcomeTutorial(
            key: const ValueKey<String>('tutorial'),
            onCompleted: _finishTutorial,
          ),
          _LaunchStage.dashboard => GeoVibeShell(
            key: const ValueKey<String>('dashboard'),
            controller: _controller,
            eewController: _eewController,
            monitorHealth: _monitorHealth,
          ),
        },
      ),
    );
  }
}

class GeoVibeIntroScreen extends StatefulWidget {
  const GeoVibeIntroScreen({super.key});

  @override
  State<GeoVibeIntroScreen> createState() => _GeoVibeIntroScreenState();
}

class _GeoVibeIntroScreenState extends State<GeoVibeIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
              Color(0xFF081019),
              Color(0xFF101B2A),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext context, Widget? child) {
              final double scale = 0.96 + (_pulse.value * 0.06);
              return Opacity(
                opacity: 0.72 + (_pulse.value * 0.28),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Container(
              width: 148,
              height: 148,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF56E6DC).withValues(alpha: 0.62),
                  width: 2,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x6656E6DC),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/geovibe_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _LaunchStage { intro, tutorial, dashboard }
