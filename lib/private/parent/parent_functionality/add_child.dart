import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddChildDashboard extends StatefulWidget {
  const AddChildDashboard({super.key});

  @override
  State<AddChildDashboard> createState() => _AddChildDashboardState();
}

class _AddChildDashboardState extends State<AddChildDashboard> {
  final _formSignupKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signUpUser() async {
    if (_formSignupKey.currentState!.validate()) {
      try {
        // Get current parent credentials
        final parentUser = FirebaseAuth.instance.currentUser!;
        final parentEmail = parentUser.email;
        final parentUid = parentUser.uid;
        final parentPassword =
            await promptParentForPassword(); // Prompt for password

        if (parentPassword == null || parentEmail == null) {
          throw Exception("Parent credentials are missing.");
        }

        // Ensure current user is signed out before creating a new user
        await FirebaseAuth.instance.signOut();

        // Create child user with Firebase Authentication
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Get the UID of the newly created child user
        String childUid = userCredential.user!.uid;

        // Log out the child user and reauthenticate the parent
        await FirebaseAuth.instance.signOut();

        try {
          // Re-authenticate the parent user
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: parentEmail,
            password: parentPassword,
          );
        } on FirebaseAuthException {
          await FirebaseAuth.instance.currentUser?.delete();
          throw Exception(
              "Parent re-authentication failed. Child account deleted.");
        }

        // Store child details in Firestore
        await FirebaseFirestore.instance
            .collection('childs')
            .doc(childUid)
            .set({
          'child_name': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(),
          'role': 'Child',
          'is_boarded': false,
          'is_champion': false,
          'is_present': false,
          'parent_id': parentUid,
          'child_id': childUid,
        });

        // Update parent collection with child ID
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(parentUid)
            .update({
          'children': FieldValue.arrayUnion([childUid]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child account created successfully!')),
        );

        // Clear fields after successful signup
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The password provided is too weak.')),
          );
        } else if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('The account already exists for that email.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> promptParentForPassword() async {
    String? password;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController passwordController =
            TextEditingController();
        return AlertDialog(
          title: Text(
            "Re-authentication Required",
            style: GoogleFonts.montserrat(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Please enter your password to continue.",
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                password = null;
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: GoogleFonts.montserrat(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                password = passwordController.text.trim();
                Navigator.of(context).pop();
              },
              child: Text(
                "Submit",
                style: GoogleFonts.montserrat(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
    return password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA1CA73),
      appBar: AppBar(
        // title: Text(
        //   "Add Child Dashboard",
        //   style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        // ),
        backgroundColor: const Color(0xFFA1CA73),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 150),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formSignupKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add Child Details",
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _usernameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter username';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Center(
                        child: ElevatedButton(
                          onPressed: _signUpUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA1CA73),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Text(
                            'Add Child',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF042F42),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
