import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:transport_app/models/ticket_model.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Preparing JSON data to display the destination and fare amount when the QR code is scanned.
  String _generateQrData(TicketModel ticket) {
    Map<String, dynamic> qrPayload = {
      'ticketId': ticket.ticketId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'destination': ticket.routeName,
      'fare': ticket.fare,
      'passengerName': ticket.passengerName,
      'busNumber': ticket.busNumber,
      'status': ticket.status,
    };
    return jsonEncode(qrPayload);
  }

  // History Tickets Modal Sheet
  void _showHistoryDialog(BuildContext context, List<QueryDocumentSnapshot> historyDocs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "History Tickets (Used/Expired)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  historyDocs.isEmpty
                      ? const Expanded(
                          child: Center(child: Text("No ticket history found.")),
                        )
                      : Expanded(
                          child: ListView.builder(
                            controller: controller,
                            itemCount: historyDocs.length,
                            itemBuilder: (context, index) {
                              TicketModel ticket = TicketModel.fromFirestore(historyDocs[index]);
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                color: Colors.grey.shade100,
                                child: ListTile(
                                  leading: QrImageView(
                                    data: _generateQrData(ticket),
                                    size: 50.0,
                                  ),
                                  title: Text(
                                    ticket.routeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text("Bus: ${ticket.busNumber} | LKR ${ticket.fare.toStringAsFixed(2)}"),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ticket.status,
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Digital Tickets')),
        body: const Center(child: Text('Please log in to view your tickets.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Digital Tickets'),
        backgroundColor: const Color(0xFF1A2B4C),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Filtering only the logged-in user's tickets from Firestore
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('passengerName', isEqualTo: currentUser?.displayName ?? currentUser?.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No tickets found for your account.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          var docs = snapshot.data!.docs;

          // 1. Valid / Retrieving unscanned tickets (sorted to bring the newest one to the top)
          var validDocs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? 'VALID') == 'VALID';
          }).toList();

          // 2. Used / Separating scanned tickets
          var historyDocs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '') != 'VALID';
          }).toList();

          TicketModel? activeTicket;
          if (validDocs.isNotEmpty) {
            activeTicket = TicketModel.fromFirestore(validDocs.first);
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: activeTicket != null
                      ? SingleChildScrollView(
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "ACTIVE TICKET",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // LATEST VALID UNIQUE QR CODE
                                  QrImageView(
                                    data: _generateQrData(activeTicket),
                                    version: QrVersions.auto,
                                    size: 220.0,
                                    backgroundColor: Colors.white,
                                  ),

                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 10),

                                  // Ticket Details
                                  Text(
                                    activeTicket.routeName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFF1A2B4C),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Bus: ${activeTicket.busNumber}",
                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Fare: LKR ${activeTicket.fare.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Text(
                            "No active tickets available.\nBuy a ticket to view your QR.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                ),

                const SizedBox(height: 10),

                // History Tickets Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A2B4C), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showHistoryDialog(context, historyDocs),
                    icon: const Icon(Icons.history, color: Color(0xFF1A2B4C)),
                    label: Text(
                      "History Tickets (${historyDocs.length})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}