import 'firebase_backend.dart';
import 'local_backend.dart';

class BackendUser {
  const BackendUser({
    required this.uid,
    this.email = '',
    this.name = '',
    this.role = '',
  });

  final String uid;
  final String email;
  final String name;
  final String role;
}

class BackendAuthException implements Exception {
  const BackendAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Server-side timestamp value sent with writes.
class BackendFieldValue {
  const BackendFieldValue.server();

  static const serverTimestamp = BackendFieldValue.server();
}

/// Timestamp returned from reads (mirrors Firestore's `Timestamp`).
class BackendTimestamp {
  const BackendTimestamp(this.value);
  final DateTime value;

  DateTime toDate() => value;

  @override
  bool operator ==(Object other) =>
      other is BackendTimestamp && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// A single document, mirroring `QueryDocumentSnapshot`.
class BackendDoc {
  const BackendDoc({
    required this.id,
    this.data = const <String, dynamic>{},
    this.exists = true,
  });

  final String id;
  final Map<String, dynamic> data;
  final bool exists;
}

/// A list of documents, mirroring `QuerySnapshot`.
class BackendSnapshot {
  BackendSnapshot(Iterable<BackendDoc> documents)
      : docs = List<BackendDoc>.unmodifiable(documents);

  final List<BackendDoc> docs;
}

abstract class BackendAuth {
  BackendUser? get currentUser;

  /// Restore a persisted session (token) into memory. No-op for Firebase
  /// since FirebaseAuth restores sessions itself; local uses SharedPreferences.
  Future<void> restoreSession() async {}

  Future<BackendUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<BackendUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
    String role = 'student',
  });

  Future<void> signOut();
}

abstract class BackendStore {
  BackendCollectionReference collection(String name);

  Stream<BackendSnapshot> snapshotsFor(BackendQuery query);
}

class BackendCollectionReference {
  BackendCollectionReference(this._store, this._name);

  final BackendStore _store;
  final String _name;

  BackendStore get store => _store;
  String get name => _name;

  Stream<BackendSnapshot> snapshots() =>
      _store
          .snapshotsFor(BackendQuery(this, const BackendQuerySpec(
            filters: [],
            orders: [],
            limit: null,
          )))
          .asBroadcastStream();

  BackendQuery where(String field, {dynamic isEqualTo}) =>
      BackendQuery(this, BackendQuerySpec(
        filters: [
          (field: field, value: isEqualTo),
        ],
        orders: const [],
        limit: null,
      ));

  BackendQuery orderBy(String field, {bool descending = false}) =>
      BackendQuery(this, BackendQuerySpec(
        filters: const [],
        orders: [
          (field: field, descending: descending),
        ],
        limit: null,
      ));

  BackendDocumentReference doc(String id) => _doc(id);

  BackendDocumentReference _doc(String id) {
    if (_store is FirebaseBackendStore) {
      return _store.docRef(_name, id);
    }
    return (_store as LocalBackendStore).docRef(_name, id);
  }

  Future<BackendDoc> add(Map<String, dynamic> data) {
    if (_store is FirebaseBackendStore) {
      return _store.addDoc(_name, data);
    }
    return (_store as LocalBackendStore).addDoc(_name, data);
  }
}

class BackendDocumentReference {
  BackendDocumentReference(this._store, this._name, this._id);

  final BackendStore _store;
  final String _name;
  final String _id;

  Future<BackendDoc> get() {
    if (_store is FirebaseBackendStore) {
      return _store.getDoc(_name, _id);
    }
    return (_store as LocalBackendStore).getDoc(_name, _id);
  }

  Future<void> set(Map<String, dynamic> data) {
    if (_store is FirebaseBackendStore) {
      return _store.setDoc(_name, _id, data);
    }
    return (_store as LocalBackendStore).setDoc(_name, _id, data);
  }

  Future<void> update(Map<String, dynamic> data) {
    if (_store is FirebaseBackendStore) {
      return _store.updateDoc(_name, _id, data);
    }
    return (_store as LocalBackendStore).updateDoc(_name, _id, data);
  }

  Future<void> delete() {
    if (_store is FirebaseBackendStore) {
      return _store.deleteDoc(_name, _id);
    }
    return (_store as LocalBackendStore).deleteDoc(_name, _id);
  }
}

class BackendQuerySpec {
  const BackendQuerySpec({
    required this.filters,
    required this.orders,
    required this.limit,
  });

  final List<({String field, dynamic value})> filters;
  final List<({String field, bool descending})> orders;
  final int? limit;
}

class BackendQuery {
  BackendQuery(this._source, this.spec);

  final BackendCollectionReference _source;
  final BackendQuerySpec spec;

  BackendCollectionReference get source => _source;

  Stream<BackendSnapshot> snapshots() =>
      _source._store.snapshotsFor(this).asBroadcastStream();

  BackendQuery where(String field, {dynamic isEqualTo}) => BackendQuery(
        _source,
        BackendQuerySpec(
          filters: [...spec.filters, (field: field, value: isEqualTo)],
          orders: spec.orders,
          limit: spec.limit,
        ),
      );

  BackendQuery orderBy(String field, {bool descending = false}) => BackendQuery(
        _source,
        BackendQuerySpec(
          filters: spec.filters,
          orders: [...spec.orders, (field: field, descending: descending)],
          limit: spec.limit,
        ),
      );

  BackendQuery limit(int n) => BackendQuery(
        _source,
        BackendQuerySpec(
          filters: spec.filters,
          orders: spec.orders,
          limit: n,
        ),
      );
}

/// Global entry point. Chooses the backend based on the serving host.
class Backend {
  Backend._({required this.auth, required this.store});

  static Backend? _instance;

  static Backend get instance {
    final existing = _instance;
    if (existing != null) return existing;
    if (isLocalHost) {
      final l = LocalBackend();
      _instance = Backend._(auth: l.auth, store: l.store);
    } else {
      final f = FirebaseBackend.instance;
      _instance = Backend._(auth: f.auth, store: f.store);
    }
    return _instance!;
  }

  static void resetForTest({required BackendAuth auth, required BackendStore store}) {
    _instance = Backend._(auth: auth, store: store);
  }

  final BackendAuth auth;
  final BackendStore store;

  static bool get isLocalHost {
    final uri = Uri.base;
    final host = uri.host.toLowerCase();
    if (host != 'localhost' && host != '127.0.0.1') return false;
    // XAMPP serves the app under /quizflow/ (or classic XAMPP port 8080).
    return uri.port == 8080 || uri.path.contains('/quizflow');
  }
}