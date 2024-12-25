import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safar/Screens/welcome_screen.dart';
import 'package:safar/private/parent/parent_feedback.dart';
import 'package:safar/private/parent/parent_functionality/add_child.dart';
import 'package:safar/private/parent/parent_functionality/child_list.dart';
import 'package:safar/private/parent/parent_functionality/set_location.dart';
import 'package:safar/private/private_bottom_nav_bar.dart';
// import 'package:tap_to_expand/tap_to_expand.dart';

class ParentProfile extends StatefulWidget {
  const ParentProfile({super.key});

  @override
  State<ParentProfile> createState() => _ParentProfileState();
}

class _ParentProfileState extends State<ParentProfile> {
  Future<String> fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    // try {
    final userData = await FirebaseFirestore.instance
        .collection('parents')
        .doc(user!.uid)
        .get();
    return userData['parent_name'];
    // } catch (e) {}
  }

  Future<String> fetchEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('parents')
        .doc(user!.uid)
        .get();
    return userData['email'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 180),
              FutureBuilder(
                future: fetchUsername(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return Text(
                    '${snapshot.data}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(
                height: 9,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FutureBuilder(
                  future: fetchEmail(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                      Icons.child_care_outlined,
                      'Add Child',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddChildDashboard(),
                          ),
                        );
                      },
                      const Color(0xFF042F40),
                    ),
                    _buildProfileOption(
                      Icons.map_outlined,
                      'Set Address',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetLocationScreen(
                                parentId:
                                    FirebaseAuth.instance.currentUser!.uid),
                          ),
                        );
                      },
                      const Color(0xFF042F40),
                    ),
                    _buildProfileOption(
                      Icons.feedback_outlined,
                      'Submit Feedback',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ParentFeedback(),
                          ),
                        );
                      },
                      const Color(0xFF042F40),
                    ),
                    // ChildrenList(
                    //     parentId: FirebaseAuth.instance.currentUser!.uid),
                    _buildProfileOption(Icons.logout, 'Logout',
                        _navigateToLoginScreen, Colors.red),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PrivateNavBar(currentTab: 'Profile'),
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
