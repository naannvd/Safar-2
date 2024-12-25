import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickalert/quickalert.dart';
import 'package:safar/private/parent/subscription_manage.dart';
import 'package:safar/private/private_bottom_nav_bar.dart';

class ParentNewDashboard extends StatelessWidget {
  const ParentNewDashboard({super.key});

  Future<String> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('parents')
        .doc(user!.uid)
        .get();
    return userData['parent_name'];
  }

  Future<void> viewSubscriptionDetails(BuildContext context) async {
    try {
      final parentId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the subscription from the parent's sub-collection
      final subscriptionSnapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('subscriptions')
          .limit(1)
          .get();

      if (subscriptionSnapshot.docs.isEmpty) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.info,
          title: 'No Subscription Found',
          text: 'You are not subscribed to any service.',
        );
        return;
      }

      final subscriptionId =
          subscriptionSnapshot.docs.first.data()['subscription_id'];

      // Fetch the subscription details from the subscriptions collection
      final subscriptionDoc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();

      if (!subscriptionDoc.exists) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Subscription details not found.',
        );
        return;
      }

      final subscriptionData = subscriptionDoc.data();
      final title = subscriptionData!['title'];
      final description = subscriptionData['description'];

      // Show subscription details in QuickAlert
      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        title: 'Current Subscription',
        text: '$title\n$description',
        confirmBtnColor: const Color(0xFFFFC847),
      );
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to fetch subscription details. Please try again later.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: getUserName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('An error occurred'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('No data found'),
                  );
                }
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      Padding(
                        padding: const EdgeInsets.only(left: 55.0, right: 20),
                        child: Row(
                          children: [
                            Text(
                              "Welcome, Mr ${snapshot.data}",
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 50),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFA1CA73),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF94C83D),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Subscription Management',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 15),
              child: Container(
                margin: const EdgeInsets.only(left: 7, bottom: 3),
                child: Text(
                  'Van Services',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF042F42),
                  ),
                ),
              ),
            ),
            const SingleChildScrollView(
              child: SubscriptionManagement(),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () => viewSubscriptionDetails(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF94C83D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                  child: Text(
                    'View Subscription',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
      bottomNavigationBar: const PrivateNavBar(currentTab: 'Home'),
    );
  }
}
