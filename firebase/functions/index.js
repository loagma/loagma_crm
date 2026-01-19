const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.setUserRole = functions.https.onCall(async (data, context) => {
  // Only admin can assign roles
  if (!context.auth || context.auth.token.role !== "admin") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can set roles",
    );
  }

  const {uid, role} = data;

  if (!uid || !role) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "UID and role are required",
    );
  }

  await admin.auth().setCustomUserClaims(uid, {role});

  return {success: true};
});
