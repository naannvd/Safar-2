const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.initializeParentSubscriptions = functions.firestore
  .document('parents/{parentId}')
  .onCreate(async (snap, context) => {
    const parentId = context.params.parentId;

    const parentRef = admin.firestore().collection('parents').doc(parentId);
    const subscriptionsRef = parentRef.collection('subscriptions');

    await subscriptionsRef.doc('default').set({
      subscription_id: 'default',
      title: 'No Subscription',
      start_date: null,
      end_date: null,
    });

    return console.log(`Initialized subscriptions for parent: ${parentId}`);
  });
