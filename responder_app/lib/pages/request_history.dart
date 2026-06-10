import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_108_responders/pages/request_details.dart';
import 'package:smart_108_responders/theme/app_colors.dart';
import 'package:smart_108_responders/utils/app_logger.dart';

class RequestHistoryScreen extends StatelessWidget {
  const RequestHistoryScreen({super.key});

  String _getMonth(DateTime date){
    List months=[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return months[date.month-1];
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Previous Requests", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.iconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('emergency_requests')
            .where('responderId', isEqualTo: uid)
            .where('status', isEqualTo: 'completed') // Only show finished tasks
            // .orderBy('completionTime', descending: true) // Newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("No completed requests found."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var request = doc.data();
              String reqId=doc.id;

              return GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                        RequestDetailsScreen(requestId: docs[index].id),
                      ),
                  );
                },

                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
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
                          const Text("Id: ", style: TextStyle(fontSize: 16,color: AppColors.iconColor)),
                          Text(
                            reqId,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        ],
                      ),

                      Row(
                        children: [
                          const Text(
                            "Date: ",
                            style: TextStyle(fontSize: 16, color: AppColors.iconColor),
                          ),
                          Text(
                            request['timestamp'] != null
                                ? "${_getMonth(request['timestamp'].toDate())} ${request['timestamp'].toDate().day}, ${request['timestamp'].toDate().year}"
                                : "Just now",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )

                    ]
                  )
                )
              );
            }
          );
        }
      )

    );
  }
}
