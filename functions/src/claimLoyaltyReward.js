const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.claimLoyaltyReward = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const rewardId = data.rewardId;

  if (!userId) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
  }

  if (!rewardId) {
    throw new functions.https.HttpsError('invalid-argument', 'Reward ID is required.');
  }

  const rewardDoc = await admin.firestore().collection('loyalty_programs').doc(rewardId).get();
  if (!rewardDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Reward not found.');
  }

  const rewardData = rewardDoc.data();
  const requiredTickets = rewardData.criteria?.ticketsCompleted || 0;
  const requiredPoints = rewardData.criteria?.loyaltyPointsRequired || 0;

  const userRewardRef = admin.firestore().collection('users').doc(userId).collection('loyalty').doc(rewardId);
  const userRewardDoc = await userRewardRef.get();

  if (!userRewardDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'User progress not found for this reward.');
  }

  const userProgress = userRewardDoc.data()?.progress || {};
  const ticketsCompleted = userProgress.ticketsCompleted || 0;
  const loyaltyPoints = userProgress.loyaltyPoints || 0;

  if (ticketsCompleted < requiredTickets || loyaltyPoints < requiredPoints) {
    throw new functions.https.HttpsError('failed-precondition', 'User does not meet reward criteria.');
  }

  if (userRewardDoc.data()?.claimed) {
    throw new functions.https.HttpsError('already-exists', 'Reward has already been claimed.');
  }

  // Mark reward as claimed
  await userRewardRef.update({
    claimed: true,
    claimDate: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update user's discount percentage if applicable
  const discountPercentage = rewardData.discountPercentage || 0;
  if (discountPercentage > 0) {
    await admin.firestore().collection('users').doc(userId).update({
      nextTicketDiscount: discountPercentage,
    });
  }

  return {
    message: 'Reward claimed successfully.',
    discountPercentage: discountPercentage,
  };
});
