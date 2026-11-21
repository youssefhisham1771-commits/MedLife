const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationToAllUsers = functions.https.onRequest(async (req, res) => {
  try {
    const snapshot = await admin.firestore().collection("users").get();

    const tokens = [];

    snapshot.forEach((doc) => {
      const data = doc.data();

      if (data.fcmToken) {
        tokens.push(data.fcmToken);
      }
    });

    if (tokens.length === 0) {
      return res.send("No tokens found");
    }

    await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: "MY Store",
        body: "Hello from Firebase Cloud Function",
      },
    });

    res.send(`Notification sent to ${tokens.length} users`);
  } catch (e) {
    console.error(e);
    res.status(500).send(e.toString());
  }
});

// ============================================================
// MedLife Super Admin bootstrap
// Only the explicitly configured account can grant itself the
// initial Super Admin custom claim. This does not change Firestore
// rules or existing user documents.
// ============================================================

const { onCall, HttpsError } = require("firebase-functions/v2/https");

const MEDLIFE_SUPER_ADMIN_UID = "DmoPC05QspbB8QVKwir5Y0Zggcz1";

exports.bootstrapMedLifeSuperAdmin = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in before bootstrapping the admin account.");
  }

  if (request.auth.uid !== MEDLIFE_SUPER_ADMIN_UID) {
    throw new HttpsError("permission-denied", "This account is not authorized to bootstrap MedLife Super Admin.");
  }

  const user = await admin.auth().getUser(MEDLIFE_SUPER_ADMIN_UID);
  const existingClaims = user.customClaims || {};

  await admin.auth().setCustomUserClaims(MEDLIFE_SUPER_ADMIN_UID, {
    ...existingClaims,
    medlifeSuperAdmin: true,
    medlifeRole: "super_admin",
  });

  return {
    success: true,
    message: "MedLife Super Admin claim assigned.",
    uid: MEDLIFE_SUPER_ADMIN_UID,
  };
});

// ============================================================
// Staff permission management (Super Admin only)
// Custom claims are the authorization source; Firestore fields
// below are staff-directory metadata only.
// ============================================================

const MEDLIFE_STAFF_PERMISSIONS = new Set([
  "dashboard.view",
  "orders.view",
  "orders.update",
  "products.view",
  "products.create",
  "products.update",
  "products.delete",
  "inventory.view",
  "inventory.manage",
  "customers.view",
  "categories.manage",
  "marketing.manage",
  "reports_finance.view",
  "staff.manage",
  "notifications.manage",
  "settings.manage",
  "activity_log.view",
  "backup.manage",
]);

exports.setMedLifeStaffPermissions = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  if (request.auth.token.medlifeSuperAdmin !== true) {
    throw new HttpsError("permission-denied", "Only the Super Admin can manage staff.");
  }

  const targetUid = request.data?.targetUid;
  const active = request.data?.active ?? true;
  const requestedPermissions = request.data?.permissions;

  if (typeof targetUid !== "string" || targetUid.trim().length < 10) {
    throw new HttpsError("invalid-argument", "A valid targetUid is required.");
  }
  if (typeof active !== "boolean" || !Array.isArray(requestedPermissions)) {
    throw new HttpsError("invalid-argument", "Invalid active flag or permissions list.");
  }
  if (targetUid === MEDLIFE_SUPER_ADMIN_UID) {
    throw new HttpsError("failed-precondition", "The Super Admin cannot be modified as staff.");
  }

  const permissions = [...new Set(requestedPermissions)];
  if (
    permissions.length !== requestedPermissions.length ||
    permissions.some((permission) =>
      typeof permission !== "string" || !MEDLIFE_STAFF_PERMISSIONS.has(permission)
    )
  ) {
    throw new HttpsError("invalid-argument", "The permissions list contains invalid entries.");
  }
  if (!active && permissions.length > 0) {
    throw new HttpsError("invalid-argument", "Inactive staff must have no permissions.");
  }

  try {
    const target = await admin.auth().getUser(targetUid);
    if (target.customClaims?.medlifeSuperAdmin === true) {
      throw new HttpsError("failed-precondition", "A Super Admin cannot be managed as staff.");
    }

    const assignedPermissions = active ? permissions : [];
    await admin.auth().setCustomUserClaims(targetUid, {
      ...(target.customClaims || {}),
      medlifeRole: "staff",
      medlifePermissions: assignedPermissions,
      medlifeStaffActive: active,
    });

    await admin.firestore().collection("users").doc(targetUid).set({
      medlifeRole: "staff",
      medlifePermissions: assignedPermissions,
      medlifeStaffActive: active,
      staffPermissionsUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      staffPermissionsUpdatedBy: request.auth.uid,
    }, { merge: true });

    return { success: true, targetUid, active, permissions: assignedPermissions };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("setMedLifeStaffPermissions failed:", error);
    throw new HttpsError("internal", "Unable to update staff permissions.");
  }
});

