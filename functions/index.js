const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Initialize the Firebase Admin SDK
admin.initializeApp();

// Export initialized admin for use in other files
// exports.admin = admin;

// Import and export all functions from other files
// exports.claimLoyaltyReward = require('./src/claimLoyaltyReward').claimLoyaltyReward;
exports.subscribeToService = require('./src/subscribeToService').subscribeToService;
exports.initializeParentSubscriptions = require('./src/initializeParentSubscriptions').initializeParentSubscriptions;
// exports.myFunction = require('./src/messages').myFunction;
// exports.notifyParentsAndLog = require('./src/notifyParentsAndLog').notifyParentsAndLog;
// exports.onTicketCompleted = require('./src/onTicketCompleted').onTicketCompleted;
// exports.syncLoyaltyPointsAndProgress = require('./src/syncLoyaltyPointsAndProgress').syncLoyaltyPointsAndProgress;
// exports.initializeLoyaltyData = require('./src/initializeLoyaltyData').initializeLoyaltyData;
// exports.updateLoyaltyProgress = require('./src/updateLoyaltyPrograms').updateLoyaltyProgress;
