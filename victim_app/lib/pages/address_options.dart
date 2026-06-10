import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_108/pages/LocationPicker.dart';
import 'package:smart_108/pages/detailed_address_overlay.dart';
import 'package:smart_108/utils/address_helper.dart';

class SelectLocationScreen extends StatefulWidget {
  final String selectedService;
  const   SelectLocationScreen({super.key,required this.selectedService});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

    Future<void> _fetchAddresses() async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .orderBy('createdAt', descending: true)
            .limit(3)
            .get();

        setState(() {
            _addresses = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // ← Add document ID
            return data;
            }).toList();
            _isLoading = false;
        });
    }

    void _showSavedAddressOverlay(Map<String, dynamic> addressData, String addressId) {
        final String tag = addressData['tag'] ?? 'Address';
        final String referenceAddress = addressData['referenceAddress'] ?? '';
        final String flatNo = addressData['flatNo'] ?? '';
        final String floorNo = addressData['floorNo'] ?? '';
        final String landmark = addressData['landmark'] ?? '';

        final Map<String, dynamic> location = addressData['location'] as Map<String, dynamic>;
        final String city=addressData['city'] ?? '';
        final double lat = location['lat'] as double;
        final double lng = location['lng'] as double;

        final LatLng savedLatLng = LatLng(lat, lng);

        showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DetailedAddressOverlay(
            isFromSavedAddress: true,
            savedTitle: tag,
            flatNo: flatNo,
            floorNo: floorNo,
            landmark: landmark,
            currentMapCenter: savedLatLng,
            service: widget.selectedService,
            mapAddress: referenceAddress,
            city: city,
        ),
        );
    }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFE0F7F4,
      ), // Light mint background from design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF8B1D1D)),
        title: const Text(
          "Select Location",
          style: TextStyle(
            color: Color(0xFF1A1C24),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            //1. add address
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LiveLocationPickerPage(
                      selectedService: widget.selectedService,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A49E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Set pickup location",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Choose on map or search address",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. Saved addresses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "SAVED ADDRESSES",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "VIEW ALL",
                    style: TextStyle(
                      color: Color(0xFF4A49E8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // 4. Saved Addresses List
            _buildSavedAddressesSection(),
          ],
        ),
      ),
    );
  }


  Widget _buildSavedAddressesSection() {

  if (_addresses.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        "No saved addresses yet",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  return Column(
    children: _addresses.map((data) {
    final String addressId = data['id'] ?? '';

      return _buildSavedAddressTile(
        addressData: data,
        addressId: addressId,
      );
    }).toList(),
  );
}

  Widget _buildSavedAddressTile({
    required Map<String, dynamic> addressData,
    required String addressId,
  }) {
    final String tag = addressData['tag'] ?? 'Address';
    final String referenceAddress = addressData['referenceAddress'] ?? '';
    final bool isPrimary = addressData['isPrimary'] ?? false;

    return InkWell(
        onTap: () => _showSavedAddressOverlay(addressData, addressId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
            children: [
            CircleAvatar(
                backgroundColor: getIconColor(tag).withValues(alpha: 0.1),
                child: Icon(getIcon(tag), color: getIconColor(tag)),
            ),
            const SizedBox(width: 15),
            Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                    children: [
                        Text(
                        tag,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                        ),
                        ),
                        if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                            ),
                            decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                            "PRIMARY",
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                            ),
                            ),
                        ),
                        ],
                    ],
                    ),
                    Text(
                    referenceAddress,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    ),
                ],
                ),
            ),
            ],
        ),
        ),
    );
  }
}
