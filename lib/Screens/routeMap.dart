import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:safar/Screens/station_directions.dart';
import 'dart:async';

import 'package:safar/consts.dart';

class RouteMapScreen extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final String stationName;

  const RouteMapScreen({
    super.key,
    required this.startLocation,
    required this.endLocation,
    required this.stationName,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  late GoogleMapController mapController;
  BitmapDescriptor?
      customIcon; // Make it nullable to handle asynchronous loading

  @override
  void initState() {
    super.initState();
    _getPolyline();
  }

  Future<void> _getPolyline() async {
    double originLatitude = widget.startLocation.latitude;
    double originLongitude = widget.startLocation.longitude;
    double destLatitude = widget.endLocation.latitude;
    double destLongitude = widget.endLocation.longitude;

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(originLatitude, originLongitude),
        destination: PointLatLng(destLatitude, destLongitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xFF042F42),
          width: 3,
          points: polylineCoordinates,
        ));
      });
    } else {
      print(result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.startLocation,
              zoom: 12.0,
            ),
            polylines: _polylines,
            markers: {
              Marker(
                markerId: const MarkerId('start'),
                position: widget.startLocation,
                // icon: customIcon!,
                infoWindow: const InfoWindow(title: 'Your Location'),
              ),
              Marker(
                markerId: const MarkerId('end'),
                position: widget.endLocation,
                // icon: customIcon!,
                infoWindow: InfoWindow(title: widget.stationName),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              mapController = controller;
            },
          ),

          // Floating action button to recenter
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () async {
                mapController.animateCamera(
                  CameraUpdate.newLatLng(widget.startLocation),
                );
              },
            ),
          ),

          // Sliding Up Panel for Route Details
          SlidingPanelWithDirections(
            startLocation: widget.startLocation,
            endLocation: widget.endLocation,
            stationName: widget.stationName,
          ),

          // App Bar-like Top Overlay
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
                    'Directions',
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
