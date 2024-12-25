const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.syncLoyaltyPointsAndProgress = functions.firestore
  .document("tickets/{ticketId}")
  .onUpdate((change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "completed" && after.status === "completed") {
      const userId = after.userId;
      const userLoyaltyRef = admin.firestore().collection("users").doc(userId).collection("loyalty");
      const programsRef = admin.firestore().collection("loyalty_programs").where("active", "==", true);

      return programsRef.get().then((programsSnapshot) => {
        const batch = admin.firestore().batch();

        programsSnapshot.forEach((programDoc) => {
          const program = programDoc.data();
          const rewardId = programDoc.id;

          batch.set(
            userLoyaltyRef.doc(rewardId),
            {
              rewardId,
              progress: {
                loyaltyPoints: admin.firestore.FieldValue.increment(30),
                ticketsCompleted: admin.firestore.FieldValue.increment(1),
              },
              claimed: false,
            },
            { merge: true }
          );
        });

        return batch.commit();
      });
    }

    return null;
  });
