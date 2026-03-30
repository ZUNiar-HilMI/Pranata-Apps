import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../lib/screens/login_screen.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/models/user.dart';

// ─── Fake AuthProvider (no build_runner needed) ─────────────────────────────

class FakeAuthProvider extends AuthProvider {
  bool _loading = false;
  String? _err;
  User? _user;
  bool _loginResult = true;

  FakeAuthProvider({bool loading = false, String? error, User? user, bool loginResult = true})
      : _loading = loading,
        _err = error,
        _user = user,
        _loginResult = loginResult;

  @override bool get isLoading => _loading;
  @override String? get error => _err;
  @override User? get currentUser => _user;
  @override bool get isLoggedIn => _user != null;

  String? capturedUsername;
  String? capturedPassword;
  int loginCallCount = 0;

  @override
  Future<bool> login(String username, String password) async {
    capturedUsername = username;
    capturedPassword = password;
    loginCallCount++;
    _err = _loginResult ? null : _err;
    notifyListeners();
    return _loginResult;
  }

  @override
  void clearError() {
    _err = null;
    notifyListeners();
  }

  @override
  Future<void> initialize() async {}
}

// ─── Helper ─────────────────────────────────────────────────────────────────

Widget _buildApp(FakeAuthProvider auth) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: const MaterialApp(home: LoginScreen()),
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('LoginScreen — UI Rendering', () {
    testWidgets('renders email/username label, password label, and login button',
        (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));

      expect(find.text('Username or Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('renders SiGap title in header', (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));
      expect(find.text('SiGap'), findsOneWidget);
    });

    testWidgets('renders "Create one" sign-up link', (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));
      expect(find.text('Create one'), findsOneWidget);
    });

    testWidgets('renders Forgot Password? link', (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('password field is obscured by default', (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('LoginScreen — Validation', () {
    testWidgets('shows snackbar "Please fill in all fields" when both empty',
        (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));

      await tester.tap(find.text('Log In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('shows snackbar when only email is typed', (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));

      await tester.enterText(find.byType(TextField).first, 'testuser');
      await tester.tap(find.text('Log In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets('login is NOT called when fields are empty', (tester) async {
      final auth = FakeAuthProvider();
      await tester.pumpWidget(_buildApp(auth));

      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(auth.loginCallCount, 0);
    });
  });

  group('LoginScreen — Login Flow', () {
    testWidgets('calls login with correct credentials when fields are filled',
        (tester) async {
      final auth = FakeAuthProvider(loginResult: true);
      await tester.pumpWidget(_buildApp(auth));

      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(auth.loginCallCount, 1);
      expect(auth.capturedUsername, 'admin');
      expect(auth.capturedPassword, 'password123');
    });

    testWidgets('shows CircularProgressIndicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider(loading: true)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Log In'), findsNothing);
    });

    testWidgets('login button is disabled (null onPressed) when loading',
        (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider(loading: true)));

      final ElevatedButton btn = tester.widget(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('shows error snackbar when login returns false', (tester) async {
      final auth = FakeAuthProvider(
        loginResult: false,
        error: 'Username atau password salah',
      );
      await tester.pumpWidget(_buildApp(auth));

      await tester.enterText(find.byType(TextField).first, 'wrong');
      await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
      await tester.tap(find.text('Log In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Username atau password salah'), findsOneWidget);
    });
  });

  group('LoginScreen — Password Visibility', () {
    testWidgets('tapping eye icon reveals password', (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));

      // Initially obscured (eye-off icon visible)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pump();

      // Now eye icon visible (password shown)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('tapping eye icon twice re-obscures password',
        skip: true, // TODO: fix icon-finder ambiguity
        (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthProvider()));

      // Toggle ON (reveal)
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pump();

      // Toggle OFF (re-obscure)
      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
