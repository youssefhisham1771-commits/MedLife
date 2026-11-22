const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

admin.initializeApp();

exports.sendNotificationToAllUsers = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed." });
  }

  const authorization = req.get("Authorization") || "";
  const match = authorization.match(/^Bearer (.+)$/i);
  if (!match) {
    return res.status(401).json({ error: "Authentication is required." });
  }

  let caller;
  try {
    caller = await admin.auth().verifyIdToken(match[1]);
  } catch (error) {
    return res.status(401).json({ error: "Invalid authentication token." });
  }

  const isSuperAdmin = caller.medlifeSuperAdmin === true;
  const isAuthorizedStaff = caller.medlifeRole === "staff"
    && caller.medlifeStaffActive === true
    && Array.isArray(caller.medlifePermissions)
    && caller.medlifePermissions.includes("notifications.manage");

  if (!isSuperAdmin && !isAuthorizedStaff) {
    return res.status(403).json({ error: "You are not allowed to send notifications." });
  }

  try {
    const snapshot = await admin.firestore().collection("users").get();
    const tokens = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      if (typeof data.fcmToken === "string" && data.fcmToken.trim()) {
        tokens.push(data.fcmToken.trim());
      }
    });

    if (tokens.length === 0) {
      return res.status(200).json({ sent: 0, message: "No tokens found." });
    }

    const result = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "MedLife",
        body: "You have a new notification from MedLife.",
      },
    });

    return res.status(200).json({
      sent: result.successCount,
      failed: result.failureCount,
    });
  } catch (error) {
    console.error("sendNotificationToAllUsers failed:", error);
    return res.status(500).json({ error: "Unable to send notifications." });
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
// Secure staff directory (Super Admin only)
// Uses Firebase Admin SDK so the dashboard does not need broad
// client-side permission to list every user document.
// ============================================================

exports.listMedLifeAccounts = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  if (request.auth.token.medlifeSuperAdmin !== true) {
    throw new HttpsError("permission-denied", "Only the Super Admin can view staff accounts.");
  }

  try {
    const accounts = [];
    let pageToken;
    do {
      const page = await admin.auth().listUsers(1000, pageToken);
      const profileRefs = page.users.map((user) =>
        admin.firestore().collection("users").doc(user.uid)
      );
      const profiles = profileRefs.length
        ? await admin.firestore().getAll(...profileRefs)
        : [];

      page.users.forEach((user, index) => {
        if (user.uid === MEDLIFE_SUPER_ADMIN_UID) return;
        const profile = profiles[index]?.data() || {};
        const claims = user.customClaims || {};
        accounts.push({
          uid: user.uid,
          email: user.email || "",
          displayName: user.displayName || "",
          phoneNumber: user.phoneNumber || "",
          disabled: user.disabled === true,
          role: claims.medlifeRole || profile.medlifeRole || profile.role || "user",
          active: claims.medlifeRole === "staff"
            ? claims.medlifeStaffActive === true
            : profile.medlifeStaffActive === true,
          permissions: Array.isArray(claims.medlifePermissions)
            ? claims.medlifePermissions
            : [],
          name: profile.name || profile.fullName || user.displayName || "",
          createdAt: profile.createdAt || null,
        });
      });
      pageToken = page.pageToken;
    } while (pageToken);

    return { accounts };
  } catch (error) {
    const diagnostic = {
      code: error?.code || "unknown",
      message: error?.message || String(error),
    };
    console.error("listMedLifeAccounts failed:", diagnostic, error?.stack || "");
    const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
    throw new HttpsError(
      "internal",
      isEmulator
        ? `Unable to load MedLife accounts (${diagnostic.code}): ${diagnostic.message}`
        : "Unable to load MedLife accounts.",
      isEmulator ? diagnostic : undefined,
    );
  }
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
      role: FieldValue.delete(),
      medlifeRole: "staff",
      medlifePermissions: assignedPermissions,
      medlifeStaffActive: active,
      staffPermissionsUpdatedAt: FieldValue.serverTimestamp(),
      staffPermissionsUpdatedBy: request.auth.uid,
    }, { merge: true });

    return { success: true, targetUid, active, permissions: assignedPermissions };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("setMedLifeStaffPermissions failed:", error);
    throw new HttpsError("internal", "Unable to update staff permissions.");
  }
});

