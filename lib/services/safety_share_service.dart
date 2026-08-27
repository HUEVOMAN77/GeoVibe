import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'safety_message_formatter.dart';

enum SafetyShareChannel { whatsapp, facebook, sms }

class SafetyShareService {
  SafetyShareService._();

  static const MethodChannel _channel = MethodChannel('geovibe/safety_share');

  static Future<String> createSafetyMessage() async {
    final Position? position = await _currentPosition();
    return SafetyMessageFormatter.format(
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
  }

  static Future<bool> share(SafetyShareChannel channel, String message) async {
    try {
      return await _channel.invokeMethod<bool>('shareSafety', <String, String>{
            'channel': channel.name,
            'message': message,
          }) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  static Future<Position?> _currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
