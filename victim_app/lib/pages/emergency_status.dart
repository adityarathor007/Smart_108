import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_108/components/status_components.dart';
import 'package:smart_108/pages/home.dart';
import 'package:smart_108/pages/main_screen.dart';

class EmergencyStatusPage extends StatelessWidget {
  final String requestId;
  const EmergencyStatusPage({super.key,required this.requestId});

  Future<void> _cancelAndDeletingRequest(BuildContext context) async {
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFBADFDB),
      appBar: AppBar(
        title: const Text("Emergency Status"),
        // backgroundColor: const Color(0xFF2C5E67),
        backgroundColor: Colors.transparent,
        // automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2596be)),
          onPressed: () {
            // reset navigation and going back to home screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false,
            );
          },
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
          .collection('emergency_requests')
          .doc(requestId)
          .snapshots(),

        builder: (context, snapshot){
          if(snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if(!snapshot.hasData || !snapshot.data!.exists){
            return const Center(child: CircularProgressIndicator());
          }
          // get data from the snapshot
          var data=snapshot.data!.data() as Map<String,dynamic>;
          String status = data['status'] ?? 'pending';

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                buildStatusHeader(status),
                const SizedBox(height: 30),
                buildRequestSummary(data),
                const Spacer(),
                // if(status=='assigned') buildResponderCard(data),
                _buildCancelButton(context)

              ],
            )
          );
        },

        )
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _cancelAndDeletingRequest(context),
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


}
