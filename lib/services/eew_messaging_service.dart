import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import '../models/eew_alert.dart';
import 'emergency_alert_service.dart';

class EewDelivery {
  const EewDelivery({required this.alert, required this.shouldSound});

  final EewAlert alert;
  final bool shouldSound;
}

@pragma('vm:entry-point')
Future<void> firebaseEewBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!EewAlert.isEewPayload(message.data)) return;
  final EewAlert alert = EewAlert.fromMap(
    Map<Object?, Object?>.from(message.data),
    id: message.messageId,
  );
  await EmergencyAlertService.triggerEew(alert);
}

class EewMessagingService {
  EewMessagingService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  static const String topic = 'geovibe_eew';

  final FirebaseMessaging _messaging;
  final StreamController<EewDelivery> _deliveries =
      StreamController<EewDelivery>.broadcast();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  Stream<EewDelivery> get deliveries => _deliveries.stream;

  Future<String?> connect() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.subscribeToTopic(topic);
    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) => _route(message, shouldSound: true),
    );
    _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) => _route(message, shouldSound: false),
    );
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _route(initialMessage, shouldSound: false);
    return _messaging.getToken();
  }

  void _route(RemoteMessage message, {required bool shouldSound}) {
    if (!EewAlert.isEewPayload(message.data)) return;
    _deliveries.add(
      EewDelivery(
        alert: EewAlert.fromMap(
          Map<Object?, Object?>.from(message.data),
          id: message.messageId,
        ),
        shouldSound: shouldSound,
      ),
    );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _deliveries.close();
  }
}
