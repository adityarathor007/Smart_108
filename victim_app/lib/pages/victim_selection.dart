import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_108/pages/add_victim.dart';
import 'package:smart_108/utils/address_helper.dart';

class VictimSelectionSheet extends StatefulWidget {
  final String currentUserId;
  final Profile currentUserProfile;
  final String? selectedVictimId;

  const VictimSelectionSheet({super.key,required this.currentUserId,required this.currentUserProfile, required this.selectedVictimId});

  @override
  State<VictimSelectionSheet> createState() => _VictimSelectionSheetState();
}

class _VictimSelectionSheetState extends State<VictimSelectionSheet> {
  String? _tempSelectedId;
  Profile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _tempSelectedId = widget.selectedVictimId;
    _selectedProfile = widget.currentUserProfile;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF7F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Victim",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context,"add_new"); //close selection sheet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text("+ Add New"),
                ),
              ],
            ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUserId)
                  .collection('saved_profiles')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // 🔥 Convert Firestore docs
                final profiles = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Profile.fromMap(data, doc.id);
                }).toList();

                // ✅ Add current user on top
                final allProfiles = [
                  widget.currentUserProfile,
                  ...profiles,
                ];

                return ListView.builder(
                  itemCount: allProfiles.length,
                  itemBuilder: (context, index) {
                    final profile = allProfiles[index];
                    final isSelected = _tempSelectedId == profile.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _tempSelectedId = profile.id;
                          _selectedProfile = profile;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            // 🔹 Name + Phone
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.isSelf
                                        ? "${profile.name} (You)"
                                        : profile.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(profile.phone),
                                ],
                              ),
                            ),

                            // 🔹 Small Blood Group
                            if (profile.bloodGroup != null &&
                                profile.bloodGroup!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  profile.bloodGroup!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // 🔹 Confirm Button (CENTERED)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
            onPressed: _selectedProfile == null
                  ? null
                  : () {
                      Navigator.pop(context, _selectedProfile);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Confirm Selection",
                style: TextStyle(fontSize: 16,color: Colors.white),

              ),
            ),
          )
          ],
        ),
    );
  }
}
