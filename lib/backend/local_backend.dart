import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';

class BackendHttpException implements Exception {
  const BackendHttpException(this.status, this.message);
  final int? status;
  final String message;
  @override
  String toString() => message;
}

class LocalApiClient {
  LocalApiClient(this.baseUrl, this.token);

  final String baseUrl;
  String token;

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? query,
    Object? body,
    bool auth = false,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ));
    try {
      final r = await dio.request<dynamic>(
        path,
        queryParameters: query,
        data: body,
        options: Options(method: method),
      );
      return r.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      var msg = e.message ?? 'Connection error';
      final data = e.response?.data;
      if (data is Map) {
        final err = data['error'];
        if (err is String && err.isNotEmpty) msg = err;
      }
      if (status == 401 || status == 403) {
        throw BackendAuthException(msg);
      }
      throw BackendHttpException(status, msg);
    }
  }
}

String apiRoleName(String role) =>
    role == 'admin' ? 'admin' : (role == 'instructor' ? 'teacher' : 'student');

class LocalAuthBackend implements BackendAuth {
  LocalAuthBackend(this._api);

  final LocalApiClient _api;
  BackendUser? _user;

  static const _tokenKey = 'qf_token';
  static const _userKey = 'qf_user';

  static String _apiBase() {
    final origin = Uri.base.origin;
    return '$origin/quizflow/api';
  }

  @override
  BackendUser? get currentUser => _user;

  @override
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final raw = prefs.getString(_userKey);
      if (token == null || raw == null) return;
      _api.token = token;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _user = BackendUser(
        uid: map['uid']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        role: map['role']?.toString() ?? '',
      );
    } catch (_) {}
  }

  Future<void> _save(String token, BackendUser user) async {
    _api.token = token;
    _user = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(
        _userKey,
        jsonEncode({
          'uid': user.uid,
          'email': user.email,
          'name': user.name,
          'role': user.role,
        }),
      );
    } catch (_) {}
  }

  BackendUser _fromApi(Map<String, dynamic> user) => BackendUser(
        uid: user['user_id'].toString(),
        email: user['email']?.toString() ?? '',
        name: user['username']?.toString() ?? '',
        role: user['role']?.toString() ?? '',
      );

  @override
  Future<BackendUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _api.request(
        '/auth/login',
        method: 'POST',
        body: {'identifier': email, 'password': password},
      ) as Map<String, dynamic>;
      final user = _fromApi(data['user'] as Map<String, dynamic>);
      await _save(data['token'].toString(), user);
      return user;
    } on BackendAuthException {
      throw const BackendAuthException(
        'Incorrect email or password. Note: accounts are not shared between '
        'this local site and the online site.',
      );
    }
  }

  @override
  Future<BackendUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
    String role = 'student',
  }) async {
    final data = await _api.request(
      '/auth/register',
      method: 'POST',
      body: {
        'name': (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : email.split('@').first,
        'email': email,
        'password': password,
        'role': apiRoleName(role),
      },
      auth: true,
    ) as Map<String, dynamic>;
    final user = _fromApi(data['user'] as Map<String, dynamic>);
    await _save(data['token'].toString(), user);
    return user;
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.request('/auth/logout', method: 'POST');
    } catch (_) {}
    _api.token = '';
    _user = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
  }
}

class LocalBackend {
  LocalBackend()
      : api = LocalApiClient(LocalAuthBackend._apiBase(), ''),
        cache = {} {
    auth = LocalAuthBackend(api);
    store = LocalBackendStore(this);
    debugPrint('QuizFlow: local backend (PHP/MySQL) @ ${api.baseUrl}');
  }

  final LocalApiClient api;
  final Map<String, List<BackendDoc>> cache;
  final StreamController<void> _bus = StreamController<void>.broadcast();

  late final LocalAuthBackend auth;
  late final LocalBackendStore store;

  Stream<void> get changes => _bus.stream;

  void bump() {
    cache.clear();
    if (!_bus.isClosed) _bus.add(null);
  }
}

class LocalBackendStore implements BackendStore {
  LocalBackendStore(this._backend);

  final LocalBackend _backend;

  LocalApiClient get _api => _backend.api;

