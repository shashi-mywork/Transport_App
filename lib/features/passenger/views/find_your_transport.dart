import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/features/passenger/views/buy_ticket_screen.dart';

class FindYourTransportScreen extends StatefulWidget {
  const FindYourTransportScreen({super.key});

  @override
  State<FindYourTransportScreen> createState() => _FindYourTransportScreenState();
}

class _FindYourTransportScreenState extends State<FindYourTransportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  late StreamSubscription _timerSubscription;
  DateTime currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // It automatically hides old buses while updating the current time every 30 seconds.
    _timerSubscription = Stream.periodic(const Duration(seconds: 30)).listen((_) {
      if (mounted) {
        setState(() {
          currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _timerSubscription.cancel();
    super.dispose();
  }

  // Converting a time string ("14:30") into a DateTime object
  DateTime? _parseBusTime(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    try {
      List<String> parts = timeStr.split(':');
      DateTime now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0].trim()),
        int.parse(parts[1].trim()),
      );
    } catch (e) {
      return null;
    }
  }

  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Transport'),
        backgroundColor: const Color(0xFF1A2B4C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. SEARCH BAR FOR DESTINATION OR ROUTE
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Destination or Route (e.g., Fort, Maharagama)...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A2B4C)),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Upcoming Buses",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2B4C)),
                ),
                Text(
                  "Current Time: ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 2. FIRESTORE REAL-TIME BUS LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('buses').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No bus schedules found."),
                    );
                  }

                  // Buses Filter and Sort
                  var filteredBuses = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;

                    String routeName = (data['routeName'] ?? '').toString().toLowerCase();
                    String busNumber = (data['busNumber'] ?? '').toString().toLowerCase();
                    List stops = data['stops'] ?? [];
                    String stopsText = stops.join(" ").toLowerCase();

                    // Search Query Validation
                    bool matchesSearch = searchQuery.isEmpty ||
                        routeName.contains(searchQuery) ||
                        busNumber.contains(searchQuery) ||
                        stopsText.contains(searchQuery);

                    if (!matchesSearch) return false;

                    // Time Filter (Excluding buses that have already passed and considering only those that are approaching)
                    DateTime? busTime = _parseBusTime(data['departureTime']);
                    if (busTime == null) return true;

                    // Displays buses scheduled from two minutes ago onwards.
                    return busTime.isAfter(currentTime.subtract(const Duration(minutes: 2)));
                  }).toList();

                  // 3. Sorting by time to display the next arriving bus at the top.
                  filteredBuses.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;

                    DateTime? timeA = _parseBusTime(dataA['departureTime']);
                    DateTime? timeB = _parseBusTime(dataB['departureTime']);

                    if (timeA == null || timeB == null) return 0;
                    return timeA.compareTo(timeB);
                  });

                  if (filteredBuses.isEmpty) {
                    return const Center(
                      child: Text(
                        "No upcoming buses available for this route/destination.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredBuses.length,
                    itemBuilder: (context, index) {
                      var busData = filteredBuses[index].data() as Map<String, dynamic>;
                      List stops = busData['stops'] ?? [];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bus Number & Departure Time Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_bus, color: Color(0xFF1A2B4C)),
                                      const SizedBox(width: 8),
                                      Text(
                                        busData['busNumber'] ?? 'Bus',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Departs: ${busData['departureTime'] ?? 'N/A'}",
                                      style: TextStyle(
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Route Name
                              Text(
                                busData['routeName'] ?? 'Route',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A2B4C),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Stops / Bus Route Stops Section
                              if (stops.isNotEmpty) ...[
                                Row(
                                  children: const [
                                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      "Stops:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  stops.join(" ➔ "),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              const Divider(),

                              // Fare and Buy Ticket Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Fare: LKR ${busData['fare'] ?? '0'}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00875A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      // Buy Ticket Screen එකට Navigate වීම
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BuyTicketScreen(selectedBus: busData),
                                        ),
                                      );
                                    },
                                    child: const Text("BUY TICKET"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}