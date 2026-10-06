import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;

import 'backend.dart';

class FirebaseBackend {
  FirebaseBackend._()
      : auth = _FirebaseAuthBackend(),
        store = FirebaseBackendStore();

  static final FirebaseBackend instance = FirebaseBackend._();

  final BackendAuth auth;
  final BackendStore store;
}

class _FirebaseAuthBackend implements BackendAuth {
  fauth.FirebaseAuth get _a => fauth.FirebaseAuth.instance;

  @override
  Future<void> restoreSession() async {}

  @override
  BackendUser? get currentUser {
    try {
      final u = _a.currentUser;
      if (u == null) return null;
      return BackendUser(uid: u.uid, email: u.email ?? '');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BackendUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final c = await _a.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final u = c.user;
      if (u == null) throw const BackendAuthException('Sign in failed');
      return BackendUser(uid: u.uid, email: u.email ?? '');
} on fauth.FirebaseAuthException {
      const hint =
          'Incorrect email or password. Accounts created on the local site '
          '(localhost:8080) are stored separately and do not exist online.';
      throw const BackendAuthException(hint);
    }
  }

  @override
  Future<BackendUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
    String role = 'student',
  }) async {
    try {
      final c = await _a.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final u = c.user;
      if (u == null) throw const BackendAuthException('Registration failed');
      return BackendUser(uid: u.uid, email: u.email ?? '');
    } on fauth.FirebaseAuthException catch (e) {
      throw BackendAuthException(
        e.message ?? 'An error occurred during registration',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _a.signOut();
    } catch (_) {}
  }
}

class FirebaseBackendStore implements BackendStore {
  FirebaseFirestore get _f => FirebaseFirestore.instance;

  Map<String, dynamic> _convert(Map<String, dynamic> data) {
    final out = <String, dynamic>{};
    data.forEach((k, v) {
      if (v is Timestamp) {
        out[k] = BackendTimestamp(v.toDate());
      } else if (v is Map<String, dynamic>) {
        out[k] = _convert(v);
      } else if (v is List) {
        out[k] = v.map((e) {
          if (e is Timestamp) return BackendTimestamp(e.toDate());
          if (e is Map<String, dynamic>) return _convert(e);
          return e;
        }).toList();
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  dynamic _writeConvert(dynamic value) {
    if (value is BackendFieldValue) return FieldValue.serverTimestamp();
    if (value is BackendTimestamp) return Timestamp.fromDate(value.value);
    if (value is Map<String, dynamic>) {
      final out = <String, dynamic>{};
      value.forEach((k, v) => out[k] = _writeConvert(v));
      return out;
    }
    if (value is List) return value.map(_writeConvert).toList();
    return value;
  }

  Query<Map<String, dynamic>> _toQuery(String name, BackendQuerySpec spec) {
    Query<Map<String, dynamic>> q = _f.collection(name);
    for (final f in spec.filters) {
      q = q.where(f.field, isEqualTo: f.value);
    }
    for (final o in spec.orders) {
      q = q.orderBy(o.field, descending: o.descending);
    }
    final lim = spec.limit;
    if (lim != null) {
      q = q.limit(lim);
    }
    return q;
  }

  @override
  BackendCollectionReference collection(String name) =>
      BackendCollectionReference(this, name);

  @override
  Stream<BackendSnapshot> snapshotsFor(BackendQuery query) {
    final q = _toQuery(query.source.name, query.spec);
    return q.snapshots().map((snap) {
      final docs = snap.docs
          .map((d) => BackendDoc(id: d.id, data: _convert(d.data())))
          .toList();
      return BackendSnapshot(docs);
    });
  }

  BackendDocumentReference docRef(String name, String id) =>
      BackendDocumentReference(this, name, id);

  Future<BackendDoc> getDoc(String name, String id) async {
    final d = await _f.collection(name).doc(id).get();
    return BackendDoc(
        id: id,
        data: d.exists ? _convert(d.data() ?? const {}) : const {},
        exists: d.exists);
  }

  Future<void> setDoc(String name, String id, Map<String, dynamic> data) =>
      _f.collection(name).doc(id).set(_writeConvert(data) as Map<String, dynamic>);

  Future<void> updateDoc(String name, String id, Map<String, dynamic> data) =>
      _f.collection(name).doc(id).update(_writeConvert(data) as Map<String, dynamic>);

  Future<void> deleteDoc(String name, String id) =>
      _f.collection(name).doc(id).delete();

  Future<BackendDoc> addDoc(String name, Map<String, dynamic> data) async {
    final ref = await _f.collection(name).add(
      _writeConvert(data) as Map<String, dynamic>,
    );
    return BackendDoc(id: ref.id);
  }
}