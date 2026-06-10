import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_108/pages/emergency_status.dart';
import 'package:smart_108/pages/live_emergency_status.dart';
import 'package:smart_108/pages/live_tracking.dart';
import 'package:smart_108/pages/request_completion.dart';

class RequestHistoryPage extends StatelessWidget {
  const RequestHistoryPage({super.key});

  // Helper to color-code the status
  // Widget _getStatusIcon(String status) {
  //   Color color;
  //   switch (status) {
  //     case 'pending':
  //       color = Colors.orange;
  //       break;
  //     case 'assigned':
  //       color = Colors.blue;
  //       break;
  //     case 'en-route':
  //       color = Colors.green;
  //       break;
  //     case 'completed':
  //       color = Colors.grey;
  //       break;
  //     default:
  //       color = Colors.black;
  //   }
  //   return Icon(Icons.circle, color: color, size: 12);
  // }

  String _getMonth(DateTime date){
    List months=[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return months[date.month-1];
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = const Color(0xFFFFEBD2); // Light orange
        textColor = const Color(0xFFD48A28); //Darker orange
      case 'assigned':
        bgColor = const Color(0xFFD1F2F2); // Light blue
        textColor = const Color(0xFF4A9090); // Darker blue
        break;
      case 'completed':
        bgColor = const Color(0xFFD1FADF); // Light green
        textColor = const Color(0xFF2E7D32); // Darker green
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Color(0xFFBADFDB),
      appBar: AppBar(
        title: const Text("My Emergency Requests"),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2596be)),
          onPressed: () {
            // Manually trigger the pop to return to the Login Screen
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
          .collection('emergency_requests')
          .where('userId', isEqualTo: currentUserId)
          // .orderBy('timestamp', descending: true)
          .snapshots(),

        builder: (context,snapshot){
          if(snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator());
          }

          if(snapshot.data!.docs.isEmpty){
            return const Center(child: Text("No requests found."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context,index){
              var doc = snapshot.data!.docs[index];
              var request = doc.data();
              String status = request['status'] ?? 'pending';
              String service = request['serviceType'] ?? 'Emergency';
              String requestId = doc.id;
              // print(request['timestamp']);

              return GestureDetector(
                onTap: (){
                  if(status=="completed"){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestCompletionScreen(
                          requestId: requestId,
                        ),
                      ),
                    );
                  }
                  else{
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LiveTracking(
                          requestId: requestId,
                          fromEmergencyFlow: false,
                        ),
                      ),
                    );
                  }

                },

                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0,4),
                      )
                    ]
                  ),

                 child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Row1: Emergency Type
                    Row(
                      children: [
                        const Text("Emergency: ", style: TextStyle(fontSize: 16,color: Colors.grey)),
                        Text(
                          service[0].toUpperCase() + service.substring(1),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C5E67)),
                        )
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Row 2: Status Chip
                  Row(
                    children: [
                      const Text("Status: ",style: TextStyle(fontSize: 16, color: Colors.grey)),
                      _buildStatusChip(status),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 3: Date
                  Row(
                        children: [
                          const Text(
                            "Date: ",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            request['timestamp'] != null
                                ? "${_getMonth(request['timestamp'].toDate())} ${request['timestamp'].toDate().day}, ${request['timestamp'].toDate().year}"
                                : "Just now",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),




                  ],
                 )

                )

              );

              // return Card(
              //   margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              //   child: ListTile(
              //     leading: _getStatusIcon(status),
              //     title: Text("Emergency: ${request['serviceType'].toString().toUpperCase()}"),
              //     subtitle: Text("Status: ${status.toUpperCase()}\nDate: ${request['timestamp']?.toDate()}"),
              //     trailing: (status == 'assigned' || status == 'en-route'|| status == 'pending')
              //       ? ElevatedButton(
              //         onPressed: () {//Navigate to Live Tracking map
              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //               builder: (context) =>
              //                   EmergencyStatusPage(requestId: requestId),
              //             ),
              //           );
              //           },
              //         child: const Text("Track"),
              //       )
              //     : const Icon(Icons.arrow_forward_ios, size: 14)
              //   )
              // );

            }
          );
        }
      )
    );
  }
}
