import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_pos/providers/auth_provider.dart';
import 'package:project_pos/services/auth_service.dart';

// ---- Mocks ----

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late AuthNotifier authNotifier;

  /// Builds a fake JWT whose payload encodes the given [sessionInstance].
  ///
  /// The token has the structure `header.payload.signature` where payload is
  /// a base64url-encoded JSON containing a `sessionInstance` field (itself a
  /// JSON string, as the real backend sends).
  String _buildFakeJwt({
    String userId = 'user-1',
    String userName = 'admin',
    String displayName = 'Admin User',
    String selectedCompanyCode = 'ACME',
    String languageVal = 'TR',
    List<String> roles = const ['ADMIN'],
  }) {
    final sessionInstance = jsonEncode({
      'userInformation': {
        'userId': userId,
        'userName': userName,
        'displayName': displayName,
        'selectedCompanyCode': selectedCompanyCode,
        'languageVal': languageVal,
      },
      'roles': roles,
    });
    final payload = jsonEncode({'sessionInstance': sessionInstance});
    final encoded = base64Url.encode(utf8.encode(payload));
    // header and signature are not validated by _decodeUserFromJwt
    return 'eyJhbGciOiJIUzI1NiJ9.$encoded.fakesig';
  }

  /// Returns a login response map matching the structure AuthNotifier expects.
  Map<String, dynamic> _loginResponse({
    String? accessToken,
    String refreshToken = 'refresh-abc',
    String sessionId = 'sess-1',
  }) {
    return {
      'status': 200,
      'payload': {
        'accessToken': accessToken ?? _buildFakeJwt(),
        'refreshToken': refreshToken,
        'sessionId': sessionId,
      },
    };
  }

  setUp(() {
    // Initialize SharedPreferences with empty values for tests
    SharedPreferences.setMockInitialValues({});
    mockAuthService = MockAuthService();
    authNotifier = AuthNotifier(mockAuthService);
  });

  tearDown(() {
    authNotifier.dispose();
  });

  // ---------------------------------------------------------------------------
  // Login success
  // ---------------------------------------------------------------------------

  group('login success', () {
    test('transitions to authenticated state with user data', () async {
      final fakeJwt = _buildFakeJwt(
        userId: 'u-42',
        userName: 'testuser',
        displayName: 'Test User',
        selectedCompanyCode: 'ACME',
      );

      when(() => mockAuthService.login('testuser', 'pass123'))
          .thenAnswer((_) async => _loginResponse(accessToken: fakeJwt));

      await authNotifier.login('testuser', 'pass123');

      final state = authNotifier.debugState;
      expect(state.isAuthenticated, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.token, fakeJwt);
      expect(state.user?.id, 'u-42');
      expect(state.user?.username, 'testuser');
      expect(state.user?.displayName, 'Test User');
      expect(state.user?.selectedCompanyCode, 'ACME');
      expect(state.user?.roles, ['ADMIN']);
    });

    test('stores token and user in SharedPreferences', () async {
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) async => _loginResponse());

      await authNotifier.login('admin', 'secret');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNotNull);
      expect(prefs.getString('refresh_token'), 'refresh-abc');
      expect(prefs.getString('session_id'), 'sess-1');
      expect(prefs.getString('user_data'), isNotNull);
    });

    test('stores company code when present', () async {
      final jwt = _buildFakeJwt(selectedCompanyCode: 'CORP');
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) async => _loginResponse(accessToken: jwt));

      await authNotifier.login('admin', 'secret');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('company_code'), 'CORP');
    });
  });

  // ---------------------------------------------------------------------------
  // Login failure
  // ---------------------------------------------------------------------------

  group('login failure', () {
    test('sets error state when service throws', () async {
      when(() => mockAuthService.login(any(), any()))
          .thenThrow(Exception('Invalid credentials'));

      expect(
        () => authNotifier.login('bad', 'creds'),
        throwsException,
      );

      // After the rethrow, state should have error info
      final state = authNotifier.debugState;
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('Invalid credentials'));
    });

    test('sets error state when backend returns non-200 status', () async {
      when(() => mockAuthService.login(any(), any())).thenAnswer((_) async => {
            'status': 401,
            'messages': ['Bad credentials'],
          });

      expect(
        () => authNotifier.login('bad', 'creds'),
        throwsException,
      );

      final state = authNotifier.debugState;
      expect(state.isAuthenticated, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  group('logout', () {
    test('clears tokens and resets state to initial', () async {
      // First login to have some state
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) async => _loginResponse());

      await authNotifier.login('admin', 'secret');
      expect(authNotifier.debugState.isAuthenticated, isTrue);

      // Now logout
      await authNotifier.logout();

      final state = authNotifier.debugState;
      expect(state.isAuthenticated, isFalse);
      expect(state.user, isNull);
      expect(state.token, isNull);
      expect(state.refreshToken, isNull);
      expect(state.sessionId, isNull);
    });

    test('removes stored tokens from SharedPreferences', () async {
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) async => _loginResponse());

      await authNotifier.login('admin', 'secret');
      await authNotifier.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('refresh_token'), isNull);
      expect(prefs.getString('user_data'), isNull);
      expect(prefs.getString('session_id'), isNull);
      expect(prefs.getString('company_code'), isNull);
    });
  });
}