  static BackendTimestamp _ts(String? sql) {
    if (sql == null || sql.isEmpty) return BackendTimestamp(DateTime.now());
    return BackendTimestamp(DateTime.tryParse(sql.replaceFirst(' ', 'T')) ?? DateTime.now());
  }

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  List<BackendDoc> _transform(String name, List<dynamic> rows) {
    switch (name) {
      case 'users':
        return [
          for (final r in rows)
            BackendDoc(
              id: r['user_id'].toString(),
              data: {
                'name': r['username'] ?? '',
                'email': r['email'] ?? '',
                'role': r['role'] ?? 'student',
                'createdAt': _ts(r['created_at']?.toString()),
              },
            ),
        ];
      case 'subjects':
        return [
          for (final r in rows)
            BackendDoc(
              id: r['subject_id'].toString(),
              data: {
                'name': r['name'] ?? '',
                'createdAt': _ts(r['created_at']?.toString()),
              },
            ),
        ];
      case 'quizzes':
        return [
          for (final r in rows)
            BackendDoc(
              id: r['quiz_id'].toString(),
              data: {
                'title': r['title'] ?? '',
                'course': r['course'] ?? '',
                'duration': r['duration'] ?? 0,
                'maxAttempts': r['max_attempts'] ?? 1,
                'resultPolicy': 'immediate',
                'published': (r['published'] ?? 0) == 1,
                'createdAt': _ts(r['publish_date']?.toString()),
                'teacher_name': r['teacher_name'] ?? '',
                'question_count': r['question_count'] ?? 0,
              },
            ),
        ];
      case 'questions':
        return [
          for (final r in rows)
            BackendDoc(
              id: r['question_id'].toString(),
              data: _questionDoc(
                r['question_id'].toString(),
                r['question_text'] ?? '',
                r['course'] ?? '',
                r['degree'] ?? 1,
                r['difficulty']?.toString() ?? 'medium',
                r['status']?.toString() ?? 'approved',
                r['quiz_id']?.toString(),
                _ts(r['created_at']?.toString()),
                (r['options'] as List?) ?? const [],
              ),
            ),
        ];
      case 'attempts':
        return [
          for (final r in rows)
            BackendDoc(
              id: r['result_id'].toString(),
              data: {
                'userId': r['student_id'].toString(),
                'name': r['student_name'] ?? '',
                'email': r['student_email'] ?? '',
                'score': r['total_score'] ?? 0,
                'total': r['total_questions'] ?? 0,
                'percentage': (r['percentage'] ?? 0).round(),
                'quizId': r['quiz_id'].toString(),
                'quiz_title': r['quiz_title'] ?? '',
                'submittedAt': _ts(r['submission_date']?.toString()),
                'answers': (r['answers'] as List?) ?? const [],
              },
            ),
        ];
      default:
        return const [];
    }
  }

  static Map<String, dynamic> _questionDoc(
    String id,
    String title,
    String course,
    dynamic degree,
    String difficulty,
    String status,
    String? quizId,
    BackendTimestamp createdAt,
    List<dynamic> options,
  ) {
    final letters = <String, dynamic>{};
    var correctLetter = '';
    for (var i = 0; i < options.length && i < _letters.length; i++) {
      final o = options[i] as Map<String, dynamic>;
      final letter = _letters[i];
      letters[letter] = o['option_text'] ?? '';
      if ((o['is_correct'] ?? 0) == 1) correctLetter = letter;
    }
    return {
      'title': title,
      'course': course,
      'points': degree,
      'difficulty': difficulty,
      'status': status,
      'quizId': quizId,
      'createdAt': createdAt,
      'options': letters,
      'correctAnswer': correctLetter,
    };
  }

  @override
  BackendCollectionReference collection(String name) =>
      BackendCollectionReference(this, name);

  /// Fetch the full Firestore-shaped doc list for a collection from the API.
  Future<List<BackendDoc>> _fetch(String name) async {
    final cached = _backend.cache[name];
    if (cached != null) return cached;
    dynamic data;
    switch (name) {
      case 'users':
        data = await _api.request('/users');
        data = (data as Map<String, dynamic>)['users'];
        break;
      case 'subjects':
        data = await _api.request('/subjects');
        data = (data as Map<String, dynamic>)['subjects'];
        break;
      case 'quizzes':
        data = await _api.request('/quizzes');
        data = (data as Map<String, dynamic>)['quizzes'];
        break;
      case 'questions':
        data = await _api.request('/questions');
        data = (data as Map<String, dynamic>)['questions'];
        break;
      case 'attempts':
        data = await _api.request('/attempts');
        data = (data as Map<String, dynamic>)['attempts'];
        break;
      default:
        return const [];
    }
    final docs = _transform(name, (data as List?) ?? const []);
    _backend.cache[name] = docs;
    return docs;
  }

  int _cmp(dynamic a, dynamic b) {
    final ad = a is BackendTimestamp ? a.value : a;
    final bd = b is BackendTimestamp ? b.value : b;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    if (ad is num && bd is num) return ad.compareTo(bd);
    if (ad is DateTime && bd is DateTime) return ad.compareTo(bd);
    return ad.toString().compareTo(bd.toString());
  }

