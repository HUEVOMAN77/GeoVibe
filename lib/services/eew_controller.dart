import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/eew_alert.dart';
import 'eew_messaging_service.dart';
import 'eew_repository.dart';
import 'emergency_alert_service.dart';

class EewController extends ChangeNotifier {
  EewController({EewRepository? repository, EewMessagingService? messaging})
    : _repository = repository ?? EewRepository(FirebaseDatabase.instance),
      _messaging = messaging ?? EewMessagingService();

  final EewRepository _repository;
  final EewMessagingService _messaging;
  StreamSubscription<List<EewAlert>>? _historySubscription;
  StreamSubscription<EewDelivery>? _deliverySubscription;
  Timer? _bannerTimer;

  bool _isReady = false;
  bool _isConnected = false;
  String? _connectionDetail;
  String? _token;
  EewAlert? _activeAlert;
  List<EewAlert> _alerts = const <EewAlert>[];

  bool get isReady => _isReady;
  bool get isConnected => _isConnected;
  String? get connectionDetail => _connectionDetail;
  String? get token => _token;
  EewAlert? get activeAlert => _activeAlert;
  List<EewAlert> get alerts => List<EewAlert>.unmodifiable(_alerts);

  Future<void> initialize() async {
    await EmergencyAlertService.initialize(requestPermission: true);
    _historySubscription = _repository.watchRecent().listen(
      (List<EewAlert> alerts) {
        _alerts = alerts;
        notifyListeners();
      },
      onError: (Object error) {
        _connectionDetail = 'No se pudo sincronizar la red: $error';
        notifyListeners();
      },
    );
    _deliverySubscription = _messaging.deliveries.listen(_handleDelivery);
    try {
      _token = await _messaging.connect();
      _isConnected = _token != null;
      _connectionDetail = _isConnected
          ? 'Suscrito al canal prioritario Red EEW.'
          : 'Esperando el registro del dispositivo en Red EEW.';
    } catch (error) {
      _isConnected = false;
      _connectionDetail = 'Red EEW sin conexión: $error';
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> _handleDelivery(EewDelivery delivery) async {
    _activeAlert = delivery.alert;
    _alerts = <EewAlert>[delivery.alert, ..._alerts]
      ..sort((EewAlert a, EewAlert b) => b.detectedAt.compareTo(a.detectedAt));
    _scheduleBannerDismissal();
    notifyListeners();
    if (delivery.shouldSound) {
      await EmergencyAlertService.triggerEew(delivery.alert);
    }
  }

  void _scheduleBannerDismissal() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer(EmergencyAlertService.alarmDuration, () {
      _activeAlert = null;
      unawaited(EmergencyAlertService.dismiss());
      notifyListeners();
    });
  }

  Future<void> dismissActiveAlert() async {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    _activeAlert = null;
    await EmergencyAlertService.dismiss();
    notifyListeners();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _historySubscription?.cancel();
    _deliverySubscription?.cancel();
    unawaited(_messaging.dispose());
    super.dispose();
  }
}
