import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:safar/private/parent/parent_functionality/daily_trip.dart';
import 'package:safar/private/private_bottom_nav_bar.dart';

class Tracking extends StatelessWidget {
  const Tracking({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Map Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4, // Adjust height
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter:
                      LatLng(33.6844, 73.0479), // Islamabad coordinates
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.safar',
                  ),
                ],
              ),
            ),
          ),

          // Divider Section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
            child: Divider(
              thickness: 2,
              color: Colors.grey,
            ),
          ),

          // Daily Trip Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Expanded(child: DailyTrip()),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PrivateNavBar(currentTab: 'Tracking'),
    );
  }
}
