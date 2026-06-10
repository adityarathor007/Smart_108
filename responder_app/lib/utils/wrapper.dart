// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_108_responders/pages/login.dart';
import 'package:smart_108_responders/pages/mainScreen.dart';
import 'package:smart_108_responders/pages/noAccess.dart';
import 'package:smart_108_responders/pages/verifyEmail.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> checkUserAccess(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('responders')
        .doc(uid)
        .get();
    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
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

            // if (!accessSnapshot.hasData || accessSnapshot.data == false) {
            //   return const NoAccessPage();
            // }

            // !!!!!!!!!!! DISABLING THE VERIFY PAGE OF THIS APP SO THAT I CAN BRING MORE RESPONDERS !!!!!!!!!!!
            // if (!user.emailVerified) {
            //   return const VerifyEmailPage();
            // }

            return const MainScreen();
          }
        );
      }
    );
  }
}
