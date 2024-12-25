import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class SetLocationScreen extends StatefulWidget {
  final String parentId;

  const SetLocationScreen({super.key, required this.parentId});

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  LatLng? _selectedLocation;
  late GoogleMapController _mapController;
  LocationData? _currentLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final location = Location();
      final currentLocation = await location.getLocation();
      setState(() {
        _currentLocation = currentLocation;
        _selectedLocation = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch current location: $e')),
      );
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation != null) {
      try {
        await FirebaseFirestore.instance
            .collection('parents')
            .doc(widget.parentId)
            .update({
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location saved successfully!',
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save location: $e',
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a location on the map.',
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Set Location",
          style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF042F42)),
        ),
        backgroundColor: const Color(0xFFA1CA73),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onTap: _onMapTap,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? const LatLng(33.6844, 73.0479),
                    zoom: 14,
                  ),
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selectedLocation'),
                            position: _selectedLocation!,
                          ),
                        }
                      : {},
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLng(_selectedLocation!),
                      );
                    }
                  },
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _saveLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA1CA73),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Save Location",
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF042F42),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_selectedLocation != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Location:',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF042F42),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.black87,
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
