import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LineMapBox extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> routePoints;
  final String? selectedLine;

  const LineMapBox({
    super.key,
    required this.routePoints,
    required this.selectedLine,
  });

  @override
  Widget build(BuildContext context) {
    print(selectedLine);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: routePoints,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading route points'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No route points available'));
        } else {
          // Determine marker color based on the selectedLine
          Color markerColor;
          switch (selectedLine?.toLowerCase()) {
            case 'red-line':
              markerColor = const Color(0xFFCC3636);
              break;
            case 'blue-line':
              markerColor = const Color(0xFF3E7C98);
              break;
            case 'green-line':
              markerColor = const Color(0xFFA1CA73);
              break;
            case 'orange-line':
              markerColor = const Color(0xFFE06236);
              break;
            default:
              markerColor = Colors.black; // Default color
          }

          List<LatLng> points = snapshot.data!.map((point) {
            return LatLng(point['latitude'], point['longitude']);
          }).toList();

          // Create markers from points with dynamic color
          List<Marker> markers = points
              .map(
                (point) => Marker(
                  point: point,
                  width: 30.0,
                  height: 30.0,
                  child: Image.asset(
                    'assets/images/bus.png',
                    // color: markerColor,
                    width: 30.0,
                    height: 30.0,
                  ),
                ),
              )
              .toList();

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.0),
              ),
              height: 350,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: points.isNotEmpty
                      ? points.first
                      : const LatLng(33.6844, 73.0479), // Default to Islamabad
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.safar',
                  ),
                  MarkerLayer(
                    markers: markers,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
