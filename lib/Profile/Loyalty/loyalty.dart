import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickalert/quickalert.dart';

class LoyaltyDashboard extends StatefulWidget {
  const LoyaltyDashboard({super.key});

  @override
  State<LoyaltyDashboard> createState() => _LoyaltyDashboardState();
}

class _LoyaltyDashboardState extends State<LoyaltyDashboard> {
  final user = FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> _fetchLoyaltyPrograms() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('loyalty_programs')
          .where('active', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'rewardId': data['reward_id'],
          'title': data['title'],
          'description': data['description'],
          'criteria': data['criteria'],
          'rewardType': data['rewardType'],
          'discountPercentage': data['discountPercentage'],
          'oneTimeUse': data['oneTimeUse']
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching loyalty programs: $e');
      throw Exception('Failed to fetch loyalty programs.');
    }
  }

  Stream<Map<String, dynamic>> _fetchUserProgress(String rewardId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('loyalty')
        .doc(rewardId)
        .snapshots()
        .map((doc) {
      if (doc.exists && !(doc.data()?['claimed'] ?? false)) {
        // Explicitly cast doc.data() to Map<String, dynamic>
        return Map<String, dynamic>.from(doc.data()!);
      }
      return <String, dynamic>{}; // Return an empty Map<String, dynamic>
    }).handleError((e) {
      debugPrint('Error fetching user progress for $rewardId: $e');
    });
  }

  Future<void> _claimReward(String rewardId) async {
    try {
      // Call the Firebase function
      final callable =
          FirebaseFunctions.instance.httpsCallable('claimLoyaltyReward');
      final result = await callable({'rewardId': rewardId});

      // Extract the discount percentage from the response
      final discountPercentage = result.data['discountPercentage'] ?? 0;
      debugPrint('Discount applied: $discountPercentage%');

      // Show success alert
      await QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: discountPercentage > 0
            ? 'Reward claimed successfully! ${discountPercentage}% discount applied to your next ticket!'
            : 'Reward claimed successfully!',
      );

      // Update user's discount locally (optional, as the backend already updates it)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'nextTicketDiscount': discountPercentage});

      // Remove the reward from the user's loyalty sub-collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('loyalty')
          .doc(rewardId)
          .delete();

      // Refresh the UI after successfully claiming the reward
      setState(() {});
    } catch (e) {
      debugPrint('Error claiming reward: $e');

      // Handle specific error cases if possible
      if (e is FirebaseFunctionsException) {
        String errorMessage = 'Error claiming reward: ${e.message}';
        switch (e.code) {
          case 'unauthenticated':
            errorMessage = 'You must be logged in to claim a reward.';
            break;
          case 'not-found':
            errorMessage = 'Reward not found or already claimed.';
            break;
          case 'failed-precondition':
            errorMessage = 'You do not meet the criteria to claim this reward.';
            break;
          default:
            errorMessage = e.message ?? 'An unexpected error occurred.';
        }

        // Show appropriate error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else {
        // Generic error handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA1CA73),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA1CA73),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLoyaltyPrograms(),
        builder: (context, programsSnapshot) {
          if (programsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (programsSnapshot.hasError) {
            debugPrint('Error in FutureBuilder: ${programsSnapshot.error}');
            return Center(child: Text('Error: ${programsSnapshot.error}'));
          }

          final programs = programsSnapshot.data!;

          return ListView.builder(
            itemCount: programs.length,
            itemBuilder: (context, index) {
              final program = programs[index];
              final rewardId = program['rewardId'];
              final title = program['title'];
              final description = program['description'];
              final criteria = program['criteria'];

              return StreamBuilder<Map<String, dynamic>>(
                stream: _fetchUserProgress(rewardId),
                builder: (context, progressSnapshot) {
                  if (progressSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (progressSnapshot.hasError) {
                    debugPrint(
                        'Error in StreamBuilder for $rewardId: ${progressSnapshot.error}');
                    return Text('Error loading progress.');
                  }

                  final progressData = progressSnapshot.data!;
                  if (progressData.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final progress = progressData['progress'] ?? {};
                  final ticketsCompleted = (progress['ticketsCompleted'] is num)
                      ? (progress['ticketsCompleted'] as num).toDouble()
                      : 0.0;
                  final loyaltyPoints = (progress['loyaltyPoints'] is num)
                      ? (progress['loyaltyPoints'] as num).toDouble()
                      : 0.0;
                  final claimed = progressData['claimed'] ?? false;

                  final requiredTickets =
                      (criteria.containsKey('ticketsCompleted') &&
                              criteria['ticketsCompleted'] is num)
                          ? (criteria['ticketsCompleted'] as num).toDouble()
                          : 0.0; // Fallback to 0 if not available

                  print('Criteria Data: $criteria');
                  print('Criteria Data: ${criteria['ticketsCompleted']}');

                  final requiredPoints = (criteria['loyaltyPointsRequired']
                          is num)
                      ? (criteria['loyaltyPointsRequired'] as num).toDouble()
                      : 0.0;

                  final ticketsProgress =
                      (ticketsCompleted / requiredTickets).clamp(0.0, 1.0);
                  final pointsProgress =
                      (loyaltyPoints / requiredPoints).clamp(0.0, 1.0);

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                          Text(description,
                              style: GoogleFonts.montserrat(fontSize: 14)),
                          const SizedBox(height: 10),
                          Text('Progress:',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600)),

                          // Show Tickets Progress Only if Required
                          if (requiredTickets > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: ticketsProgress.isNaN
                                      ? 0.0
                                      : ticketsProgress,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Tickets: ${ticketsCompleted.toInt()}/${requiredTickets.toInt()}',
                                  style: GoogleFonts.montserrat(fontSize: 12),
                                ),
                              ],
                            ),

                          // Show Points Progress Only if Required
                          if (requiredPoints > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: pointsProgress.isNaN
                                      ? 0.0
                                      : pointsProgress,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Points: ${loyaltyPoints.toInt()}/${requiredPoints.toInt()}',
                                  style: GoogleFonts.montserrat(fontSize: 12),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: claimed
                                    ? null
                                    : (ticketsCompleted >= requiredTickets &&
                                            loyaltyPoints >= requiredPoints)
                                        ? () => _claimReward(rewardId)
                                        : null,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        claimed ? Colors.grey : Colors.blue),
                                child:
                                    Text(claimed ? 'Claimed' : 'Claim Reward'),
                              ),
                              Text(
                                  claimed
                                      ? 'Reward Claimed'
                                      : 'Eligible for Claim',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: claimed
                                          ? Colors.grey
                                          : Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
