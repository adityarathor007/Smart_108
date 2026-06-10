import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_108_responders/theme/app_colors.dart';

class RequestDetailsScreen extends StatelessWidget {
  final String requestId;
  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Request Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.iconColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('emergency_requests')
            .doc(requestId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailItem("Status", data['status']),
                _detailItem("Victim Address", data['referenceAddress'] ?? "N/A"),
                _detailItem("Requested At", _formatDate(data['timestamp'])),
                _detailItem("Arrived At", _formatDate(data['arrivalTime'])),
                _detailItem("Completed At", _formatDate(data['completionTime'])),
                // You could add a mini Google Map here too!
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.iconColor,
            ),
          ),
          Text(value.toString(), style: const TextStyle(fontSize: 16,color: Colors.white)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    return DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format((timestamp as Timestamp).toDate());
  }
}
