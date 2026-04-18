import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:protectme/screens/profile/profile_screen.dart';
import 'package:protectme/models/firestore_user.dart';
import 'package:protectme/services/language_service.dart';

void main() {
  testWidgets('Admin button navigates to /admin/users', (
    WidgetTester tester,
  ) async {
    // Create a test FirestoreUser with role 'admin'
    final testFsUser = FirestoreUser(
      id: 'u1',
      name: 'Admin User',
      email: 'admin@example.com',
      birthDate: DateTime(1990, 1, 1),
      role: 'admin',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => LanguageService())],
        child: MaterialApp(
          routes: {
            '/admin/users': (_) =>
                Scaffold(body: Center(child: Text('ADMIN USERS PAGE'))),
          },
          home: ProfileScreen(testFirestoreUser: testFsUser),
        ),
      ),
    );

    // Wait for async init
    await tester.pumpAndSettle();

    // Expect the manage users button to be present
    final manageBtn = find.byKey(Key('manageUsersButton'));
    expect(manageBtn, findsOneWidget);

    // Tap and verify navigation
    await tester.tap(manageBtn);
    await tester.pumpAndSettle();

    expect(find.text('ADMIN USERS PAGE'), findsOneWidget);
  });
}
