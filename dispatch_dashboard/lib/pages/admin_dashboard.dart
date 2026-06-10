import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? adminCity;
  bool _isLoading = true;

  @override
  void initState(){
    super.initState();
    _loadAdminData();
  }

  // Fetch the current admin's assigned city
  Future<void> _loadAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      setState(() {
        adminCity = doc.data()?['administered_city'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel: $adminCity'),
        actions:[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:() async {
                 await FirebaseAuth.instance.signOut();
                 Navigator.pushReplacementNamed(context, '/login');
            }
          )
        ]
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
                .collection('dispatchers')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
        builder: (context, snapshot){
          if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs=snapshot.data!.docs;
          if(docs.isEmpty) return const Center(child: Text("No pending registrations."));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index){
              var dispatcher = docs[index];
              return Card(
                child: ListTile(
                  title: Text(dispatcher['name']),
                  subtitle: Text(dispatcher['email']),
                  trailing: ElevatedButton(
                    onPressed: () => _approveDispatcher(dispatcher.id),
                    child: const Text('Approve and Assign'),
                  )
                )
              );
            }
          );
        }
        )
    );
  }
  Future<void>  _approveDispatcher(String id) async {
    await FirebaseFirestore.instance.collection('dispatchers').doc(id).update({
      'status': 'active',
      'assigned_city': adminCity, // Binds them to this Admin's city
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dispatcher approved successfully!")),
    );
  }
}
