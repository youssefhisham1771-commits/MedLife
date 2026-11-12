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

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");

// Executes enabled admin notification rules for new orders.
exports.runOrderCreatedAutomations = onDocumentCreated("orders/{orderId}", async (event) => {
  const order = event.data?.data();
  if (!order) return;
  const rules = await admin.firestore().collection("automationRules")
    .where("enabled", "==", true)
    .where("trigger", "==", "order_created").get();
  if (rules.empty) return;
  await admin.firestore().collection("notifications").add({
    title: "New MedLife order",
    body: "A new order " + event.params.orderId + " has been placed.",
    type: "admin_automation",
    orderId: event.params.orderId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});

// Executes enabled admin notification rules when an order status changes.
exports.runOrderStatusAutomations = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;
  const rules = await admin.firestore().collection("automationRules")
    .where("enabled", "==", true)
    .where("trigger", "==", "order_status_changed").get();
  if (rules.empty) return;
  await admin.firestore().collection("notifications").add({
    title: "Order status updated",
    body: "Order " + event.params.orderId + " changed from " + before.status + " to " + after.status + ".",
    type: "admin_automation",
    orderId: event.params.orderId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
