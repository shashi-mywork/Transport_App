import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String? ticketId;
  final String passengerName;
  final String busNumber;
  final String routeName;
  final double fare;
  final String status; // "VALID" or "USED"
  final DateTime purchaseTime;

  TicketModel({
    this.ticketId,
    required this.passengerName,
    required this.busNumber,
    required this.routeName,
    required this.fare,
    this.status = 'VALID',
    required this.purchaseTime,
  });

  // Firestore එකට Save කරන්න Map එකක් බවට හැරවීම (CREATE)
  Map<String, dynamic> toMap() {
    return {
      'passengerName': passengerName,
      'busNumber': busNumber,
      'routeName': routeName,
      'fare': fare,
      'status': status,
      'purchaseTime': Timestamp.fromDate(purchaseTime),
    };
  }

  // Firestore එකෙන් Data ගන්න විට (READ)
  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TicketModel(
      ticketId: doc.id,
      passengerName: data['passengerName'] ?? '',
      busNumber: data['busNumber'] ?? '',
      routeName: data['routeName'] ?? '',
      fare: (data['fare'] ?? 0).toDouble(),
      status: data['status'] ?? 'VALID',
      purchaseTime: (data['purchaseTime'] as Timestamp).toDate(),
    );
  }
}