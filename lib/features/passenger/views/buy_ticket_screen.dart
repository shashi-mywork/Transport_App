import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transport_app/models/ticket_model.dart';

class BuyTicketScreen extends StatefulWidget {
  final Map<String, dynamic> selectedBus;

  const BuyTicketScreen({super.key, required this.selectedBus});

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  final TextEditingController _nameController = TextEditingController();
  String selectedPaymentMethod = "App Wallet"; // Default payment method
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Auto-filling the logged-in user's name
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      } else {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
            setState(() {
              _nameController.text = data['name'] ?? data['userName'] ?? "Passenger";
            });
          } else {
            _nameController.text = user.email ?? "Passenger";
          }
        } catch (e) {
          _nameController.text = "Passenger";
        }
      }
    }
  }

  // Booking the ticket and saving it to Firestore
  Future<void> bookTicket() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter passenger name')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      double fare = (widget.selectedBus['fare'] as num).toDouble();

      TicketModel newTicket = TicketModel(
        passengerName: _nameController.text.trim(),
        busNumber: widget.selectedBus['busNumber'] ?? '',
        routeName: widget.selectedBus['routeName'] ?? '',
        fare: fare,
        purchaseTime: DateTime.now(),
        status: "VALID",
      );

      //Saving a ticket to the Firestore 'tickets' collection
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('tickets')
          .add({
        ...newTicket.toMap(),
        'paymentMethod': selectedPaymentMethod,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket Booked Successfully via $selectedPaymentMethod!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Closing the screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking ticket: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double fare = (widget.selectedBus['fare'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout & Buy Ticket'),
        backgroundColor: const Color(0xFF1A2B4C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PASSENGER & BUS SUMMARY CARD
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Trip & Passenger Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4C),
                      ),
                    ),
                    const Divider(height: 20),

                    // Passenger Name Field
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Passenger Name",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Bus Details
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Color(0xFF1A2B4C)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Bus: ${widget.selectedBus['busNumber'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Route Details
                    Row(
                      children: [
                        const Icon(Icons.alt_route, color: Color(0xFF1A2B4C)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Route: ${widget.selectedBus['routeName'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Time Details
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF1A2B4C)),
                        const SizedBox(width: 10),
                        Text(
                          "Departure: ${widget.selectedBus['departureTime'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),

                    const Divider(height: 25),

                    // Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Amount:",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "LKR ${fare.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. PAYMENT METHOD CARD (Radio Buttons)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Payment Method",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4C),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Option 1: App Wallet
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.blue),
                          SizedBox(width: 10),
                          Text("App Wallet", style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      value: "App Wallet",
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                    ),

                    const Divider(height: 1),

                    // Option 2: Visa / Master Card
                    RadioListTile<String>(
                      title: const Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.orange),
                          SizedBox(width: 10),
                          Text("Visa / MasterCard", style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      value: "Visa / MasterCard",
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 3. BUY TICKET BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00875A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isLoading ? null : bookTicket,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "CONFIRM & PAY LKR ${fare.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}