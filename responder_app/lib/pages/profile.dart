import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot, FirebaseFirestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_108_responders/components/profile_card.dart';
import 'package:smart_108_responders/utils/authService.dart';

class ProfileScreen extends StatefulWidget {
  // Change to StatefulWidget
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {


  Future<void> updateFirestore(String field, String newValue) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // --- ASYNC GAP STARTS HERE ---
      await FirebaseFirestore.instance.collection('responders').doc(uid).update({
        field: newValue,
      });
      // --- ASYNC GAP ENDS HERE ---

      // Check if the user is still looking at this screen!
      if (!mounted) return;

      // Now it is safe to use context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${field.replaceAll('_', ' ')} updated!")),
      );
    } catch (e) {
      if (!mounted) return; // Check again here just in case

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('responders')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: Color(0xFF121A1F),

          //screen heading
          appBar: AppBar(
            title: Text(
              "Profile",
              style: TextStyle(
                color: Color(0xFFFF6500),
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            leading: BackButton(color: Color(0xFFFF6500)),
            // leading: IconButton(
            //     icon: const Icon(
            //       Icons.arrow_back_ios_new,
            //       color: Color(0xFF2596be),
            //     ),
            //     onPressed: () {
            //       // Manually trigger the pop to return to the Login Screen
            //       Navigator.pop(context);
            //     },
            //   ),
          ),

          //body
          body: SingleChildScrollView(
            child: Column(
              children: [
                //Profile Image section
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white,
                        backgroundImage: userData['profile_base64'] != null
                            ? MemoryImage(
                                base64Decode(userData['profile_base64']),
                              )
                            : null, // No background image if the string is null
                        child: userData['profile_base64'] == null
                            ? Text(
                                userData['full_name'] != null &&
                                        userData['full_name'].isNotEmpty
                                    ? userData['full_name'][0].toUpperCase()
                                    : '?', // Show '?' if name is also missing for some reason
                                style: const TextStyle(fontSize: 24, color: Colors.black),
                              )
                            : null,
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          String? error = await AuthService()
                              .uploadProfilePictureBase64();
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 35,
                          width: 35,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6500),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                //PROFILE DESC
                // buildProfileCard(
                //   'Full Name',
                //   userData['full_name'] ?? '-',
                //   Icons.person,
                // ),
                InlineEditCard(
                  label: 'FULL NAME',
                  value: userData['full_name'] ?? '-',
                  icon: Icons.person_outline,
                  isEditable: true,
                  onSave: (newValue) => updateFirestore('full_name', newValue),
                ),

                InlineEditCard(
                  label: 'EMAIL',
                  value: userData['email'] ?? '-',
                  icon: Icons.email_outlined,
                  isEditable: false, // The pencil icon will disappear
                ),

                InlineEditCard(
                  label: 'PHONE',
                  value: userData['phone_number'] ?? '-',
                  icon: Icons.phone_outlined,
                  isEditable: true,
                  onSave: (newValue) =>
                      updateFirestore('phone_number', newValue),
                ),

                InlineEditCard(
                  label: 'SERVICE TYPE',
                  value: userData['serviceType'] ?? '-',
                  icon: Icons.person_outline,
                  isEditable: false, // The pencil icon will disappear
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout, color: Color(0xFFFF6500)),
            label: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF404258),
          ),
        );
      },
    );
  }
}
