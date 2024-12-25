import 'package:drop_down_list/model/selected_list_item.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drop_down_list/drop_down_list.dart';

class StationDropDown extends StatefulWidget {
  final void Function(String) onStationSelected;
  final String selectedLine;
  final List<String> excludedStations;

  const StationDropDown({
    super.key,
    required this.onStationSelected,
    required this.selectedLine,
    required this.excludedStations,
  });

  @override
  State<StationDropDown> createState() => _StationDropDownState();
}

class _StationDropDownState extends State<StationDropDown> {
  List<SelectedListItem> _stationItems = [];
  bool _isLoading = true;
  String? _selectedStation;

  @override
  void initState() {
    super.initState();
    _fetchStationNames(widget.selectedLine);
  }

  @override
  void didUpdateWidget(covariant StationDropDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLine != oldWidget.selectedLine ||
        widget.excludedStations != oldWidget.excludedStations) {
      setState(() {
        _isLoading = true;
        _stationItems = [];
      });
      _fetchStationNames(widget.selectedLine);
    }
  }

  Future<void> _fetchStationNames(String selectedLine) async {
    try {
      // Query the routes collection for the selected line
      final DocumentSnapshot<Map<String, dynamic>> routeDoc =
          await FirebaseFirestore.instance
              .collection('routes')
              .doc(selectedLine)
              .get();

      // Check if the document exists and contains a stations field
      if (!routeDoc.exists || !routeDoc.data()!.containsKey('stations')) {
        throw Exception(
            'No stations found for the selected line: $selectedLine');
      }

      // Extract the stations field, which is a List<Map<String, dynamic>>
      final List<dynamic> stations = routeDoc.data()!['stations'];

      // Map the stations to SelectedListItem objects, excluding selected stations
      final List<SelectedListItem> stationNames = stations
          .cast<Map<String, dynamic>>()
          .where((station) =>
              !widget.excludedStations.contains(station['station_name']))
          .map((station) => SelectedListItem(name: station['station_name']))
          .toList();

      setState(() {
        _stationItems = stationNames;
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors and update state
      print('Error fetching station names: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isLoading) const CircularProgressIndicator(),
        if (!_isLoading && _stationItems.isNotEmpty)
          GestureDetector(
            onTap: () => _showDropdown(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromARGB(255, 4, 47, 64),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedStation ?? 'Select a Station'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        if (!_isLoading && _stationItems.isEmpty)
          const Text('No stations available for this metro line'),
      ],
    );
  }

  void _showDropdown() {
    DropDownState(
      DropDown(
        dropDownBackgroundColor: Colors.white,
        bottomSheetTitle: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Stations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        data: _stationItems,
        selectedItems: (List<dynamic> selectedList) {
          if (selectedList.isNotEmpty) {
            setState(() {
              _selectedStation = selectedList[0].name;
            });
            widget.onStationSelected(_selectedStation!);
          }
        },
      ),
    ).showModal(context);
    FocusScope.of(context).unfocus();
  }
}
