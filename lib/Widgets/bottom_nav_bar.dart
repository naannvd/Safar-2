import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safar/Dashboard/landing_page.dart';
import 'package:safar/Profile/profile.dart';
import 'package:safar/Tickets/ticket.dart';
import 'package:safar/Tickets/ticket_book.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoundedNavBar extends StatefulWidget {
  final String currentTab;

  const RoundedNavBar({super.key, required this.currentTab});

  @override
  State<RoundedNavBar> createState() => _RoundedNavBarState();
}

class _RoundedNavBarState extends State<RoundedNavBar> {
  late String activeTab;
  bool hasActiveTicket = false;

  @override
  void initState() {
    super.initState();
    activeTab = widget.currentTab;
    _checkActiveTicket();
  }

  Future<void> _checkActiveTicket() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            hasActiveTicket = true;
          });
        }
      }
    } catch (e) {
      print('Error checking active ticket: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> navItems = [
      {
        'name': 'Home',
        'icon': FontAwesomeIcons.house,
        'screen': const LandingPage(),
      },
      {
        'name': 'Ticket',
        'icon': FontAwesomeIcons.ticket,
        'screen': hasActiveTicket ? const TicketCard() : const TicketBook(),
      },
      {
        'name': 'Profile',
        'icon': FontAwesomeIcons.user,
        'screen': const ProfileScreen()
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF042F40), // Dark blue background
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(
          bottom: 20, left: 20, right: 20), // Adjust for symmetry
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.map((item) {
          bool isActive = activeTab == item['name'];
          return GestureDetector(
            onTap: () {
              if (activeTab != item['name']) {
                setState(() {
                  activeTab = item['name']; // Update the active tab
                });
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        item['screen'], // Navigate to the corresponding screen
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal:
                    isActive ? 20 : 0, // Add horizontal padding for active tab
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFA1CA73) // Green for active
                    : Colors.transparent, // Transparent for inactive
                borderRadius: BorderRadius.circular(30), // Rounded pill shape
              ),
              child: Row(
                children: [
                  FaIcon(
                    item['icon'],
                    color: isActive
                        ? const Color(0xFF042F40) // Dark blue for active icon
                        : const Color(0xFFA1CA73), // Green for inactive icon
                    size: 20,
                  ),
                  if (isActive) ...[
                    const SizedBox(
                        width: 8), // Space between icon and text in active tab
                    Text(item['name'],
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
