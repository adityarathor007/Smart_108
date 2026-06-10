import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_108_responders/utils/wrapper.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isResending = false;

  Future<void> checkVerificationStatus() async {
    // 1. Refresh the user's data from Firebase servers
    await FirebaseAuth.instance.currentUser?.reload();

    // 2. Get the refreshed user instance
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Email Verified!")));

        // 3. NUDGE: Force the app to re-evaluate the AuthWrapper
        //authStateChange() only  triggers when a users signs in, signs out, or the token changes. It does not know that user.emailVerified changed from false to true
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Still not verified. Check your inbox."),
          ),
        );
      }
    }
  }

  Future<void> sendVerificationLink() async {
    setState(() => isResending = true);

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Verification link sent!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => isResending = false);
  }

  Future<void> deleteAndGoBack() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // 1. Delete the Firestore document first
        await FirebaseFirestore.instance
            .collection('responders')
            .doc(user.uid)
            .delete();

        // 2. Delete the Auth account
        await user.delete();

        // // 3. Navigate back to Register Page
        // if (mounted) {
        //   Navigator.of(context).pushReplacementNamed('/register');
        // }
      }
    } catch (e) {
      // If the user hasn't logged in recently, Firebase might require re-authentication
      // to delete. In this case, just signing out is a safe fallback.
      await FirebaseAuth.instance.signOut();
      // if (mounted) Navigator.of(context).pushReplacementNamed('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121A1F),
      appBar: AppBar(
        title: const Text("Verify Email",style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 100,
              color: Color(0xFFFF6500),
            ),
            const SizedBox(height: 30),

            const Text(
              "A verification link has been sent to your email:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),

            const SizedBox(height: 10),

            // NEW: Displays the registered email id
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF404258),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                FirebaseAuth.instance.currentUser?.email ?? "your email",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Please verify your email id using that link to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),

            // const Text(
            //   "A verification link has been sent to your email. Please verify your email id using that",
            //   textAlign: TextAlign.center,
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)
            // ),
            const SizedBox(height: 40),

            //Primary Button: MANUAL CHECK
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: checkVerificationStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "I HAVE VERIFIED MY EMAIL",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            //Secondary Button: RESEND
            TextButton(
              onPressed: isResending ? null : sendVerificationLink,
              child: Text(
                isResending ? "Sending..." : "Resend Verification Link",
                style: const TextStyle(
                  color: Color(0xFFFF6500),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 5),

            //tertiary button for re entering the email id
            TextButton.icon(
              onPressed: deleteAndGoBack,
              icon: const Icon(Icons.edit, size: 18, color: Colors.white),
              label: const Text(
                "Entered the wrong email? Edit it here",
                style: TextStyle(color: Color(0xFFFF6500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
