import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safar/private/parent/subscription_card.dart';

class SubscriptionManagement extends StatelessWidget {
  const SubscriptionManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      color: Colors.grey[200], // Background color
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SizedBox(height: 5),
          Expanded(
            child: SingleChildScrollView(
              child: SubscriptionsScreen(), // Scrollable widget
            ),
          ),
        ],
      ),
    );
  }
}
