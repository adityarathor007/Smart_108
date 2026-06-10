import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:smart_108/utils/logger.dart';

Widget buildReqSummaryUI(
  Map<String, dynamic> data,
  BuildContext context,
  String serviceType,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 2. Header: "YOUR REQUEST DETAILS" + timestamp
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "YOUR REQUEST DETAILS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            "Sent ${TimeOfDay.fromDateTime((data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()).format(context)}",
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),

      const SizedBox(height: 16),

      // 3. Main card
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Victim Name Row
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(Icons.person, color: Color(0xFF26A69A), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "VICTIM NAME",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      data['victimName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 24, color: Color(0xFFEEEEEE)),

            // Emergency Type + Phone Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "EMERGENCY",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.medical_services,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                serviceType,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PHONE",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black45,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['victimPhone'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24, color: Color(0xFFEEEEEE)),

            // Detailed Address
            const Text(
              "DETAILED ADDRESS",
              style: TextStyle(
                fontSize: 9,
                color: Colors.black45,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFF26A69A),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                              data['floorNo'],
                              data['flatNo'],
                              data['referenceAddress'],
                            ]
                            .where(
                              (e) =>
                                  e != null && (e as String).trim().isNotEmpty,
                            )
                            .join(', '),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (data['landmark'] != null &&
                          (data['landmark'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "Landmark: ${data['landmark']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF26A69A),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

Future<String> fetchETA(LatLng origin, LatLng destination) async {
  const apiKey = 'AIzaSyAB6ETR9TOC0rDfy4MSqp0APJ3456FP6ic'; //IMP using API KEY
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/directions/json'
    '?origin=${origin.latitude},${origin.longitude}'
    '&destination=${destination.latitude},${destination.longitude}'
    '&key=$apiKey',
  );

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['routes'].isNotEmpty) {
      final duration = data['routes'][0]['legs'][0]['duration']['text'];
      logger.d(duration);
      return duration; // e.g. "4 mins"
    }
  }
  return 'N/A';
}



  Future<void> _cancelAndDeletingRequest(BuildContext context, String requestId) async {
    try {
      //1. Ask for conformation
      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Cancel your request?"),
          content: const Text(
            "This will remove your request from our system. Are you sure?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("NO"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "YES CANCEL",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      await FirebaseFirestore.instance
          .collection('emergency_requests')
          .doc(requestId)
          .delete();

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Emergency request cancelled")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error cancelling: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

Widget buildCancelButton(BuildContext context,String requestId) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _cancelAndDeletingRequest(context,requestId),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text(
          "CANCEL REQUEST",
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}
