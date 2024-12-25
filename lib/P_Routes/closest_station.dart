import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safar/P_Routes/Services/directions_panel.dart';
import 'package:safar/P_Routes/Services/directions_service.dart';
import 'package:safar/P_Routes/Services/distance_calculator.dart';
import 'package:safar/P_Routes/Services/location_service.dart';
import 'package:safar/P_Routes/Services/stations_repository.dart';
import 'package:safar/P_Routes/route_displayer.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ClosestStation extends StatefulWidget {
  final LocationService locationService;
  final StationsRepository stationsRepository;
  final DirectionsService directionsService;

  const ClosestStation({
    super.key,
    required this.locationService,
    required this.stationsRepository,
    required this.directionsService,
  });

  @override
  State<ClosestStation> createState() => _ClosestStationState();
}

class _ClosestStationState extends State<ClosestStation> {
  LatLng? _userLocation;
  Map<String, dynamic>? _nearestStation;
  List<LatLng> _routePoints = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _findAndDisplayNearestStation();
  }

  Future<void> _findAndDisplayNearestStation() async {
    setState(() => _isLoading = true);
    try {
      final position = await widget.locationService.getUserLocation();
      _userLocation = LatLng(position.latitude, position.longitude);

      final stations = await widget.stationsRepository.fetchStations();
      _nearestStation = _findNearestStation(stations, _userLocation!);

      if (_nearestStation != null) {
        _routePoints = await widget.directionsService.getRoutePolyline(
          _userLocation!.latitude,
          _userLocation!.longitude,
          _nearestStation!['latitude'],
          _nearestStation!['longitude'],
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _findNearestStation(
      List<Map<String, dynamic>> stations, LatLng userLoc) {
    double minDistance = double.infinity;
    Map<String, dynamic>? nearest;
    for (var station in stations) {
      final dist = DistanceCalculator.haversineDistance(userLoc.latitude,
          userLoc.longitude, station['latitude'], station['longitude']);

      if (dist < minDistance) {
        minDistance = dist;
        nearest = station;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (_userLocation == null || _nearestStation == null) {
      return const Scaffold(
        body: Center(child: Text('No location or station data available.')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: RouteDisplayWidget(
                  userLocation: _userLocation!,
                  stationLocation: LatLng(_nearestStation!['latitude'],
                      _nearestStation!['longitude']),
                  routePoints: _routePoints,
                ),
              ),
            ],
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
                  const Spacer(),
                  const Text(
                    'Nearest Station',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          ClosestStationDirectionsPanel(
              userLocation: _userLocation!, nearestStation: _nearestStation!)
        ],
      ),
    );
  }
}
