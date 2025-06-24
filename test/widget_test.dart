// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lojinha_flutter/main.dart';
import 'package:lojinha_flutter/models/theme_provider.dart';
import 'package:lojinha_flutter/models/user_provider.dart';
import 'package:lojinha_flutter/screens/login_screen.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => UserProvider()),
        ],
        child: const MyApp(initialScreen: LoginScreen()),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Build the login screen
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => UserProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Verify that login screen elements are present
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
