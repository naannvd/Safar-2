import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkChildAttendance extends StatefulWidget {
  final List<Map<String, dynamic>> children;
  final Map<String, dynamic> rideData;

  const MarkChildAttendance(
      {super.key, required this.children, required this.rideData});

  @override
  State<MarkChildAttendance> createState() => _MarkChildAttendanceState();
}

class _MarkChildAttendanceState extends State<MarkChildAttendance> {
  @override
  void initState() {
    super.initState();
    monitorStudentStatusChanges(widget.rideData['ride_id']);
  }

  void monitorStudentStatusChanges(String rideId) {
    FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((rideSnapshot) async {
      if (rideSnapshot.exists) {
        final rideData = rideSnapshot.data();
        final List<String> studentIds =
            List<String>.from(rideData?['students'] ?? []);

        List<LatLng> studentLocations = [];
        for (String studentId in studentIds) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('childs')
              .doc(studentId)
              .get();

          if (studentDoc.exists) {
            final parentId = studentDoc.data()?['parent_id'];

            if (parentId != null) {
              final parentDoc = await FirebaseFirestore.instance
                  .collection('parents')
                  .doc(parentId)
                  .get();

              if (parentDoc.exists) {
                final lat = parentDoc.data()?['latitude'];
                final lng = parentDoc.data()?['longitude'];

                if (lat != null && lng != null) {
                  studentLocations.add(LatLng(lat, lng));
                }
              }
            }
          }
        }
        _updateGeofences(rideId, studentLocations);
      }
    });
  }

  void _updateGeofences(String rideId, List<LatLng> studentLocations) async {
    try {
      // Reference to the 'geofences' sub-collection within the 'rides' document
      final geofencesCollection = FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('geofences');

      // Clear existing geofence document
      final existingDocs = await geofencesCollection.get();
      for (var doc in existingDocs.docs) {
        await doc.reference.delete();
      }

      // Prepare the list of latitude and longitude as a single array
      List<Map<String, double>> geofenceLocations =
          studentLocations.map((location) {
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }).toList();

      // Add a new document containing the array of geofence coordinates
      await geofencesCollection.doc('student_geofences').set({
        'geofences': geofenceLocations,
        'radius': 100, // Add a radius value if needed for geofencing logic
        'updated_at': FieldValue.serverTimestamp(),
      });

      print("Geofences updated successfully for ride: $rideId");
    } catch (e) {
      print("Error updating geofences: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.children.map(
        (child) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: ListTile(
                    title: Text(
                      child['child_name'],
                      style: GoogleFonts.montserrat(fontSize: 17),
                    ),
                    subtitle: Text(
                      'Status: ${child['is_present'] ? "Going" : "Not Going"}',
                      style: GoogleFonts.montserrat(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: child['is_present'],
                      onChanged: (bool newStatus) async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('childs')
                              .doc(child['child_id'])
                              .update({'is_present': newStatus});

                          setState(() {
                            child['is_present'] = newStatus;
                          });

                          final rideQuery = await FirebaseFirestore.instance
                              .collection('rides')
                              .where('ride_id',
                                  isEqualTo: widget.rideData['ride_id'])
                              .get();

                          for (var doc in rideQuery.docs) {
                            await doc.reference.update({
                              'students': newStatus
                                  ? FieldValue.arrayUnion([child['child_id']])
                                  : FieldValue.arrayRemove([child['child_id']])
                            });
                          }

                          // Fetch the updated list of students and update geofences
                          List<LatLng> studentLocations = [];

                          for (var doc in rideQuery.docs) {
                            final rideData = doc.data();
                            final List<String> studentIds =
                                List<String>.from(rideData['students'] ?? []);

                            for (String studentId in studentIds) {
                              final studentDoc = await FirebaseFirestore
                                  .instance
                                  .collection('childs')
                                  .doc(studentId)
                                  .get();

                              if (studentDoc.exists) {
                                final parentId =
                                    studentDoc.data()?['parent_id'];

                                if (parentId != null) {
                                  final parentDoc = await FirebaseFirestore
                                      .instance
                                      .collection('parents')
                                      .doc(parentId)
                                      .get();

                                  if (parentDoc.exists) {
                                    final lat = parentDoc.data()?['latitude'];
                                    final lng = parentDoc.data()?['longitude'];

                                    if (lat != null && lng != null) {
                                      studentLocations.add(LatLng(lat, lng));
                                    }
                                  }
                                }
                              }
                            }
                          }

                          // Call _updateGeofences to reflect the changes
                          _updateGeofences(
                              widget.rideData['ride_id'], studentLocations);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Status and geofences updated successfully')),
                          );
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Failed to update status: $error')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }
}
