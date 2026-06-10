import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyRequestStream extends StatelessWidget {
  final String city;
  final String status;
  // Define the callback function
  final Function(String id, Map<String,dynamic> data) onLocationSelected;
  const EmergencyRequestStream({
    super.key,
    required this.city,
    required this.status,
    required this.onLocationSelected
    });

  @override
  Widget build(BuildContext context) {
    // print(city);
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_requests')
            .where('city', isEqualTo: city)
            .where('status',isEqualTo: status)
            .snapshots(),
        builder: (context,snapshot){
          // print(snapshot);
          if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs=snapshot.data!.docs;
          // If no active emergencies
          if(docs.isEmpty) return Center(child: Text("No active emergencies in $city"));

          //Else return the list
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context,index){
              var data=docs[index].data() as Map<String,dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(data['serviceType'] ?? "Emergency"),
                  subtitle: Text("House/FlatNo.: ${data['flatNo']}\nLandmark: ${data['landmark']}\nAddress: ${data['referenceAddress']}\nStatus: ${data['status']}"),
                  onTap: (){
                    //Logic to center the map on this location

                    onLocationSelected(docs[index].id, data);
                  }
                )
              );
            }
          );

        }

      );
  }
}
