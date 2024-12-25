const functions = require('firebase-functions');
const admin = require('firebase-admin');
// admin.initializeApp();

exports.initializeLoyaltyData = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;

  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
  }

  const loyaltyProgramsSnapshot = await admin
    .firestore()
    .collection('loyalty_programs')
    .where('active', '==', true)
    .get();

  const userLoyaltyRef = admin.firestore().collection('users').doc(userId).collection('loyalty');
  const batch = admin.firestore().batch();

  loyaltyProgramsSnapshot.forEach((program) => {
    const programData = program.data();
    const rewardId = program.id;

    const userRewardRef = userLoyaltyRef.doc(rewardId);

    batch.set(
      userRewardRef,
      {
        rewardId,
        progress: {
          loyaltyPoints: 0,
          ticketsCompleted: 0,
        },
        claimed: false,
      },
      { merge: true }
    );
  });

  await batch.commit();
  return { message: 'Loyalty data initialized successfully.' };
});
