import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlife_admin/admin_login.dart';

void main() {
  testWidgets('Admin login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminLogin()));

    expect(find.text('MEDLIFE ADMIN'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
