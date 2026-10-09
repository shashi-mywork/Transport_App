import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'find_your_transport.dart';
import 'my_tickets.dart';
import 'live_tracking_s.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF1A2B4C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part C has been added here: Displaying User Details from Firestore.
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: LinearProgressIndicator(),
                  );
                }

                if (snapshot.hasData && snapshot.data!.exists) {
                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  String name = userData['name'] ?? 'Passenger';
                  String role = userData['role'] ?? 'passenger';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $name!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'Role: ${role.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Default text (if data fails to load)
                return const Text(
                  'Welcome Passenger!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                );
              },
            ),

            const SizedBox(height: 15),
            const Text('What would you like to do today?'),
            const SizedBox(height: 20),

            // Menu Option 1: Buy Ticket
            _buildMenuCard(
              context,
              title: 'Find Your Transport',
              subtitle: 'Find Your Transport quickly',
              icon: Icons.search_outlined,
              color: Colors.blue.shade800,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FindYourTransportScreen()),
                  ),
            ),
            const SizedBox(height: 12),

            // Menu Option 2: View My Tickets & QR
            _buildMenuCard(
              context,
              title: 'My Tickets & QR Codes',
              subtitle: 'View active tickets for scanning',
              icon: Icons.qr_code_scanner,
              color: Colors.green.shade700,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                  ),
            ),
            const SizedBox(height: 12),

            // Menu Option 3: Live Bus Tracking
            _buildMenuCard(
              context,
              title: 'Live Bus Tracking',
              subtitle: 'Track buses on Google Maps',
              icon: Icons.location_on_outlined,
              color: Colors.orange.shade800,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiveTrackingScreen(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}