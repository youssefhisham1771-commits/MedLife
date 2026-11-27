import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medlife_admin/admin_access_policy.dart';
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

  group('admin section permission policy', () {
    test('analytics and reports require both report and order access', () {
      expect(canAccessAdminSection(
        sectionIndex: 7,
        isSuperAdmin: false,
        permissions: {'reports_finance.view'},
      ), isFalse);
      expect(canAccessAdminSection(
        sectionIndex: 8,
        isSuperAdmin: false,
        permissions: {'reports_finance.view', 'orders.view'},
      ), isTrue);
    });

    test('customer history requires customer and order access', () {
      expect(canAccessAdminSection(
        sectionIndex: 4,
        isSuperAdmin: false,
        permissions: {'customers.view'},
      ), isFalse);
      expect(canAccessAdminSection(
        sectionIndex: 4,
        isSuperAdmin: false,
        permissions: {'customers.view', 'orders.view'},
      ), isTrue);
    });

    test('write-enabled modules are hidden unless all exposed actions are allowed', () {
      expect(canAccessAdminSection(
        sectionIndex: 2,
        isSuperAdmin: false,
        permissions: {'products.view', 'products.create'},
      ), isFalse);
      expect(canAccessAdminSection(
        sectionIndex: 2,
        isSuperAdmin: false,
        permissions: {
          'products.view', 'products.create', 'products.update', 'products.delete'
        },
      ), isTrue);
    });

    test('staff-only modules stay hidden and super admin can access all modules', () {
      expect(canAccessAdminSection(
        sectionIndex: 9,
        isSuperAdmin: false,
        permissions: {'staff.manage'},
      ), isFalse);
      expect(canAccessAdminSection(
        sectionIndex: 14,
        isSuperAdmin: true,
        permissions: const {},
      ), isTrue);
    });
  });
}
