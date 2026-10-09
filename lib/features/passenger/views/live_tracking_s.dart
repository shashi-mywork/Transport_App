import 'package:flutter/material.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        backgroundColor: const Color(0xFF1A2B4C),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Simulated Map View Area
          Container(
            color: Colors.blueGrey.shade100,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Live Google Map View", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
          ),
          
          // Bus Info Overlay
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Bus: NB-4589 (Route 138)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Chip(label: Text("LIVE"), backgroundColor: Colors.greenAccent),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text("Current Location: Nugegoda Junction"),
                    Text("Estimated Arrival: 5 Mins"),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}