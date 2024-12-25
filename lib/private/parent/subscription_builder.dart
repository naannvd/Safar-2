import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safar/Payment/pages/home_page.dart';

class SubscriptionCard extends StatelessWidget {
  final String title;
  final int price;
  final VoidCallback onSubscribe;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        children: [
          // Subscription Image
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/station.jpeg',
                height: 85,
                width: 85,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Subscription Details
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF042F42),
                    ),
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            'From',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFA1CA73),
                            ),
                          ),
                          Text(
                            '$price RS',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF042F42),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            onSubscribe();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF94C83D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Subscribe',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
