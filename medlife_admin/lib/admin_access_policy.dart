/// Centralized client-side navigation policy. Firestore rules and callable
/// functions remain the authoritative security boundary.
///
/// Every permission listed for a section is required before the section is
/// shown. Individual controls must still enforce their own action permissions.
const Map<int, List<String>> adminSectionRequiredPermissions = {
  0: ['dashboard.view'],
  1: ['orders.view'],
  // The product module exposes create, edit, and delete actions. Keep the
  // whole module hidden unless every exposed action is authorized.
  2: [
    'products.view',
    'products.create',
    'products.update',
    'products.delete',
  ],
  3: ['inventory.view'],
  // Customer history reads both customer profiles and their orders.
  4: ['customers.view', 'orders.view'],
  5: ['categories.manage'],
  6: ['marketing.manage'],
  // Analytics and finance reports aggregate order data and financial reports.
  7: ['reports_finance.view', 'orders.view'],
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
