import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safar/private/bus_driver/ridestatus.dart';

class RideStart extends StatelessWidget {
  const RideStart({super.key});

  String generateRandomRideId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomString =
        List.generate(5, (_) => chars[random.nextInt(chars.length)])
            .join(); // Generates a 5-character random route ID
    return randomString;
  }

  Future<String> fetchDriverName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "Driver not logged in";
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return doc.data()?['driver_name'] ?? "No name found";
      } else {
        return "Driver not found";
      }
    } catch (e) {
      return "Error fetching driver name: $e";
    }
  }

  Future<String> createRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "Driver not logged in";
    }

    // Future<String> fetchDriverName() async {
    //   final user = FirebaseAuth.instance.currentUser;
    //   if (user == null) {
    //     return "Driver not logged in";
    //   }

    //   try {
    //     final doc = await FirebaseFirestore.instance
    //         .collection('drivers')
    //         .doc(user.uid)
    //         .get();
    //     if (doc.exists) {
    //       return doc.data()?['driver_name'] ?? "No name found";
    //     } else {
    //       return "Driver not found";
    //     }
    //   } catch (e) {
    //     return "Error fetching driver name:$e";
    //   }
    // }

    String driverId = user.uid;
    String rideId =
        "${generateRandomRideId().substring(0, 3)}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    String driverName = await fetchDriverName();

    try {
      await FirebaseFirestore.instance.collection('rides').add({
        'driver_id': driverId,
        'driver_name': driverName,
        'ride_id': rideId,
        'start_time': Timestamp.now(),
        'status': 'scheduled',
        'students': [],
        'champion_student': null
      });
    } catch (e) {
      return "Error starting ride: $e";
    }

    return rideId;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final rideId = await createRide();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideStatusScreen(
              rideId: rideId,
            ),
          ),
        );
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
          const Color(0xFF042F42), // Background color
        ),
        padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(vertical: 20), // Padding
        ),
      ),
      child: Text(
        "Create Ride",
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 22,
          letterSpacing: 1.5,
          color: Colors.white, // Text color
        ),
      ),
    );
  }
}
