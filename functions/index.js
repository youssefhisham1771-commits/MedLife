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