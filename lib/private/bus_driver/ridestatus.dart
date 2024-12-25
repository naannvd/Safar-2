import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safar/Profile/QrScanner/scanner_with_window.dart';
import 'package:safar/private/bus_driver/driver_functionality/driver_chat/driver_chat_screen.dart';
import 'package:safar/private/bus_driver/driver_functionality/finish_ride.dart';
import 'package:safar/private/bus_driver/driver_functionality/mark_attendance.dart';
import 'package:safar/private/bus_driver/driver_functionality/present_students.dart';
import 'package:safar/private/bus_driver/full_map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideStatusScreen extends StatefulWidget {
  final String rideId;

  const RideStatusScreen({super.key, required this.rideId});

  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  Widget _buildRouteDetailsPanel() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverChat(),
                ),
              );
            },
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text(
              'Chat with Parents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF042F42),
              shadowColor: Colors.grey.shade300,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Divider(thickness: 1.5),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarcodeScannerWithScanWindow(),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text(
              'Scan Attendance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.grey.shade300,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Divider(thickness: 1.5),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                // Fetch the ride document by matching the ride_id
                final QuerySnapshot<Map<String, dynamic>> querySnapshot =
                    await FirebaseFirestore.instance
                        .collection('rides')
                        .where('ride_id', isEqualTo: widget.rideId)
                        .limit(1)
                        .get();

                if (querySnapshot.docs.isNotEmpty) {
                  final DocumentSnapshot<Map<String, dynamic>> rideDoc =
                      querySnapshot.docs.first;

                  // Update the ride status to 'completed'
                  await rideDoc.reference.update({'status': 'completed'});

                  // Reset attributes for all children associated with the ride
                  final List<dynamic> studentIds =
                      rideDoc.data()?['students'] ?? [];
                  for (String studentId in studentIds) {
                    await FirebaseFirestore.instance
                        .collection('childs')
                        .doc(studentId)
                        .update({
                      'is_boarded': false,
                      'is_champion': false,
                      'is_present': false,
                    });
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ride finished successfully!')),
                  );

                  // Navigate back to the driver's dashboard
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Ride not found.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error finishing ride: $e')),
                );
              }
            },
            icon: const Icon(Icons.flag, color: Colors.white),
            label: const Text(
              'Finish Ride',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF042F42),
              shadowColor: Colors.grey.shade300,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSOS(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final emergencyId =
          FirebaseFirestore.instance.collection('emergency').doc().id;

      // Save emergency details in Firestore
      await FirebaseFirestore.instance
          .collection('emergency')
          .doc(emergencyId)
          .set({
        'driver_id': user.uid,
        'ride_id': widget.rideId,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Emergency triggered!',
      });

      // // Retrieve all parent FCM tokens from Firestore
      // final parentDocs =
      //     await FirebaseFirestore.instance.collection('parents').get();

      // for (var parentDoc in parentDocs.docs) {
      //   final fcmToken = parentDoc.data()['fcm_token'];

      //   if (fcmToken != null) {
      //     // Send notification to each parent
      //     await sendNotification(
      //       fcmToken: fcmToken,
      //       title: 'Emergency Alert',
      //       body: 'An SOS has been triggered for Ride ID: ${widget.rideId}.',
      //     );
      //   }
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('SOS triggered! Parents have been notified.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error triggering SOS: $e')),
      );
    }
  }

  // Future<void> sendNotification({
  //   required String fcmToken,
  //   required String title,
  //   required String body,
  // }) async {
  //   try {
  //     // Notification payload
  //     final notificationPayload = {
  //       "to": fcmToken,
  //       "notification": {
  //         "title": title,
  //         "body": body,
  //         "sound": "default",
  //       },
  //       "data": {
  //         "click_action": "FLUTTER_NOTIFICATION_CLICK",
  //         "ride_id": "12345", // Example data payload
  //       },
  //     };

  //     // Firebase server key (replace with your actual server key)
  //     const String serverKey = "YOUR_SERVER_KEY";

  //     // Send the POST request
  //     final response = await http.post(
  //       Uri.parse("https://fcm.googleapis.com/fcm/send"),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": "key=$serverKey",
  //       },
  //       body: jsonEncode(notificationPayload),
  //     );

  //     // Handle the response
  //     if (response.statusCode == 200) {
  //       print("Notification sent successfully!");
  //     } else {
  //       print("Failed to send notification: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Error sending notification: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Ride Status Header
                Text(
                  "Ride ID: ${widget.rideId}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // "View Full Map" Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullMapScreen(rideId: widget.rideId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF042F42),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Full Map',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Present Students List
                Expanded(
                  child: PresentStudents(
                    rideId: widget.rideId,
                  ),
                ),

                // Sliding Up Panel
                SlidingUpPanel(
                  color: const Color(0xFFA1C173),
                  minHeight: 100,
                  maxHeight: 300,
                  panel: _buildRouteDetailsPanel(),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ],
            ),
          ),

          // SOS Button
          Positioned(
            top: 13,
            right: 13,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.red,
              icon: const Icon(
                Icons.warning,
                color: Colors.white,
                size: 12,
              ),
              label: Text(
                'SOS',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              onPressed: () => _triggerSOS(context),
            ),
          ),
        ],
      ),
    );
  }
}
