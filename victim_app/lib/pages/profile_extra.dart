import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_108/components/profile_view.dart';
import 'package:smart_108/utils/auth_service.dart';
import 'package:smart_108/utils/logger.dart';

class ProfileExtraScreen extends StatelessWidget {
  const ProfileExtraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final isProfileCompleted = userData['profile_completed'] ?? false;

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: Column(
            children: [
              if (!isProfileCompleted) _ProfileIncompleteBanner(),

              ProfileView(userData: userData),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
    );
  }
}

class _ProfileIncompleteBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your profile is incomplete. Complete it to unlock all features.',
            ),
          ),
          TextButton(
            onPressed: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            //   );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}









//old code

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // This checks if there is an active dialog/spinner and closes it
//       // without popping the actual Home Page.
//       if (Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }
//     });

//     final user = FirebaseAuth.instance.currentUser;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7F8),
//       appBar: AppBar(
//         title: const Text(
//           "User Dashboard",
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: const Color(0xFF2596be),
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: FutureBuilder<DocumentSnapshot>(
//         // Fetch the specific user's document from Firestore
//         future: FirebaseFirestore.instance
//             .collection('users')
//             .doc(user?.uid)
//             .get(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           // logger.d("Snapshot: $snapshot");

//           if (snapshot.hasError ||
//               !snapshot.hasData ||
//               !snapshot.data!.exists) {
//             return const Center(child: Text("Error loading profile details"));
//           }


//           // Extract data from the document
//           var userData = snapshot.data!.data() as Map<String, dynamic>;

//           // Navigator.pop(context);

//           return Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "Welcome back,",
//                   style: TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//                 Text(
//                   userData['full_name'] ?? 'User',
//                   style: const TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF2596be),
//                   ),
//                 ),
//                 const SizedBox(height: 30),

//                 // USER DETAILS CARD
//                 _buildInfoCard(
//                   title: "Emergency Profile",
//                   items: [
//                     {
//                       "label": "Phone",
//                       "value": userData['phone_number'] ?? 'N/A',
//                       "icon": Icons.phone,
//                     },
//                     {
//                       "label": "Email",
//                       "value": userData['email'] ?? 'N/A',
//                       "icon": Icons.email,
//                     },
//                     {
//                       "label": "Blood Group",
//                       "value": userData['blood_group'] ?? 'Not Set',
//                       "icon": Icons.water_drop,
//                     },
//                     {
//                       "label": "Role",
//                       "value": userData['role'].toString().toUpperCase(),
//                       "icon": Icons.security,
//                     },
//                   ],
//                 ),
//               ],
//             ),
//           );
//         },
//       ),

//       // FLOATING SIGNOUT BUTTON
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           await AuthService().signOut();
//           // After signing out, the AuthWrapper in main.dart will
//           // automatically take the user back to the LoginPage.
//         },
//         backgroundColor: Colors.redAccent,
//         icon: const Icon(Icons.logout, color: Colors.white),
//         label: const Text("Sign Out", style: TextStyle(color: Colors.white)),
//       ),
//     );
//   }

//   // UI Helper for the Info Card
//   Widget _buildInfoCard({
//     required String title,
//     required List<Map<String, dynamic>> items,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//           const Divider(height: 25),
//           ...items
//               .map(
//                 (item) => Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: Row(
//                     children: [
//                       Icon(
//                         item['icon'],
//                         size: 20,
//                         color: const Color(0xFF009688),
//                       ),
//                       const SizedBox(width: 15),
//                       Text(
//                         "${item['label']}: ",
//                         style: const TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                       Text(
//                         item['value'],
//                         style: const TextStyle(color: Colors.black87),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//         ],
//       ),
//     );
//   }
// }
