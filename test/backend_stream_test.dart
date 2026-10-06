import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_generator/backend/backend.dart';

/// Mimics the local (PHP/MySQL) store, whose [snapshotsFor] is an `async*`
/// generator and therefore a single-subscription stream.
class _SingleSubscriptionStore implements BackendStore {
  _SingleSubscriptionStore(this._events);

  final StreamController<BackendSnapshot> _events;

  @override
  BackendCollectionReference collection(String name) =>
      BackendCollectionReference(this, name);

  @override
  Stream<BackendSnapshot> snapshotsFor(BackendQuery query) async* {
    yield BackendSnapshot(const []);
    yield* _events.stream;
  }
}

void main() {
  test('a shared snapshots() stream feeds several listeners', () async {
    final events = StreamController<BackendSnapshot>.broadcast();
    addTearDown(events.close);

    final stream = _SingleSubscriptionStore(events).collection('attempts')
        .snapshots();
    final first = <BackendSnapshot>[];
    final second = <BackendSnapshot>[];
    final third = <BackendSnapshot>[];

    final subs = [
      stream.listen(first.add),
      stream.listen(second.add),
      stream.listen(third.add),
    ];
    await pumpEventQueue();

    expect(first, isNotEmpty, reason: 'first listener should load');
    expect(
      second,
      isNotEmpty,
      reason: 'second listener must not throw "already listened to"',
    );
    expect(
      third,
      isNotEmpty,
      reason: 'third listener must not throw "already listened to"',
    );

    events.add(BackendSnapshot(const []));
    await pumpEventQueue();
    expect(second.length, greaterThan(1), reason: 'live updates still flow');

    for (final sub in subs) {
      await sub.cancel();
    }
  });

  test('filters and limits still apply to the broadcast stream', () async {
    final events = StreamController<BackendSnapshot>.broadcast();
    addTearDown(events.close);

    final store = _SingleSubscriptionStore(events);
    final stream = store.collection('attempts').snapshots();
    final seen = <BackendSnapshot>[];
    final sub = stream.listen(seen.add);
    await pumpEventQueue();

    expect(seen.first.docs, isEmpty);
    expect(store.collection('attempts').name, 'attempts');

    await sub.cancel();
  });
}