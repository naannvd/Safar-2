import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Map<String, Marker> _markers = {}; // Map to hold markers for all locations
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  void _fetchLocations() async {
    try {
      FirebaseFirestore.instance.collection("locations").snapshots().listen(
        (querySnapshot) {
          Map<String, Marker> newMarkers = {};
          for (var document in querySnapshot.docs) {
            if (document.exists) {
              final data = document.data();
              final latitude = data["latitude"];
              final longitude = data["longitude"];
              final docId = document.id;

              if (latitude != null && longitude != null) {
                final marker = Marker(
                  markerId: MarkerId(docId),
                  position: LatLng(latitude, longitude),
                  infoWindow: InfoWindow(title: "Location: $docId"),
                );
                newMarkers[docId] = marker;
              }
            }
          }
          setState(() {
            _markers = newMarkers;
          });
          if (_markers.isNotEmpty && _mapController != null) {
            // Move the camera to the first marker's location
            final firstLocation = _markers.values.first.position;
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(firstLocation),
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Error fetching locations: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   // title: const Text("Map View"),
      // ),
      body: Stack(
        children: [
          _error.isNotEmpty
              ? Center(
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(33.652617874502404,
                        73.1569340558223), // Default position until data is loaded
                    zoom: 14, // Zoom out to view all locations initially
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers.values.toSet(), // Display all markers
                ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    child: const Icon(Icons.arrow_back_ios),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(
                    width: 100,
                  ),
                  Text(
                    'Tracking',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
