import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:safar/consts.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SlidingPanelWithDirections extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final String stationName;

  const SlidingPanelWithDirections({
    required this.startLocation,
    required this.endLocation,
    super.key,
    required this.stationName,
  });

  @override
  State<SlidingPanelWithDirections> createState() =>
      _SlidingPanelWithDirectionsState();
}

class _SlidingPanelWithDirectionsState
    extends State<SlidingPanelWithDirections> {
  List<String> _steps = []; // To store textual directions
  bool _isLoading = true; // Loading state for directions

  @override
  void initState() {
    super.initState();
    _fetchDirections(); // Fetch directions when widget initializes
  }

  Future<void> _fetchDirections() async {
    const String apiKey = googleApiKey; // Add your Google API Key
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${widget.startLocation.latitude},${widget.startLocation.longitude}&destination=${widget.endLocation.latitude},${widget.endLocation.longitude}&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final steps = data['routes'][0]['legs'][0]['steps'] as List;

          // Extract textual directions
          setState(() {
            _steps = steps
                .map((step) => _parseHtmlText(step['html_instructions']))
                .toList();
            _isLoading = false;
          });
        } else {
          throw Exception("No directions found");
        }
      } else {
        throw Exception("Failed to fetch directions");
      }
    } catch (e) {
      setState(() {
        _steps = []; // Empty steps list on failure
        _isLoading = false;
      });
      debugPrint("Error fetching directions: $e");
    }
  }

  String _parseHtmlText(String html) {
    // Remove HTML tags for cleaner display
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Widget _buildRouteDetailsPanel() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Details',
            style: GoogleFonts.montserrat(
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
                  'Your Location: ${widget.startLocation.latitude.toStringAsFixed(4)}, ${widget.startLocation.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'End Location: ${widget.stationName}',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1.5),
          const SizedBox(height: 10),

          // Conditional Loading State for Directions
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _steps.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                const Icon(Icons.directions,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _steps[index],
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No directions available.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      minHeight: 100,
      maxHeight: 400, // Increased maxHeight to accommodate directions
      panel: _buildRouteDetailsPanel(),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    );
  }
}
