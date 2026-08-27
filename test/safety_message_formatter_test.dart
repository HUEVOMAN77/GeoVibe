import 'package:flutter_test/flutter_test.dart';
import 'package:geovibe/services/safety_message_formatter.dart';

void main() {
  group('SafetyMessageFormatter', () {
    test('incluye enlace de Google Maps y coordenadas aproximadas', () {
      expect(
        SafetyMessageFormatter.format(latitude: 13.6929, longitude: -89.2182),
        'El sismo acaba de pasar y los sensores de GeoVibe se activaron. '
        '¡Estoy a salvo! Mi ubicación actual es: '
        'https://www.google.com/maps/search/?api=1&query=13.6929,-89.2182',
      );
    });

    test('incluye una alternativa clara cuando no hay ubicación', () {
      expect(
        SafetyMessageFormatter.format(),
        'El sismo acaba de pasar y los sensores de GeoVibe se activaron. '
        '¡Estoy a salvo! Mi ubicación actual es: Ubicación actual no disponible.',
      );
    });
  });
}
