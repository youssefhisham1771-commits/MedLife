import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlife_admin/admin_login.dart';

void main() {
  testWidgets('Redesigned admin login renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminLogin()));
    expect(find.text('MedLife'), findsOneWidget);
    expect(find.text('ADMIN CONTROL CENTER'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
