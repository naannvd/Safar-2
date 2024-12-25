import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickalert/quickalert.dart';

class ParentFeedback extends StatelessWidget {
  const ParentFeedback({super.key});

  // Function to take feedback and store it in Firestore
  void _submitFeedback(BuildContext context, String rideId) {
    TextEditingController feedbackController = TextEditingController();

    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      widget: Column(
        children: [
          Text(
            'Provide your feedback',
            style: GoogleFonts.montserrat(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your feedback here',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      onConfirmBtnTap: () async {
        final feedback = feedbackController.text.trim();

        if (feedback.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('parent_feedbacks')
                .add({
              'ride_id': rideId,
              'feedback': feedback,
              'timestamp': Timestamp.now(),
            });

            // Close the dialog and show success message
            Navigator.pop(context);
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'Thank you!',
              text: 'Your feedback has been submitted successfully.',
            );
          } catch (e) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Error',
              text: 'Failed to submit feedback. Please try again later.',
            );
          }
        } else {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            title: 'Invalid Input',
            text: 'Please enter some feedback before submitting.',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA1CA73),
      appBar: AppBar(
        title: Text(
          'Completed Rides',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: const Color(0xFF042F42)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFA1CA73), // Match project theme
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No completed rides available.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final rides = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Card(
                color: Colors.white,
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF3E7C98),
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Ride ID: ${ride['ride_id']}',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Driver: ${ride['driver_name']}',
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.feedback,
                      color: Color(0xFF042F42),
                    ),
                    onPressed: () => _submitFeedback(context, ride['ride_id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
