import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_108/pages/add_victim.dart';
import 'package:smart_108/pages/emergency_status.dart';
import 'package:smart_108/pages/live_tracking.dart';
import 'package:smart_108/pages/victim_selection.dart';
import 'package:smart_108/utils/address_helper.dart';
import 'package:smart_108/utils/logger.dart';

class DetailedAddressOverlay extends StatefulWidget {
  final bool isFromSavedAddress;
  final String? savedTitle;
  final LatLng currentMapCenter;
  final String? flatNo;
  final String? floorNo;
  final String? landmark;
  final String service;
  final String mapAddress;
  final String city;

  const DetailedAddressOverlay({
    super.key,
    this.isFromSavedAddress = false,
    this.savedTitle,
    this.flatNo,
    this.floorNo,
    this.landmark,
    required this.currentMapCenter,
    required this.service,
    required this.mapAddress,
    required this.city,
  });

  @override
  State<DetailedAddressOverlay> createState() => _DetailedAddressOverlayState();
}

class _DetailedAddressOverlayState extends State<DetailedAddressOverlay> {
  String? _selectedTag;
  String? _userName;
  String? _userPhone;
  String? _userId;
  Profile? _selectedVictim;
  bool _isDataLoading = true;
  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchUserData();

    // If it's a saved address, pre-fill the fields
    if (widget.isFromSavedAddress)  _preFillSavedAddressData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _userId = user.uid;
          _userName = doc.data()?['full_name'] ?? "User";
          _userPhone = doc.data()?['phone_number'] ?? "No number";

          _selectedVictim = Profile(
            id: user.uid,
            name: _userName!,
            phone: _userPhone!,
            isSelf: true,
          );

