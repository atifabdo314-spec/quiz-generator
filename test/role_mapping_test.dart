import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_generator/backend/local_backend.dart';

void main() {
  test('maps Flutter roles to local API role names', () {
    expect(apiRoleName('instructor'), 'teacher');
    expect(apiRoleName('admin'), 'admin');
    expect(apiRoleName('student'), 'student');
    expect(apiRoleName('unknown'), 'student');
  });
}