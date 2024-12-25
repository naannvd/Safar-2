import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:safar/private/child/attendance_QR.dart';
import 'package:safar/private/child/sos_button.dart';

class ChildDashboard extends StatelessWidget {
  const ChildDashboard({super.key});

  Future<String> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      final userData = await FirebaseFirestore.instance
          .collection('childs')
          .doc(user!.uid)
          .get();
      final fullName = userData['child_name'];
      return fullName;
    } catch (e) {
      return 'User not found';
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = FirebaseAuth.instance.currentUser;

    return FutureBuilder<String>(
      future: getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error fetching data'),
          );
        } else {
          return Scaffold(
            body: Stack(
              children: [
                // Background Gradient
                Container(
                  decoration: const BoxDecoration(
                      // gradient: LinearGradient(
                      //   begin: Alignment.topCenter,
                      //   end: Alignment.bottomCenter,
                      //   colors: [
                      //     Color(0xFF042F42),
                      //     Color(0xFFA1CA73),
                      //   ],
                      // ),
                      color: Color(0xFFA1CA73)),
                ),

                // Main Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 250,
                        ),
                        // Header
                        GlassmorphicContainer(
                          width: double.infinity,
                          height: 120,
                          borderRadius: 15,
                          blur: 15,
                          alignment: Alignment.center,
                          border: 2,
                          linearGradient: LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.2),
                              Colors.black.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderGradient: LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.5),
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome, ${snapshot.data}',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF042F42),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Your Dashboard',
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF042F42),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Options
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              // Attendance Card
                              _buildOptionCard(
                                context,
                                icon: Icons.qr_code_scanner,
                                title: 'Scan Attendance',
                                description: 'Mark your attendance quickly',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ChildQRCodeWidget(),
                                    ),
                                  );
                                },
                              ),
                              _buildOptionCard(
                                context,
                                icon: Icons.exit_to_app,
                                title: 'Logout',
                                description: 'Log out of the child account',
                                onTap: () {
                                  FirebaseAuth.instance.signOut();
                                  Navigator.pop(context);
                                },
                              ),

                              const SizedBox(height: 10),
                            ],
                          ),
                        ),

                        // SOS Button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: SOSButton(studentId: student!.uid),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: double.infinity,
        height: 100,
        borderRadius: 15,
        blur: 15,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.2),
            Colors.black.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.grey.withOpacity(0.5),
            Colors.black.withOpacity(0.2),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF042F42),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
