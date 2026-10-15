import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:transport_app/models/ticket_model.dart';

class MyTicketsScreen extends StatefulWidget {
  final TicketModel? activeTicket;

  const MyTicketsScreen({
    super.key,
    this.activeTicket,
  });

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Preparing JSON data to display when the QR code is scanned.
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

  // History Dialog Display Function
  void _showHistoryDialog(BuildContext context, List<QueryDocumentSnapshot> historyDocs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.history, color: Color(0xFF1A2B4C)),
            SizedBox(width: 8),
            Text("Ticket History", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: historyDocs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    "No past/used tickets found.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: historyDocs.length,
                  itemBuilder: (context, index) {
                    TicketModel ticket = TicketModel.fromFirestore(historyDocs[index]);
                    DateTime pTime = ticket.purchaseTime;
                    String formattedDate = "${pTime.day.toString().padLeft(2, '0')}/${pTime.month.toString().padLeft(2, '0')}/${pTime.year}";

                    int hour = pTime.hour % 12 == 0 ? 12 : pTime.hour % 12;
                    String period = pTime.hour >= 12 ? 'PM' : 'AM';
                    String formattedTime = "${hour.toString().padLeft(2, '0')}:${pTime.minute.toString().padLeft(2, '0')} $period";
                  
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.confirmation_number_outlined, color: Colors.grey, size: 30),
                        title: Text(
                          ticket.routeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Bus: ${ticket.busNumber} | Status: ${ticket.status}"),
                            const SizedBox(height: 2),
                            // Date & Time Display
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "$formattedDate at $formattedTime",
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          "LKR ${ticket.fare.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
        stream: FirebaseFirestore.instance.collection('tickets').where('userId', isEqualTo: currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && widget.activeTicket == null) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot>[];

          // 1. Valid tickets
          var validDocs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? 'VALID') == 'VALID';
          }).toList();

          // 2. History tickets (Explicit List Type set කර ඇත)
          List<QueryDocumentSnapshot> historyDocs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '') != 'VALID';
          }).toList();

          TicketModel? activeTicket = widget.activeTicket ??
              (validDocs.isNotEmpty ? TicketModel.fromFirestore(validDocs.first) : null);

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