  List<BackendDoc> _applyQuery(List<BackendDoc> docs, BackendQuerySpec spec) {
    var out = docs;
    for (final f in spec.filters) {
      out = out
          .where((d) {
        final v = d.data[f.field];
        if (f.value is bool) return v == f.value;
        return v?.toString() == f.value?.toString();
      })
          .toList();
    }
    for (final o in spec.orders) {
      final stable = List<BackendDoc>.from(out);
      stable.sort((a, b) {
        final c = _cmp(a.data[o.field], b.data[o.field]);
        return o.descending ? -c : c;
      });
      out = stable;
    }
    final lim = spec.limit;
    if (lim != null && out.length > lim) out = out.sublist(0, lim);
    return out;
  }

  @override
  Stream<BackendSnapshot> snapshotsFor(BackendQuery query) async* {
    while (true) {
      yield BackendSnapshot(
        _applyQuery(await _fetch(query.source.name), query.spec),
      );
      await _backend.changes.first;
    }
  }

  BackendDocumentReference docRef(String name, String id) =>
      BackendDocumentReference(this, name, id);

  // -------- document reads --------

  Future<BackendDoc> getDoc(String name, String id) async {
    if (name == 'users') {
      final data = await _api.request('/users/$id');
      final user = (data as Map<String, dynamic>)['user'] as Map<String, dynamic>;
      final docs = _transform('users', [user]);
      return docs.isEmpty ? BackendDoc(id: id, exists: false) : docs.first;
    }
    if (name == 'quizzes') {
      final data = await _api.request('/quizzes/$id');
      final quiz = (data as Map<String, dynamic>)['quiz'] as Map<String, dynamic>;
      final docs = _transform('quizzes', [quiz]);
      return docs.isEmpty ? BackendDoc(id: id, exists: false) : docs.first;
    }
    final docs = await _fetch(name);
    for (final d in docs) {
      if (d.id == id) return d;
    }
    return BackendDoc(id: id, exists: false);
  }

  Future<BackendDoc> addDoc(String name, Map<String, dynamic> data) async {
    dynamic res;
    switch (name) {
      case 'subjects':
        res = await _api.request('/subjects', method: 'POST', body: {'name': data['name']});
        _backend.bump();
        return BackendDoc(id: (res as Map<String, dynamic>)['subject_id'].toString());
      case 'quizzes':
        res = await _api.request('/quizzes', method: 'POST', body: {
          'title': data['title'],
          'course': data['course'],
          'duration': (data['duration'] ?? 10),
          'max_attempts': (data['maxAttempts'] ?? 1),
          'published': (data['published'] ?? true) ? 1 : 0,
        });
        _backend.bump();
        return BackendDoc(id: (res as Map<String, dynamic>)['quiz_id'].toString());
      case 'questions':
        res = await _api.request('/questions', method: 'POST', body: _questionPayload(data, null));
        _backend.bump();
        return BackendDoc(id: (res as Map<String, dynamic>)['question_id'].toString());
      case 'attempts':
        res = await _api.request('/attempts', method: 'POST', body: await _attemptPayload(data));
        _backend.bump();
        return BackendDoc(id: (res as Map<String, dynamic>)['result_id'].toString());
      case 'users':
        res = await _api.request('/users', method: 'POST', body: {
          'name': data['name'],
          'email': data['email'],
          'role': data['role'] ?? 'student',
          'password': '1234',
        });
        _backend.bump();
        return BackendDoc(id: (res as Map<String, dynamic>)['user_id'].toString());
      default:
        throw UnsupportedError('add not supported for $name');
    }
  }

  Future<void> setDoc(String name, String id, Map<String, dynamic> data) async {
    switch (name) {
      case 'users':
        final isSelf = _backend.auth.currentUser?.uid == id;
        await _api.request('/users/$id', method: 'PUT', body: {
          if (data['name'] != null) 'name': data['name'],
          if (data['email'] != null) 'email': data['email'],
          // A user may not change their own role through the profile update.
          if (!isSelf && data['role'] != null) 'role': data['role'],
        });
        _backend.bump();
        return;
      case 'subjects':
        await _api.request('/subjects/$id', method: 'PUT', body: {'name': data['name']});
        _backend.bump();
        return;
      default:
        await updateDoc(name, id, data);
    }
  }