          _isDataLoading = false; // Stop the loader permanently for this session
        });
      }
    }
  }

  void _preFillSavedAddressData() {
    setState(() {
      _selectedTag = widget.savedTitle; // "Home", "Office", etc.

      // Pre-fill controllers
      _flatController.text = widget.flatNo ?? '';
      _floorController.text = widget.floorNo ?? '';
      _landmarkController.text = widget.landmark ?? '';
    });
  }

  @override
  void dispose() {
    _flatController.dispose();
    _floorController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final addressData = {
      'tag': _selectedTag ?? "Other", // you can make this dynamic later
      'referenceAddress': widget.mapAddress,
      'flatNo': _flatController.text.trim(),
      'floorNo': _floorController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'location': {
        'lat': widget.currentMapCenter.latitude,
        'lng': widget.currentMapCenter.longitude,
      },
      'city': widget.city,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .add(addressData);
  }

  Future<void> _submitEmergencyRequest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _isDataLoading) return  ;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create the request data
      final requestData = {
        'userId': user.uid,
        'victimName': _selectedVictim?.name ?? _userName ?? "-",
        'victimPhone': _selectedVictim?.phone ?? _userPhone ?? "-",
        'serviceType': widget.service,
        'status': 'pending', // <--- Your requested status
        'timestamp': FieldValue.serverTimestamp(),
        'referenceAddress': widget.mapAddress,
        'flatNo': _flatController.text.trim(),
        'floorNo': _floorController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'location': {
          'lat': widget.currentMapCenter.latitude,
          'lng': widget.currentMapCenter.longitude,
        },
        'city': widget.city,
        'responderId': null, // To be filled by dispatcher
      };

      // Save to Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('emergency_requests')
          .add(requestData);

      // IMP: Saving the address and checking that it is not the duplicate one which is saved
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .where('referenceAddress', isEqualTo: widget.mapAddress)
          .get();

      if (query.docs.isEmpty) {
        await _saveAddress();
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LiveTracking(requestId: docRef.id, fromEmergencyFlow: true),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

void _openVictimSelection(BuildContext context) async{
    Profile user_profile = Profile(
        id: _userId!,
        name: _userName!,
        phone: _userPhone!,
        isSelf: true,
    );
    final result = await showModalBottomSheet(
    context: context,
    builder: (_) => VictimSelectionSheet(
        currentUserId: _userId!,
        currentUserProfile: user_profile,
        selectedVictimId: _selectedVictim?.id,
    ),
    );

    if (result == "add_new") {
        final newProfile = await showModalBottomSheet<Profile>(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddVictimSheet(userId: _userId!),
        );

        if (newProfile != null) {
            setState(() {
            _selectedVictim = newProfile; // ✅ auto select
            });
        }
    }
    else if(result!=null){
        setState(() {
            _selectedVictim = result;
        });
    }
}

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator())
      );
    }
      return _buildUI(context);
    }


    Widget _buildUI(BuildContext context){
        return Container(
        // Padding ensures the content isn't hidden by the keyboard
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // 1. Header with Close Button
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Text(
                    widget.isFromSavedAddress ? "Verify the details" : "Enter complete address",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel, color: Colors.grey, size: 30),
                    ),
                ],
                ),
                const SizedBox(height: 10),

                const Text(
                "Victim Details",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                ),
                ),

                const SizedBox(height: 10),

                // 2. Victim Details
                Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFE0F7F4),
                    borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 8, right: 4),
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                                _selectedVictim?.isSelf == true
                                    ? "${_selectedVictim!.name} (You)"
                                    : _selectedVictim?.name ?? "Select Victim",
                                ),

                        subtitle: Text(_selectedVictim?.phone ?? "Tap to choose"),

                        trailing: IconButton(
                            icon: Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () {
                                _openVictimSelection(context);
                            },
                        ),
                    ),
                ),

                const SizedBox(height: 20),

                // 3. Tag this location (Home, Work, etc.)
                const Text(
                "TAG THIS LOCATION",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                ),
                ),
                const SizedBox(height: 10),
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                _buildTagChip("Home", Icons.home),
                _buildTagChip("Work", Icons.work),
                _buildTagChip("Other", Icons.more_horiz),
                ],
                ),

                const SizedBox(height: 20),

                _buildFixedAddressField(widget.mapAddress),

                const SizedBox(height: 15),
                Row(
                children: [
                    Expanded(
                    child: _buildTextField(
                        "House No./Flat No.(Optional)",
                        "e.g. House No. 1049",
                        1,
                        _flatController
                    ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                    child: _buildTextField(
                        "Floor No.(Optional)",
                        "e.g. 4th Floor",
                        1,
                        _floorController
                    ),
                    ),
                ],
                ),

                const SizedBox(height: 20),

            // 4. Input Fields (Flat, Floor, Landmark)
            _buildTextField("Landmark (Optional)", "e.g. Near Big B", 3,_landmarkController),

            const SizedBox(height: 25),

            // 5. Confirm Address Button
            SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                onPressed: _submitEmergencyRequest, //submitting the emergency request
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1D1D), // Dark Red
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    ),
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Text(
                        "Raise request",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                ),
                ),
            ),
            ],
        ),
        ),
    );
    }
    // Helper for Tags
  Widget _buildTagChip(String label, IconData icon) {
    bool isSelected = _selectedTag == label;

    return FilterChip(
      showCheckmark: false,
      label: Text(label),
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : Colors.black54,
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          // Update the state with the new selection
          _selectedTag = label;
        });
      },
      selectedColor: const Color(0xFF4A49E8), // Your primary purple/blue
      // checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFFE0F7F4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

   // Helper for Input Fields
  Widget _buildTextField(String label, String hint, int lines,TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFE0F7F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedAddressField(String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CONFIRMED LOCATION",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // The non-editable address box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(
              0xFFF0F4F4,
            ), // Slightly darker to show it's "locked"
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF8B1D1D), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // The helper text you requested
        const Text(
          "This is set according to the map marker",
          style: TextStyle(
            color: Colors.blueGrey,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
