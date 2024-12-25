import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:safar/Payment/pages/home_page.dart';
import 'package:safar/private/parent/subscription_builder.dart';
import 'package:safar/private/parent/subscription_card.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  Stream<List<Map<String, dynamic>>> _streamSubscriptions() {
    return FirebaseFirestore.instance
        .collection('subscriptions')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return {
          'subscription_id': doc['subscription_id'],
          'title': doc['title'],
          'description': doc['description'],
          'price': doc['price'],
        };
      }).toList();
    });
  }

  Future<bool> hasActiveSubscription(String parentId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('subscriptions')
          .get();

      // Check if there is any active subscription
      return querySnapshot.docs.any((doc) {
        final data = doc.data();
        final endDate = (data['end_date'] as Timestamp).toDate();
        return DateTime.now().isBefore(endDate); // Active if end_date > now
      });
    } catch (e) {
      print('Error checking active subscription: $e');
      return false;
    }
  }

  Future<void> subscribeToService(
      String parentId, String subscriptionId) async {
    try {
      // Fetch the subscription details
      final subscriptionDoc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!subscriptionDoc.exists) {
        throw Exception('Subscription not found.');
      }

      final subscriptionData = subscriptionDoc.data()!;
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 30)); // 1 month later

      // Add the subscription to the parent's sub-collection
      await FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('subscriptions')
          .doc(subscriptionId)
          .set({
        ...subscriptionData,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
      });

      print('Subscribed to service successfully!');
    } catch (e) {
      print('Error subscribing to service: $e');
      throw Exception('Failed to subscribe to service.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1000, // Set fixed height
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final subscriptions = snapshot.data!;

          return ListView.builder(
            shrinkWrap: true, // Avoid layout overflow
            physics:
                const NeverScrollableScrollPhysics(), // Prevent nested scrolling
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index];

              return SubscriptionCard(
                title: subscription['title'],
                price: subscription['price'],
                onSubscribe: () async {
                  final parentId = FirebaseAuth.instance.currentUser!.uid;

                  // Check if the parent has any active subscription
                  final alreadySubscribed =
                      await hasActiveSubscription(parentId);

                  if (alreadySubscribed) {
                    // Show alert if already subscribed
                    await QuickAlert.show(
                      context: context,
                      type: QuickAlertType.info,
                      text: 'You are already subscribed to a service!',
                    );
                  } else {
                    // Proceed with payment
                    final paymentSuccessful =
                        await PaymentHelper.openStripePaymentView(
                            context, subscription['price']);

                    if (paymentSuccessful) {
                      // Add subscription to the parent's sub-collection
                      await subscribeToService(
                          parentId, subscription['subscription_id']);

                      // Show success alert
                      await QuickAlert.show(
                        context: context,
                        type: QuickAlertType.success,
                        text: 'Subscription successful!',
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
