import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safar/Profile/Feedback/feedback.dart';
import 'package:safar/Profile/Loyalty/loyalty.dart';
import 'package:safar/Profile/Saved%20Routes/prev_routes.dart';
import 'package:safar/Profile/profile_edit.dart';
import 'package:safar/Profile/test.dart';
import 'package:safar/Screens/welcome_screen.dart';
import 'package:safar/Widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<String> fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    // try {
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return userData['fullName'];
    // } catch (e) {}
  }

  Future<String> fetchEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return userData['email'];
  }

  Future<String> fetchImage() async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    return userData['image_url'];
  }

  Future<void> _navigateToLoginScreen() async {
    FirebaseAuth.instance.signOut();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );

    if (result == true) {
      // User saved changes, refresh the profile screen
      setState(() {});
    }
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder(
          future: fetchUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    FutureBuilder<String?>(
                      future: fetchImage(),
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey,
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (imageSnapshot.hasError ||
                            !imageSnapshot.hasData ||
                            imageSnapshot.data == null ||
                            imageSnapshot.data!.isEmpty) {
                          // If no image or an error, show default image
                          return const CircleAvatar(
                            radius: 60,
                            backgroundImage:
                                AssetImage('assets/images/profile.png'),
                          );
                        } else {
                          // Show the fetched image URL from Firebase Storage
                          return CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(imageSnapshot.data!),
                          );
                        }
                      },
                    ),
                    // const CircleAvatar(
                    //   radius: 60,
                    //   backgroundImage: AssetImage('assets/images/profile.png'),
                    // ),
                    const SizedBox(height: 20),
                    Text(
                      '${snapshot.data}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 9,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FutureBuilder(
                        future: fetchEmail(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Text(
                            '${snapshot.data}',
                            style: GoogleFonts.montserrat(
                                fontSize: 15,
                                color: const Color(0xFF042F40),
                                fontWeight: FontWeight.w500),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _buildProfileOption(
                            Icons.edit,
                            'Edit Profile',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileEdit(),
                                ),
                              );
                            },
                            const Color(0xFF042F40),
                          ),
                          _buildProfileOption(
                            Icons.reviews_sharp,
                            'Loyalty',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoyaltyDashboard(),
                                ),
                              );
                            },
                            const Color(0xFF042F40),
                          ),
                          _buildProfileOption(
                            Icons.feedback,
                            'Feedback',
                            () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const FeedbackScreen()));
                            },
                            const Color(0xFF042F40),
                          ),
                          // _buildProfileOption(
                          //   Icons.baby_changing_station,
                          //   'Test',
                          //   () {
                          //     Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //             builder: (context) => const MapScreen()));
                          //   },
                          //   const Color(0xFF042F40),
                          // ),
                          _buildProfileOption(
                            Icons.route,
                            'Saved Routes',
                            () {
                              _checkPermissions();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const PrevRoutes()));
                            },
                            const Color(0xFF042F40),
                          ),
                          _buildProfileOption(Icons.logout, 'Logout',
                              _navigateToLoginScreen, Colors.red),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }),
      bottomNavigationBar: const RoundedNavBar(currentTab: 'Profile'),
    );
  }

  Widget _buildProfileOption(
      IconData icon, String title, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFA1CA73),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: GoogleFonts.montserrat(
                color: color, fontWeight: FontWeight.w500, fontSize: 16),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 15,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
