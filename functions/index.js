/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendFrontingAlterNotification = functions.database
    .ref("/current_fronting")
    .onUpdate((change, context) => {
    // Get the current fronting alter data
      const frontingAlter = change.after.val();

      // Notification details
      const payload = {
        notification: {
          title: "New Fronting Alter",
          body: `${frontingAlter.name} is now fronting!`,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      return admin
          .messaging()
          .sendToTopic("fronting_changes", payload)
          .then((response) => {
            console.log("Notification sent successfully:", response);
            return null;
          })
          .catch((error) => {
            console.error("Error sending notification:", error);
          });
    });
