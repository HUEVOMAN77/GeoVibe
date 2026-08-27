import 'package:firebase_database/firebase_database.dart';

import '../models/vibration_event.dart';

class VibrationRepository {
  VibrationRepository(this._database);

  final FirebaseDatabase _database;

  DatabaseReference get _events => _database.ref('vibration_events');

  Future<String> publish(VibrationEvent event) async {
    final DatabaseReference record = _events.push();
    await record.set(event.toFirebaseJson());
    return record.key ?? event.timestamp.microsecondsSinceEpoch.toString();
  }

  Stream<List<VibrationEvent>> watchRecent({int limit = 30}) {
    return _events.limitToLast(limit).onValue.map((
      DatabaseEvent databaseEvent,
    ) {
      final Object? raw = databaseEvent.snapshot.value;
      if (raw is! Map) return const <VibrationEvent>[];

      final List<VibrationEvent> events = <VibrationEvent>[];
      raw.forEach((Object? key, Object? value) {
        if (value is Map) {
          events.add(VibrationEvent.fromMap(value, id: key?.toString()));
        }
      });
      events.sort(
        (VibrationEvent a, VibrationEvent b) =>
            b.timestamp.compareTo(a.timestamp),
      );
      return events;
    });
  }
}
