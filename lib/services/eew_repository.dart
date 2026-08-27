import 'package:firebase_database/firebase_database.dart';

import '../models/eew_alert.dart';

class EewRepository {
  EewRepository(this._database);

  final FirebaseDatabase _database;

  DatabaseReference get _alerts => _database.ref('eew_alerts');

  Stream<List<EewAlert>> watchRecent({int limit = 40}) {
    return _alerts.limitToLast(limit).onValue.map((DatabaseEvent event) {
      final Object? raw = event.snapshot.value;
      if (raw is! Map) return const <EewAlert>[];
      final List<EewAlert> alerts = <EewAlert>[];
      raw.forEach((Object? key, Object? value) {
        if (value is Map) {
          alerts.add(EewAlert.fromMap(value, id: key?.toString()));
        }
      });
      alerts.sort(
        (EewAlert a, EewAlert b) => b.detectedAt.compareTo(a.detectedAt),
      );
      return alerts;
    });
  }
}
