import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlife_admin/main.dart';

void main() {
  testWidgets('Admin login page renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminLoginPage()),
    );

    expect(find.text('MedLife Admin'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
