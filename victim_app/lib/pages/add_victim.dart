import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_108/utils/address_helper.dart';

class AddVictimSheet extends StatefulWidget {
  final String userId;

  const AddVictimSheet({super.key, required this.userId});

  @override
  State<AddVictimSheet> createState() => _AddVictimSheetState();
}

class _AddVictimSheetState extends State<AddVictimSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bloodController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final blood = _bloodController.text.trim();

    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _isSaving = true);

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('saved_profiles')
        .add({
            'name': name,
            'phone': phone,
            'bloodGroup': blood.isEmpty ? null : blood,
            'createdAt': FieldValue.serverTimestamp(),
        });

    final newProfile = Profile(
        id: docRef.id,
        name: name,
        phone: phone,
        bloodGroup: blood,
    );

    Navigator.pop(context, newProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF7F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add New Victim",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // 🔹 Name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Name",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Phone
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 Blood Group (Optional)
          TextField(
            controller: _bloodController,
            decoration: InputDecoration(
              labelText: "Blood Group (Optional)",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const Spacer(),

          // 🔹 Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save"),
            ),
          ),
        ],
      ),
    );
  }
}
