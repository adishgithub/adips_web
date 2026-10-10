import 'package:adips_web/utils/http/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late http.Client original;
  late int unauthorizedCalls;

  setUp(() {
    original = AdipsHttpHelper.client;
    unauthorizedCalls = 0;
    AdipsHttpHelper.onUnauthorized = () => unauthorizedCalls++;
  });

  tearDown(() {
    AdipsHttpHelper.client = original;
    AdipsHttpHelper.onUnauthorized = null;
  });

  test('sends the raw token in the Authorization header, never Cookie', () async {
    late http.BaseRequest seen;
    AdipsHttpHelper.client = MockClient((req) async {
      seen = req;
      return http.Response('{"success":true,"data":{}}', 200);
    });

    await AdipsHttpHelper.get('/api/v1/accounts', cookie: 'Authorization=abc123');

    expect(seen.headers['Authorization'], 'abc123');
    expect(seen.headers.containsKey('Cookie'), isFalse);
  });

  test('401 on a request that carried a token calls onUnauthorized', () async {
    AdipsHttpHelper.client = MockClient(
        (req) async => http.Response('{"message":"Unauthorized"}', 401));

    await expectLater(
      AdipsHttpHelper.get('/api/v1/accounts', cookie: 'Authorization=expired'),
      throwsA(isA<ApiException>()),
    );
    expect(unauthorizedCalls, 1);
  });

  test('401 on login (no token sent) does not end a session', () async {
    AdipsHttpHelper.client = MockClient(
        (req) async => http.Response('{"message":"Invalid credentials"}', 401));

    await expectLater(
      AdipsHttpHelper.post('/api/v1/users/login', {'email': 'a@b.c', 'password': 'x'}),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Invalid credentials')),
    );
    expect(unauthorizedCalls, 0);
  });

  test('non-JSON error body (e.g. HTML 502) still gives a readable error', () async {
    AdipsHttpHelper.client =
        MockClient((req) async => http.Response('<html>Bad gateway</html>', 502));

    await expectLater(
      AdipsHttpHelper.get('/api/v1/accounts'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 502)),
    );
  });
}
