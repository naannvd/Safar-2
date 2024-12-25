import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safar/Dashboard/landing_page.dart';
import 'package:safar/Payment/pages/home_page.dart';
import 'package:safar/Tickets/line_map_box.dart';
import 'package:safar/Tickets/save_route.dart';
import 'package:safar/Tickets/station_drop_down.dart';
import 'package:safar/Tickets/ticket.dart';
import 'package:safar/Tickets/ticket_support.dart';
import 'package:safar/Widgets/bottom_nav_bar.dart';

class TicketBook extends StatefulWidget {
  final String selectedLine;
  final String fromStation;
  final String toStation;

  const TicketBook(
      {super.key,
      this.selectedLine = '',
      this.fromStation = '',
      this.toStation = ''});

  @override
  State<TicketBook> createState() => _TicketBookState();
}

class _TicketBookState extends State<TicketBook> {
  String? _selectedStationFrom;
  String? _selectedStationTo;
  String? _selectedLine;
  int? fare;

  // Map for metro lines and their corresponding colors
  final Map<String, Color> lineColors = {
    'Blue-Line': const Color(0xFF3E7C98),
    'Red-Line': const Color(0xFFCC3636),
    'Green-Line': const Color(0xFFA1CA73),
    'Orange-Line': const Color(0xFFE06236),
  };

  // List of metro lines
  final List<String> metroLines = [
    'Blue-Line',
    'Red-Line',
    'Green-Line',
    'Orange-Line'
  ];

  void _onFromStationSelect(String station) {
    setState(() {
      _selectedStationFrom = station;
    });
  }

  void _onToStationSelect(String station) {
    setState(() {
      _selectedStationTo = station;
    });
  }

  void _onLineSelect(String? line) {
    setState(() {
      // print(line);
      _selectedLine = line;
    });
    if (line != null) {
      _fetchFare(line);
    }
  }

