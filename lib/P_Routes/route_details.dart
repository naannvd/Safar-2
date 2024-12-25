import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safar/P_Routes/Services/location_service.dart';
import 'package:safar/Screens/routeMap.dart';
import 'package:timeline_tile/timeline_tile.dart';
// import 'package:safar/Screens/routeMap.dart';

class RouteDetails extends StatelessWidget {
  const RouteDetails({super.key, required this.routeName});

  final String routeName;

  Future<List<Map<String, dynamic>>> getStations(String routeName) async {
    try {
      final routeStations = await FirebaseFirestore.instance
          .collection('routes')
          .doc(routeName)
          .get();

      if (routeStations.exists) {
        final stationList =
            List<Map<String, dynamic>>.from(routeStations['stations'] as List);
        return stationList;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching stations: $e');
      return [];
    }
  }

  Future<LatLng> getUserLocation() async {
    try {
      final locationService = LocationService();
      final userLocation = await locationService.getUserLocation();
      return LatLng(userLocation.latitude, userLocation.longitude);
    } catch (e) {
      print('Error getting user location: $e');
      // Fallback to a default location if user location fails
      return const LatLng(33.6524, 73.1570); // Default Islamabad location
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getStations(routeName),
        builder: (context, stationSnapshot) {
          if (stationSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (stationSnapshot.hasError) {
            return const Center(
              child: Text('Error loading stations'),
            );
          } else if (stationSnapshot.hasData &&
              stationSnapshot.data!.isNotEmpty) {
            final stations = stationSnapshot.data!;
            var colorVal = routeName == 'Red-Line'
                ? const Color(0xFFCC3636)
                : routeName == 'Orange-Line'
                    ? const Color(0xFFE06236)
                    : routeName == 'Green-Line'
                        ? const Color(0xFFA1CA73)
                        : const Color(0xFF3E7C98);

            return FutureBuilder<LatLng>(
              future: getUserLocation(),
              builder: (context, locationSnapshot) {
                if (locationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (locationSnapshot.hasError) {
                  return const Center(
                    child: Text('Error getting user location'),
                  );
                } else if (locationSnapshot.hasData) {
                  final startLocation = locationSnapshot.data!;

                  return ListView.builder(
                    itemCount: stations.length,
                    itemBuilder: (context, index) {
                      final station = stations[index];
                      final stationName = station['station_name'] as String? ??
                          'Unknown Station';
                      final longitude = station['longitude'] as double? ?? 0.0;
                      final latitude = station['latitude'] as double? ?? 0.0;

                      // Station location as the end location
                      final LatLng endLocation = LatLng(latitude, longitude);

                      return TimelineTile(
                        alignment: TimelineAlign.manual,
                        lineXY:
                            0.05, // Adjust this to increase or decrease the margin
                        isFirst: index == 0,
                        isLast: index == stations.length - 1,
                        indicatorStyle: IndicatorStyle(
                          width: 20,
                          color: colorVal,
                        ),
                        beforeLineStyle: const LineStyle(
                          color: Color(0xFF042F40),
                          thickness: 3,
                        ),
                        afterLineStyle: const LineStyle(
                          color: Color(0xFF042F40),
                          thickness: 3,
                        ),
                        startChild: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width:
                              50, // Set this to control the width of the left margin
                          color: Colors.transparent, // Transparent background
                        ),
                        endChild: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            splashColor: Colors.white,
                            onTap: () {
                              // Navigate to the RouteMapScreen when the card is pressed
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RouteMapScreen(
                                    startLocation: startLocation,
                                    endLocation: endLocation,
                                    stationName: stationName,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        stationName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Color(0xFF042F40),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text('Unable to fetch user location'),
                  );
                }
              },
            );
          } else {
            return const Center(
              child: Text('No stations found'),
            );
          }
        },
      ),
    );
  }
}
