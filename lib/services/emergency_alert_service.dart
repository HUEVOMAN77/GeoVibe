import 'dart:async';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

import '../models/eew_alert.dart';

class EmergencyAlert {
  const EmergencyAlert({required this.peak, required this.detectedAt});

  final double peak;
  final DateTime detectedAt;
}

class EmergencyAlertService {
  EmergencyAlertService._();

  static const Duration alarmDuration = Duration(seconds: 10);
  static const int _notificationId = 7312;
  static const int _eewNotificationId = 7313;
  static const String _channelId = 'geovibe_emergency_critical_v2';
  static const String _eewChannelId = 'geovibe_eew_evacuation_critical_v2';
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Timer? _autoStopTimer;
  static bool _isAlarmActive = false;

  static bool get isAlarmActive => _isAlarmActive;

  static Future<void> initialize({bool requestPermission = false}) async {
    if (!_initialized) {
      await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_geovibe'),
        ),
      );
      _initialized = true;
    }

    if (requestPermission) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestFullScreenIntentPermission();
    }
  }

  /// Emite la alarma local de vibración durante diez segundos.
  static Future<void> trigger({required double peak}) async {
    try {
      await initialize();
      await dismiss();
      _isAlarmActive = true;
      _autoStopTimer = Timer(alarmDuration, () {
        unawaited(dismiss());
      });
      await Future.wait<void>(<Future<void>>[
        FlutterRingtonePlayer().playAlarm(
          volume: 1,
          looping: true,
          asAlarm: true,
        ),
        Vibration.vibrate(preset: VibrationPreset.emergencyAlert),
        _showHeadsUpNotification(peak),
      ]);
    } catch (_) {
      // La detección y el envío a Firebase continúan aunque una salida nativa
      // no esté disponible en un modelo de dispositivo concreto.
    }
  }

  /// Activa el protocolo de evacuación enviado por Red EEW durante diez segundos.
  static Future<void> triggerEew(EewAlert alert) async {
    try {
      await initialize();
      await dismiss();
      _isAlarmActive = true;
      _autoStopTimer = Timer(alarmDuration, () {
        unawaited(dismiss());
      });
      await Future.wait<void>(<Future<void>>[
        FlutterRingtonePlayer().playAlarm(
          volume: 1,
          looping: true,
          asAlarm: true,
        ),
        Vibration.vibrate(preset: VibrationPreset.emergencyAlert),
        _showEewNotification(alert),
      ]);
    } catch (_) {
      // La capa nativa de notificación queda disponible cuando Android limita
      // el audio o vibración desde un aislado de segundo plano.
    }
  }

  /// Detiene de forma idempotente el audio, vibración y avisos del sistema.
  static Future<void> dismiss() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _isAlarmActive = false;
    try {
      await Future.wait<void>(<Future<void>>[
        FlutterRingtonePlayer().stop(),
        Vibration.cancel(),
        _notifications.cancel(id: _notificationId),
        _notifications.cancel(id: _eewNotificationId),
      ]);
    } catch (_) {
      // Se evita propagar excepciones al detector o al manejador FCM.
    }
  }

  static Future<void> _showHeadsUpNotification(double peak) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          'Alertas de emergencia GeoVibe',
          channelDescription:
              'Alertas visibles cuando GeoVibe detecta un pico de vibración.',
          importance: Importance.max,
          priority: Priority.max,
          channelBypassDnd: true,
          category: AndroidNotificationCategory.alarm,
          icon: 'ic_stat_geovibe',
          color: Color(0xFFFF5C6A),
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: false,
          enableVibration: false,
          ticker: 'Alerta de emergencia GeoVibe',
        );
    return _notifications.show(
      id: _notificationId,
      title: 'ALERTA SÍSMICA LOCAL',
      body:
          'Pico de ${peak.toStringAsFixed(2)} m/s² detectado. Revisa tu entorno.',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'emergency-alert',
    );
  }

  static Future<void> _showEewNotification(EewAlert alert) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _eewChannelId,
          'Evacuación Red EEW',
          channelDescription:
              'Avisos de evacuación prioritarios de la red colaborativa.',
          importance: Importance.max,
          priority: Priority.max,
          channelBypassDnd: true,
          category: AndroidNotificationCategory.alarm,
          icon: 'ic_stat_geovibe',
          color: Color(0xFFF04152),
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: false,
          enableVibration: false,
          ticker: 'Alerta temprana de evacuación GeoVibe',
        );
    return _notifications.show(
      id: _eewNotificationId,
      title: 'EVACUAR / BUSCAR RESGUARDO',
      body: alert.instruction,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'eew:${alert.id}',
    );
  }
}
