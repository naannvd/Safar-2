import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safar/Profile/SupportChat/chat.dart';
import 'package:safar/private/parent/parent_functionality/mark_child_attendance.dart';
import 'package:tap_to_expand/tap_to_expand.dart';

class DailyTrip extends StatefulWidget {
  const DailyTrip({super.key});

  @override
  State<DailyTrip> createState() => _DailyTripState();
}

class _DailyTripState extends State<DailyTrip> {
  Future<List<Map<String, dynamic>>> _fetchChildren(String parentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('childs')
          .where('parent_id', isEqualTo: parentId)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching children: $e');
      return [];
    }
  }

  Future<String?> _fetchParentSubscription(String parentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('parents')
          .doc(parentId)
          .collection('subscriptions')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print(snapshot.docs.first.data()['subscription_id']);
        return snapshot.docs.first.data()['subscription_id'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching parent subscription: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchRides(String subscriptionId) async* {
    try {
      final driverSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('assigned_route', isEqualTo: subscriptionId)
          .limit(1)
          .get();

      if (driverSnapshot.docs.isNotEmpty) {
        final driverId = driverSnapshot.docs.first.id;
        debugPrint('driverId: $driverId');

        yield* FirebaseFirestore.instance
            .collection('rides')
            .where('status', isEqualTo: 'scheduled')
            .where('driver_id', isEqualTo: driverId)
            .orderBy('start_time', descending: true)
            .limit(1)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList());
      } else {
        debugPrint('No driver found for subscriptionId: $subscriptionId');
        yield [];
      }
    } catch (e) {
      debugPrint('Error fetching rides: $e');
      yield [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentId = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<String?>(
      future: _fetchParentSubscription(parentId),
      builder: (context, subscriptionSnapshot) {
        if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subscriptionId = subscriptionSnapshot.data;

        if (subscriptionId == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Text(
                'No active subscription found. Please subscribe to a service.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _fetchRides(subscriptionId),
          builder: (context, rideSnapshot) {
            if (rideSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (rideSnapshot.hasError) {
              debugPrint('Error in fetching rides: ${rideSnapshot.error}');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'An error occurred while fetching scheduled rides.',
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final rides = rideSnapshot.data ?? [];

            if (rides.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No scheduled rides available for the current subscription.',
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(10.0),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final rideData = rides[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TapToExpand(
                          backgroundcolor: const Color(0xFFA1CA73),
                          content: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _fetchChildren(parentId),
                            builder: (context, childSnapshot) {
                              if (childSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (childSnapshot.hasError) {
                                debugPrint(
                                    'Error fetching children: ${childSnapshot.error}');
                                return Center(
                                  child: Text(
                                    'An error occurred while fetching children.',
                                    style: GoogleFonts.montserrat(fontSize: 14),
                                  ),
                                );
                              }

                              final children = childSnapshot.data ?? [];
                              if (children.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'No children found for this parent.',
                                      style:
                                          GoogleFonts.montserrat(fontSize: 14),
                                    ),
                                  ),
                                );
                              }

                              return MarkChildAttendance(
                                children: children,
                                rideData: rideData,
                              );
                            },
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bus Ride ID: ${rideData['ride_id']}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Divider(thickness: 1, color: Colors.grey),
                              const SizedBox(height: 5),
                              Text(
                                'Driver: ${rideData['driver_name']}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (rides.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFFA1CA73),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.chat, color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
