import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:safar/private/bus_driver/driver_functionality/create_ride.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA1CA73),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA1CA73),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RideStart(),
            SizedBox(height: 20),
            // AttendanceQRScanner(),
            SizedBox(height: 20),
            // EmergencySOS(),
          ],
        ),
      ),
    );
  }
}