  Future<void> updateDoc(String name, String id, Map<String, dynamic> data) async {
    if (name == 'users') {
      await setDoc(name, id, data);
      return;
    }
    switch (name) {
      case 'subjects':
        await _api.request('/subjects/$id', method: 'PUT', body: {'name': data['name']});
        break;
      case 'questions':
        await _api.request(
          '/questions/$id',
          method: 'PUT',
          body: _questionPayload(data, id),
        );
        break;
      case 'quizzes':
        await _api.request('/quizzes/$id', method: 'PUT', body: {
          'title': data['title'],
          'course': data['course'],
          'duration': (data['duration'] ?? 10),
          'max_attempts': (data['maxAttempts'] ?? 1),
          'published': (data['published'] ?? true) ? 1 : 0,
        });
        break;
      default:
        throw UnsupportedError('update not supported for $name');
    }
    _backend.bump();
  }

  Future<void> deleteDoc(String name, String id) async {
    await _api.request('/$name/$id', method: 'DELETE');
    _backend.bump();
  }

  /// Firestore-shaped question doc -> API payload.
  ///
  /// New documents (id == null) are sent in full; updates only forward the
  /// fields the caller supplied so a partial update (e.g. assigning a question
  /// to a quiz) does not reset the others.
  Map<String, dynamic> _questionPayload(Map<String, dynamic> data, String? id) {
    final optionsMap = (data['options'] as Map<String, dynamic>?) ?? const {};
    final correct = (data['correctAnswer'] ?? '').toString();
    final payload = <String, dynamic>{};

    if (id == null) {
      payload['question_text'] = data['title'];
      payload['question_type'] = 'multiple_choice';
      if (data['points'] != null) payload['degree'] = data['points'];
      payload['difficulty'] = data['difficulty'] ?? 'medium';
      payload['status'] = data['status'] ?? 'approved';
      payload['course'] = data['course'];
    } else {
      if (data.containsKey('title')) payload['question_text'] = data['title'];
      if (data.containsKey('points')) payload['degree'] = data['points'];
      if (data.containsKey('question_type')) {
        payload['question_type'] = data['question_type'];
      }
      if (data.containsKey('difficulty')) {
        payload['difficulty'] = data['difficulty'];
      }
      if (data.containsKey('status')) payload['status'] = data['status'];
      if (data.containsKey('course')) payload['course'] = data['course'];
    }

    if (data.containsKey('quizId')) {
      final raw = data['quizId']?.toString() ?? '';
      payload['quiz_id'] = int.tryParse(raw);
    }

    if (data.containsKey('options')) {
      final options = <Map<String, dynamic>>[];
      for (final letter in _letters) {
        final v = optionsMap.containsKey(letter) ? optionsMap[letter] : null;
        if (v == null || v.toString().trim().isEmpty) break;
        options.add(_sortedOption(letter, v.toString(), letter == correct));
      }
      payload['options'] = options..sort((a, b) => a['sort'].compareTo(b['sort']));
    }

    return payload;
  }

  Map<String, dynamic> _sortedOption(String letter, String text, bool correct) => {
        'option_text': text,
        'is_correct': correct ? 1 : 0,
        'sort': _letters.indexOf(letter),
      };

  /// Firestore-shaped attempt -> API payload (maps prompt/selected text to ids).
  Future<Map<String, dynamic>> _attemptPayload(Map<String, dynamic> data) async {
    final quizId = int.tryParse(data['quizId']?.toString() ?? '') ?? 0;
    final answers = (data['answers'] as List?) ?? const [];
    final students = data['userId']?.toString() ?? '';
    final studentId = int.tryParse(students) ?? 0;

    List<dynamic> questions = const [];
    if (quizId > 0) {
      try {
        final qdata = await _api.request('/quizzes/$quizId/questions');
        questions = (qdata as Map<String, dynamic>)['questions'] as List? ?? const [];
      } catch (_) {}
    }

    final mapped = <Map<String, dynamic>>[];
    for (final a in answers) {
      final prompt = (a['prompt'] ?? '').toString().trim();
      final selected = (a['selected'] ?? '').toString().trim();
      int? qid;
      int? oid;
      for (final q in questions) {
        final qMap = q as Map<String, dynamic>;
        if (qMap['question_text']?.toString().trim() == prompt) {
          qid = (qMap['question_id'] as num).toInt();
          for (final o in (qMap['options'] as List?) ?? const []) {
            final oMap = o as Map<String, dynamic>;
            if (oMap['option_text']?.toString().trim() == selected) {
              oid = (oMap['option_id'] as num).toInt();
              break;
            }
          }
          break;
        }
      }
      if (qid != null && oid != null) {
        mapped.add({'question_id': qid, 'selected_option_id': oid});
      }
    }

    return {'quiz_id': quizId, 'student_id': studentId, 'answers': mapped};
  }
}