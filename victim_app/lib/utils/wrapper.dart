// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_108/pages/noAccess.dart';
import 'package:smart_108/pages/login.dart';
import 'package:smart_108/pages/main_screen.dart';
import 'package:smart_108/pages/verifyEmail.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> checkUserAccess(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) { //as soon there is any authStateChange this function trigger
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData) {
          return const LoginPage();
        }

        final user = authSnapshot.data!;

        return FutureBuilder<bool>(
          future: checkUserAccess(user.uid),
          builder: (context, accessSnapshot) {
            if (accessSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!accessSnapshot.hasData) {
              return const NoAccessPage();
            }

            if (!user.emailVerified) {
              return const VerifyEmailPage();
            }

            return const MainScreen();
          },
        );
      },
    );
  }
}
