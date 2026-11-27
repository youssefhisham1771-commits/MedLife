/// Centralized client-side navigation policy. Firestore rules and callable
/// functions remain the authoritative security boundary.
///
/// A section is visible when the user has its read permission. Write permissions
/// are checked separately by the individual controls inside each module.
const Map<int, List<String>> adminSectionRequiredPermissions = {
  0: ['dashboard.view'],
  1: ['orders.view'],
  2: ['products.view'],
  3: ['inventory.view'],
  4: ['customers.view', 'orders.view'],
  5: ['categories.manage'],
  6: ['marketing.manage'],
  7: ['orders.view'],
  // Finance reports query the orders collection as well.
  8: ['reports_finance.view', 'orders.view'],
  // Staff directory and AI assistant remain Super Admin-only until their
  // server authorization and permission contracts are complete.
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
