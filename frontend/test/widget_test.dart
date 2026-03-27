import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/di/locator.dart';
import 'package:frontend/modules/auth/providers/auth_provider.dart';
import 'package:frontend/modules/auth/views/login_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: 'assets/env/defaults.env');
    await setupLocator();
  });

  testWidgets('Login page shows app title', (WidgetTester tester) async {
    final auth = AuthProvider(
      repository: getIt(),
      storage: getIt(),
      tokenRef: getIt(),
    );
    await auth.bootstrap();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('HB AI Building Estimator'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
