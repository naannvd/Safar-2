const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.subscribeToService = functions.https.onCall(async (data, context) => {
    const { parentId, subscriptionId } = data;
  
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be logged in.'
      );
    }
  
    if (!parentId || !subscriptionId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Parent ID and Subscription ID are required.'
      );
    }
  
    const subscriptionDoc = await admin
      .firestore()
      .collection('subscriptions')
      .doc(subscriptionId)
      .get();
  
    if (!subscriptionDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Subscription not found.');
    }
  
    const subscriptionData = subscriptionDoc.data();
    const startDate = admin.firestore.FieldValue.serverTimestamp();
    const endDate = admin.firestore.Timestamp.fromDate(
      new Date(new Date().setMonth(new Date().getMonth() + 1))
    );
  
    await admin
      .firestore()
      .collection('parents')
      .doc(parentId)
      .collection('subscriptions')
      .doc(subscriptionId)
      .set({
        ...subscriptionData,
        start_date: startDate,
        end_date: endDate,
      });
  
    return { message: 'Subscribed successfully!' };
  });
  