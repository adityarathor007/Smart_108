import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestCompletionScreen extends StatelessWidget {
  final String requestId;

  const RequestCompletionScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFBADFDB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Summary',
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_requests')
            .doc(requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Extract fields
          final responderName = data['responderName'] ?? 'Unknown';
          final phone = data['responderPhone'] ?? 'N/A';
          final vehicleNumber = data['vehicleNumber'];

          // Format completion time
          final completedAt = (data['completionTime'] as Timestamp?)?.toDate();
          final completionDateTime = completedAt != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(completedAt)
              : 'N/A';

          final String vname=data['victimName'] ?? 'N/A';
          final String serviceType = data['serviceType'] ?? 'N/A';
          final String? vphone = data['victimPhone'];
          final String? floorNo = data['floorNo'];
          final String? flatNo = data['flatNo'];
          final String referenceAddress = data['referenceAddress'] ?? '';
          final String? landmark = data['landmark'];

          final raisedAt = (data['timestamp'] as Timestamp?)?.toDate();
          final raisedReqDateTime = raisedAt != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(raisedAt)
              : 'N/A';


          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Request Completed Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Emergency Request Resolved',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 2. Assigned Responder Label
                const Text(
                  'Responder Details',
                  style: TextStyle(
                    color: Color(0xFF26A69A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),

                const SizedBox(height: 15),

                // 4. Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // 3. Responder Name
                      Text(
                        responderName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 20),


                      _buildDetailRow(
                        icon: Icons.phone,
                        iconColor: const Color(0xFF26A69A),
                        value: phone,
                      ),

                      const SizedBox(height: 24),

                      _buildDetailRow(
                        icon: Icons.access_time,
                        iconColor: const Color(0xFF26A69A),
                        label: 'Completion Time:',
                        value: completionDateTime,
                      ),

                      const SizedBox(height: 24),

                      // Vehicle number row — only shown if present
                      if (vehicleNumber != null &&
                          (vehicleNumber as String).trim().isNotEmpty) ...[
                        const Divider(color: Color(0xFF2E3447), height: 24),
                        _buildDetailRow(
                          icon: Icons.pin,
                          iconColor: const Color(0xFF26A69A),
                          label: 'Vehicle No:',
                          value: vehicleNumber,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Victims Details',
                  style: TextStyle(
                    color: Color(0xFF26A69A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),

                const SizedBox(height: 15),

                _buildVictimSection(name: vname,serviceType:serviceType,phone:vphone,
                  raisedReqDateTime: raisedReqDateTime,floorNo:floorNo,referenceAddress: referenceAddress,flatNo:flatNo,landmark:landmark)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    String? label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 12),
        if (label != null)
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        if (label != null) const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


Widget _buildVictimSection({required String name,required String serviceType,String? phone,required String raisedReqDateTime,String? floorNo, String? flatNo, required String referenceAddress, String? landmark}){

  return Container(
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
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const Text(
                    //   "VICTIM NAME",
                    //   style: TextStyle(
                    //     fontSize: 10,
                    //     color: Colors.black45,
                    //     fontWeight: FontWeight.w600,
                    //     letterSpacing: 0.8,
                    //   ),
                    // ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                    phone ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
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
                        "Raised At",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black45,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        raisedReqDateTime   ,
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
                              floorNo,
                              flatNo,
                              referenceAddress,
                            ]
                            .where(
                              (e) =>
                                  e != null && (e).trim().isNotEmpty,
                            )
                            .join(', '),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (landmark != null &&
                          (landmark).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "Landmark: ${landmark}",
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
    );
  }
}
