class SafetyMessageFormatter {
  SafetyMessageFormatter._();

  static const String _prefix =
      'El sismo acaba de pasar y los sensores de GeoVibe se activaron. '
      '¡Estoy a salvo! Mi ubicación actual es: ';

  static String format({double? latitude, double? longitude}) {
    if (latitude == null || longitude == null) {
      return '$_prefix'
          'Ubicación actual no disponible.';
    }

    final String coordinates =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    return '$_prefix'
        'https://www.google.com/maps/search/?api=1&query=$coordinates';
  }
}
