import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../lib/screens/home_screen.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/models/user.dart';
import '../helpers/test_helpers.dart';

// ─── Fake AuthProvider (no build_runner needed) ─────────────────────────────

class FakeAuthProvider extends AuthProvider {
  final User? _fakeUser;

  FakeAuthProvider(this._fakeUser);

  @override User? get currentUser => _fakeUser;
  @override bool get isLoggedIn => _fakeUser != null;
  @override bool get isLoading => false;
  @override String? get error => null;

  @override Future<void> initialize() async {}
  @override Future<bool> login(String u, String p) async => false;
  @override Future<void> logout() async {}
}

// ─── Helper ─────────────────────────────────────────────────────────────────

Widget _buildApp(FakeAuthProvider auth) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: const MaterialApp(home: HomeScreen()),
  );
}

/// Use this instead of pumpAndSettle() when OfflineBanner is present.
/// OfflineBanner uses a StreamBuilder that never "settles", so pumpAndSettle
/// would timeout. We pump the animation duration + a few extra frames instead.
Future<void> _pumpFABAnimation(WidgetTester tester) async {
  // AnimationController duration is 300ms
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(); // one extra frame to finalize
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen — Admin view', () {
    late FakeAuthProvider adminAuth;

    setUp(() {
      adminAuth = FakeAuthProvider(TestData.createAdminUser());
    });

    testWidgets('renders Activity Dashboard title', (tester) async {
      await tester.pumpWidget(_buildApp(adminAuth));
      await tester.pump();

      expect(find.text('Activity Dashboard'), findsOneWidget);
    });

    testWidgets('FAB is visible', (tester) async {
      await tester.pumpWidget(_buildApp(adminAuth));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('admin speed dial shows "admin verification"', (tester) async {
      await tester.pumpWidget(_buildApp(adminAuth));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFABAnimation(tester);

      expect(find.text('admin verification'), findsOneWidget);
    });

    testWidgets('bottom navigation bar is present', (tester) async {
      await tester.pumpWidget(_buildApp(adminAuth));
      await tester.pump();

      expect(find.byType(BottomAppBar), findsOneWidget);
    });

    testWidgets('year selector displays current year', (tester) async {
      await tester.pumpWidget(_buildApp(adminAuth));
      await tester.pump();

      expect(find.text(DateTime.now().year.toString()), findsOneWidget);
    });
  });

  group('HomeScreen — Member view', () {
    late FakeAuthProvider memberAuth;

    setUp(() {
      memberAuth = FakeAuthProvider(TestData.createTestUser(role: 'member'));
    });

    testWidgets('renders Activity Dashboard title', (tester) async {
      await tester.pumpWidget(_buildApp(memberAuth));
      await tester.pump();

      expect(find.text('Activity Dashboard'), findsOneWidget);
    });

    testWidgets('FAB is visible', (tester) async {
      await tester.pumpWidget(_buildApp(memberAuth));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('member speed dial shows "input kegiatan"', (tester) async {
      await tester.pumpWidget(_buildApp(memberAuth));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFABAnimation(tester);

      expect(find.text('input kegiatan'), findsOneWidget);
    });

    testWidgets('member speed dial does NOT show "admin verification"',
        (tester) async {
      await tester.pumpWidget(_buildApp(memberAuth));
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFABAnimation(tester);

      expect(find.text('admin verification'), findsNothing);
    });

    testWidgets('Home label is in bottom nav', (tester) async {
      await tester.pumpWidget(_buildApp(memberAuth));
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('HomeScreen — FAB behavior', () {
    testWidgets('tapping FAB opens speed dial overlay', (tester) async {
      final auth = FakeAuthProvider(TestData.createTestUser());
      await tester.pumpWidget(_buildApp(auth));
      await tester.pump();

      expect(find.text('input kegiatan'), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFABAnimation(tester);

      expect(find.text('input kegiatan'), findsOneWidget);
    });

    testWidgets('tapping FAB again closes speed dial', (tester) async {
      final auth = FakeAuthProvider(TestData.createTestUser());
      await tester.pumpWidget(_buildApp(auth));
      await tester.pump();

      // Open
      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFABAnimation(tester);
      expect(find.text('input kegiatan'), findsOneWidget);

      // Close
      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFABAnimation(tester);
      expect(find.text('input kegiatan'), findsNothing);
    });
  });
}