  Future<void> _fetchFare(String lineName) async {
    // print('Fetching fare for line: $lineName'); // Debug log
    try {
      // Fetch fare from Firestore using TicketSupport
      TicketSupport ticketSupport = TicketSupport();
      int baseFare = await ticketSupport.getFare(lineName);

      // print('Base fare retrieved: $baseFare'); // Debug log

      // Fetch user's discount
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document does not exist.');
      }

      final discountPercentage =
          (userDoc.data()?['nextTicketDiscount'] ?? 0) as int;
      // print('User discount percentage: $discountPercentage'); // Debug log

      // Apply discount if available
      final discountedFare =
          (baseFare * (1 - discountPercentage / 100)).round();

      // Update state with the discounted fare
      setState(() {
        fare = discountedFare;
      });

      // print('Discounted fare: $fare'); // Debug log
    } catch (e) {
      // print('Error fetching fare: $e');
      // print(
      // 'Stack trace: $stackTrace'); // Debug stack trace for better insights
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching fare: $e. Please try again.'),
        ),
      );
    }
  }

  Future<String?> getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<List<Map<String, dynamic>>> fetchStationsFromRoute(
        String? _selectedLine) async {
      final userDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(_selectedLine)
          .get();
      final stations = userDoc.data()?['stations'] as List;
      return stations.cast<Map<String, dynamic>>();
    }

    Future<List<Map<String, dynamic>>> stations =
        fetchStationsFromRoute(_selectedLine);
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const RoundedNavBar(currentTab: 'Ticket'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedLine != null)
              LineMapBox(
                selectedLine: _selectedLine,
                routePoints: stations,
              ),
            const Padding(
              padding:
                  EdgeInsets.only(right: 12.0, left: 12.0, bottom: 10, top: 8),
              child: Divider(),
            ),
            const Text(
              'Book Ticket',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            // Metro Line Dropdown
            Container(
              alignment: Alignment.center,
              height: 40,
              width: 200,
              decoration: BoxDecoration(
                color: _selectedLine != null
                    ? lineColors[_selectedLine]
                    : const Color(
                        0xFFA1CA73), // Change color based on selected line
                border: Border.all(
                  color: Color.fromARGB(41, 31, 119, 154),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<String>(
                value: _selectedLine,
                hint: Text(
                  'Select Line',
                  style: GoogleFonts.montserrat(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                dropdownColor: _selectedLine != null
                    ? lineColors[_selectedLine] // Change dropdown color
                    : Colors.grey[300],
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF042F42),
                ),
                underline: Container(), // Remove the default underline
                onChanged: _onLineSelect,
                style: const TextStyle(
                  // Set the style for the selected text
                  color: Colors.white, // Change selected text color to white
                  fontSize: 16,
                ),
                items: metroLines.map((String line) {
                  return DropdownMenuItem<String>(
                    value: line,
                    child: Text(
                      line,
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(
                          color: _selectedLine == null
                              ? Colors.black
                              : Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            // Conditionally render Station Dropdowns or prompt user to select a line
            if (_selectedLine == null)
              Container(
                alignment: Alignment.center,
                height: 40,
                width: 200,
                child: Text(
                  'Select a line',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              )
            else ...[
              // From Station Dropdown
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    StationDropDown(
                      onStationSelected: (station) {
                        setState(() {
                          _selectedStationFrom = station;
                        });
                      },
                      selectedLine: _selectedLine!, // Pass the selected line
                      excludedStations: _selectedStationTo != null
                          ? [_selectedStationTo!]
                          : [],
                    ),
                    const SizedBox(height: 15),
                    StationDropDown(
                      onStationSelected: (station) {
                        setState(() {
                          _selectedStationTo = station;
                        });
                      },
                      selectedLine: _selectedLine!, // Pass the selected line
                      excludedStations: _selectedStationFrom != null
                          ? [_selectedStationFrom!]
                          : [],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(
              height: 13,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_selectedLine != null)
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.train,
                      color:
                          _selectedLine != null ? Colors.white : Colors.black,
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedLine != null
                            ? lineColors[_selectedLine]
                            : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 8)),
                    onPressed: () async {
                      if (_selectedStationFrom != null &&
                          _selectedStationTo != null &&
                          _selectedLine != null) {
                        // Check if fare is available
                        if (fare == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Fare not available. Please select a valid metro line.'),
                            ),
                          );
                          return; // Exit if fare is not available
                        }
                        // Fetch the userId
                        String? receivedUserId = await getUserId();
                        if (receivedUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'User not logged in. Please log in to book a ticket.'),
                            ),
                          );
                          return; // Exit if userId is null
                        }

                        // Initiate Payment
                        bool paymentSuccessful =
                            await PaymentHelper.openStripePaymentView(
                                context, fare!);

                        if (paymentSuccessful) {
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .get();

                          final discountPercentage =
                              userDoc.data()?['nextTicketDiscount'] ?? 0;
                          if (discountPercentage > 0) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .update({'nextTicketDiscount': 0});
                          }
                          // If payment is successful, then create the ticket
                          String ticketId =
                              TicketSupport().generateTicketId(_selectedLine!);
                          try {
                            await TicketSupport().createTicket(
                              userId: receivedUserId,
                              fromStation: _selectedStationFrom!,
                              toStation: _selectedStationTo!,
                              routeName: _selectedLine!,
                              fare: fare!,
                              timeToNext: 10,
                              ticketId: ticketId,
                            );

                            // After ticket creation, reset station fields
                            setState(() {
                              _selectedStationFrom = null;
                              _selectedStationTo = null;
                            });

                            // Navigate to TicketCard page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TicketCard(),
                              ),
                            );
                          } catch (e) {
                            print(e);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error booking ticket: $e')),
                            );
                          }
                        }
                      } else {
                        // Display an error message if any field is not selected
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a line and stations.'),
                          ),
                        );
                      }
                    },
                    label: Text(
                      'Book Ticket',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color:
                            _selectedLine != null ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                if (_selectedLine != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedLine != null
                            ? lineColors[_selectedLine]
                            : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8)),
                    onPressed: () async {
                      if (_selectedStationFrom != null &&
                          _selectedStationTo != null &&
                          _selectedLine != null) {
                        try {
                          await SaveRoute().saveRoute(
                            userId: FirebaseAuth.instance.currentUser!.uid,
                            fromStation: _selectedStationFrom!,
                            toStation: _selectedStationTo!,
                            routeName: _selectedLine!,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LandingPage(),
                            ),
                          );
                        } catch (e) {
                          print(e);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a line and stations.'),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.save,
                      color:
                          _selectedLine != null ? Colors.white : Colors.black,
                    ),
                    label: Text(
                      'Save Route ',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color:
                            _selectedLine != null ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
