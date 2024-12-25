import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safar/consts.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ClosestStationDirectionsPanel extends StatefulWidget {
  final LatLng userLocation;
  final Map<String, dynamic> nearestStation;

  const ClosestStationDirectionsPanel({
    required this.userLocation,
    required this.nearestStation,
    super.key,
  });

  @override
  State<ClosestStationDirectionsPanel> createState() =>
      _ClosestStationDirectionsPanelState();
}

class _ClosestStationDirectionsPanelState
    extends State<ClosestStationDirectionsPanel> {
  Map<String, dynamic> _directions = {
    'distance': 'Fetching...',
    'duration': 'Fetching...',
    'steps': null, // Initialize steps as null
  };

  Future<Map<String, dynamic>> _getDirections(
      LatLng origin, LatLng destination) async {
    const String apiKey = googleApiKey;
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    try {
      debugPrint("Requesting Directions API: $url");

      final response = await http.get(Uri.parse(url));
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0]['legs'][0];
          return {
            'distance': route['distance']['text'],
            'duration': route['duration']['text'],
            'steps': route['steps'] ?? [], // Safely handle null steps
          };
        } else {
          debugPrint("Directions API response error: ${data['status']}");
          throw Exception("Directions API returned: ${data['status']}");
        }
      } else {
        throw Exception("HTTP Request Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching directions: $e");
      return {'distance': 'N/A', 'duration': 'N/A', 'steps': null};
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDirections();
  }

  Future<void> _fetchDirections() async {
    final LatLng stationLocation = LatLng(
      widget.nearestStation['latitude'],
      widget.nearestStation['longitude'],
    );

    final result = await _getDirections(widget.userLocation, stationLocation);
    setState(() {
      _directions = result;
    });
  }

  String _cleanHtmlInstructions(String htmlInstructions) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlInstructions.replaceAll(exp, '');
  }

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      minHeight: 100,
      maxHeight: 400,
      panel: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Station Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Station Name: ${widget.nearestStation['name']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.directions, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Distance: ${_directions['distance']} \nDuration: ${_directions['duration']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1.5),
            const SizedBox(height: 10),
            if (_directions['steps'] != null) ...[
              const Text(
                'Directions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: (_directions['steps'] as List).length,
                  itemBuilder: (context, index) {
                    final step = (_directions['steps'] as List)[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right_alt,
                              size: 20, color: Colors.blueAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _cleanHtmlInstructions(
                                  step['html_instructions'] ?? ''),
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Center(
                child: Text(
                  'No directions available.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    );
  }
}
