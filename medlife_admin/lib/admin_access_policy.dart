/// Centralized client-side navigation policy. Firestore rules and callable
/// functions remain the authoritative security boundary.
const Map<int, List<String>> adminSectionRequiredPermissions = {
  0: ['dashboard.view'],
  1: ['orders.view', 'orders.update'],
  2: ['products.view', 'products.create', 'products.update', 'products.delete'],
  3: ['inventory.view', 'inventory.manage'],
  4: ['customers.view', 'orders.view'],
  5: ['categories.manage'],
  6: ['marketing.manage'],
  // Both reports permission and order-read permission are required because
  // these pages query /orders directly under Firestore rules.
  7: ['reports_finance.view', 'orders.view'],
  8: ['reports_finance.view', 'orders.view'],
  // Staff directory and AI assistant remain Super Admin-only until their
  // staff-facing server authorization and permission contracts are complete.
  10: ['notifications.manage'],
  12: ['settings.manage'],
  13: ['activity_log.view'],
  14: ['backup.manage'],
};

bool canAccessAdminSection({
  required int sectionIndex,
  required bool isSuperAdmin,
  required Set<String> permissions,
}) {
  if (isSuperAdmin) return true;
  final required = adminSectionRequiredPermissions[sectionIndex];
  return required != null &&
      required.isNotEmpty &&
      required.every(permissions.contains);
}
