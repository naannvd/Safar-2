import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverNewDashboard extends StatelessWidget {
  const DriverNewDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF042F42),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRouteDetailsPanel(),
            const SizedBox(height: 20),
            // AttendanceQRScanner(),
            const SizedBox(height: 20),
            // EmergencySOS(),
          ],
        ),
      ),
    );
  }
}

Widget _buildRouteDetailsPanel() {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Details',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Meow',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.flag, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Meow Meow',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
            ),
          ],
        ),
        const Divider(thickness: 1.5),
        const SizedBox(height: 10),
      ],
    ),
  );
}
