import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_108/utils/auth_service.dart';

class NoAccessPage extends StatelessWidget {
  const NoAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFBADFDB),
      appBar: AppBar(
        title: const Text(
          "Access Restricted",
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await AuthService().signOut();
        },
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        backgroundColor: Colors.redAccent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.info_outline, size: 80),
              SizedBox(height: 24),
              Text(
                "This email is registered in the responder's app.\n"
                "Kindly create a new email ID to use this app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
