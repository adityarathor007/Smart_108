import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Widget buildStatusHeader(String status){
  return Column(
    children: [
      //pulsing icon logic
      CircleAvatar(
        radius: 40,
        backgroundColor: status == 'pending' ? Colors.orange.shade100 : Colors.green.shade100,
        child: Icon(
          status == 'pending' ? Icons.hourglass_empty : Icons.check_circle,
          size: 50,
          color: status == 'pending' ? Colors.orange : Colors.green,
        )
      ),

      const SizedBox(height:10),
      Text(
        status=='pending' ? "Waiting for Dispatcher...":"Responder Assigned",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      )
    ]
  );
}

Widget buildRequestSummary(Map<String,dynamic> data){
  return Card(
    child: ListTile(
      title: Text("Service: ${data['serviceType']}"),
      subtitle: Text("House/Flat No.: ${data['flatNo']}\nLandmark: ${data['landmark']}\nAddress: ${data['referenceAddress']}"),
    ),
  );
}
