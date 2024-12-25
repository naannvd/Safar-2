const functions = require('firebase-functions');
const admin = require('firebase-admin');
// admin.initializeApp();
exports.updateLoyaltyProgress = functions.firestore
  .document('tickets/{ticketId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === 'completed' || after.status !== 'completed') {
      return null; // Only proceed if the ticket status transitions to "completed"
    }

    const userId = after.userId;
    const loyaltyProgramsSnapshot = await admin
      .firestore()
      .collection('loyalty_programs')
      .where('active', '==', true)
      .get();

    const userLoyaltyRef = admin.firestore().collection('users').doc(userId).collection('loyalty');
    const batch = admin.firestore().batch();

    loyaltyProgramsSnapshot.forEach((program) => {
      const rewardId = program.id;
      const userRewardRef = userLoyaltyRef.doc(rewardId);

      batch.set(
        userRewardRef,
        {
          progress: {
            loyaltyPoints: admin.firestore.FieldValue.increment(30),
            ticketsCompleted: admin.firestore.FieldValue.increment(1),
          },
        },
        { merge: true }
      );
    });

    await batch.commit();
    return null;
  });
