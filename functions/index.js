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
