import 'package:firebase_core/firebase_core.dart';

import 'dart:io' show Platform;

/// Opciones de Firebase del proyecto GeoVibe suministradas por el usuario.
///
/// Firebase requiere el registro Android correspondiente en la consola del
/// proyecto si se añaden servicios que dependan de `google-services.json`.
/// Realtime Database puede inicializarse con estas opciones de cliente.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (Platform.isAndroid) {
      return android;
    }
    throw UnsupportedError('GeoVibe está configurada para Android.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7LKJyNrYxP0ANHeAdI5S2aL9MV8P942M',
    appId: '1:672346654425:android:5ca2b0d5a36d30b364e0c8',
    messagingSenderId: '672346654425',
    projectId: 'geovibe-f179d',
    databaseURL: 'https://geovibe-f179d-default-rtdb.firebaseio.com',
    storageBucket: 'geovibe-f179d.firebasestorage.app',
    authDomain: 'geovibe-f179d.firebaseapp.com',
  );
}
