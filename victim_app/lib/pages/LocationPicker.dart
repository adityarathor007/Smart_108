import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:smart_108/pages/detailed_address_overlay.dart';
import 'package:smart_108/utils/location_services.dart';
import 'package:smart_108/utils/marker_dialog_box.dart';

// const String kGoogleApiKey = "<api_key>";  //used for suggestions for the places being searched in search bar

class LiveLocationPickerPage extends StatefulWidget {
  final String selectedService;

  const LiveLocationPickerPage({
    super.key,
    required this.selectedService,
  });

  @override
  State<LiveLocationPickerPage> createState() => _LiveLocationPickerPageState();
}

class _LiveLocationPickerPageState extends State<LiveLocationPickerPage> {
  late LatLng _currentMapCenter;
  MapType _currentMapType = MapType.normal;
  String? _currentAddress;
  String? _city;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  GoogleMapController? _mapController;

 @override
  void initState() {
    super.initState();
    // 2. Fetch Position to get live location
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      Position position = await LocationServices.determinePosition();
      setState(() {
        _currentMapCenter = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      // After getting coordinates, you can also trigger reverse geocoding here
      _getAddressFromLatLng(_currentMapCenter!);
    } catch (e) {
      // Handle permission denied or GPS off
      debugPrint("Error fetching location: $e");
    }
  }

  @override
  void dispose() {
    _flatController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }


  void _showAddressOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to expand with the keyboard
      backgroundColor:
          Colors.transparent, // Required for custom rounded corners
      builder: (context) => DetailedAddressOverlay(currentMapCenter: _currentMapCenter, service: widget.selectedService, mapAddress: _currentAddress ?? "Fetching address...",city: _city ?? ""),
    );
  }

//  Reverse-geocode the center point
  Future<void> _getAddressFromLatLng(LatLng? position) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position!.latitude,
      position.longitude,
    );

    Placemark place = placemarks[0];

    setState(() {
      // You can customize this format
      _currentAddress = "${place.street} ${place.subLocality}, ${place.locality}, ${place.administrativeArea} - ${place.postalCode}";
      _city="${place.locality}";
    //   print(place);
    });
  } catch (e) {
    setState(() {
      _currentAddress = "Could not fetch address details";
    });
  }
}

//   void _onCameraIdle() async {
//     print(
//       "User stopped at: ${_currentMapCenter.latitude}, ${_currentMapCenter.longitude}",
//     );
//     // Here we will eventually call the Geocoding API to get the address
//   }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.hybrid
          ? MapType.normal
          : MapType.hybrid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : Stack(
        children: [
          //1. MAP LAYER
          GoogleMap(
            initialCameraPosition: CameraPosition(
                target: _currentMapCenter,
                zoom: 17
            ),
            onCameraMove: (position) {
              _currentMapCenter =position.target;
            },
            onCameraIdle: () => _getAddressFromLatLng(_currentMapCenter),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: _currentMapType,
            onMapCreated: (controller) => _mapController = controller,
          ),

          //2. The back button and Search Bar
          _buildBackButtonAndSearchBar(context),

          // 3. THE STATIONARY PIN(does not move just the map moves and center position of the map is reverse_geoencoded when the camera comes to stop) with dialog box
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 75,
              ), // Adjust to align the "point" of the pin
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. THE DIALOG BOX (The Label)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF1A1C24,
                      ), // Dark theme like Zomato/Uber
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Move marker to set location",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // 2. THE LITTLE TRIANGLE (Optional: Creates the 'speech bubble' look)
                  RotatedBox(
                    quarterTurns: 4,
                    child: CustomPaint(
                      size: const Size(10, 6),
                      painter: TrianglePainter(
                        color: const Color(0xFF1A1C24),
                      ),
                    ),
                  ),

                  // 3. YOUR PIN IMAGE
                  Image.asset(
                    'assets/markers/my_marker.png',
                    width: 60, // Slightly smaller looks more professional with a label
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),

          //4. The Toogle that switchs between satellite view and default view
          Positioned(
            bottom: 240,
            right: 5,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _toggleMapType,
              tooltip: _currentMapType == MapType.normal
                  ? 'Switch to Satellite View'
                  : 'Switch to Default View',
              child: Icon(
                _currentMapType == MapType.normal
                  ? Icons.layers_outlined
                  : Icons.layers,
                color: Color(0xFF2C5E67)),
            ),
          ),

          //5. Button to move to the current location
          Positioned(
              bottom: 240,
              right: 110,
              child: FloatingActionButton.extended(
                onPressed: () async {

                  Position position = await LocationServices.determinePosition();
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(position.latitude, position.longitude),
                      17,
                    ),
                  );
                },
                // The Row-like layout
                icon: const Icon(Icons.my_location, color: Colors.red, size: 18),
                label: const Text(
                  "Use current location",
                  style: TextStyle(
                    color: Colors.red, // Matching text to border
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: Colors.white,
                elevation: 2,
                // THE CURVED RED BORDER LOGIC
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Adjust for "rectangle with curves"
                  side: const BorderSide(
                    color: Colors.red, // Red highlighted border
                    width: 1.5,        // Border thickness
                  ),
                ),
              ),
          ),

          //6. BOTTOM Address for the marker
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const SizedBox(height: 10),

                        //Service Indicator
                        Row(
                            children:[
                                const Icon(Icons.emergency, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                    "CONFIRM ${widget.selectedService.toUpperCase()} LOCATION",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                )
                            ]
                        ),

                        const SizedBox(height: 20),

                        //The Automatically fetched address
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const Icon(Icons.location_on, color: Color(0xFF2C5E67)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        _currentAddress ?? "Locating...",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    )
                                )
                            ],
                        ),

                    const SizedBox(height: 20),

                    SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                            // onPressed:_submitEmergencyRequest,
                            onPressed:() => _showAddressOverlay(context),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C5E67),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Add more address details",
                                style: TextStyle(color: Colors.white, fontSize: 16))
                        )
                    ),

                    const SizedBox(height: 30),
                  ],
              )
          )
          )]
      )
    );
  }

  Widget  _buildBackButtonAndSearchBar(BuildContext context) {
    return Positioned(
      top: 50,                    // Adjust if needed (safe from status bar)
      left: 15,
      right: 15,
      child: Row(
        children: [
          // 1. Back Button (Left)
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1A1C24),
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),   // Space between back button and search bar

          // 2. Search Bar (Takes remaining space)
          Expanded(
            child: GooglePlacesAutoCompleteTextFormField(
              textEditingController: _searchController,
              config: GoogleApiConfig( //for sending the typed text to the google places automcomplete api
                apiKey: kGoogleApiKey, // Your Google API Key
                countries: ["in"], // Restrict to India (change if needed)
                debounceTime: 600, // milliseconds to avoid many request send at once
                fetchPlaceDetailsWithCoordinates:
                    true, // Important: to get lat/lng
              ),
              decoration: InputDecoration(
                hintText: "Search location",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),

              // Called after coordinates are received for the selected location
              onPredictionWithCoordinatesReceived: (prediction) async {
                // prediction.lat and prediction.lng are String?
                final String? latStr = prediction.lat;
                final String? lngStr = prediction.lng;

                if (latStr != null && lngStr != null) {
                  try {
                    final double lat = double.parse(latStr);
                    final double lng = double.parse(lngStr);

                    final newLatLng = LatLng(lat, lng);

                    // Move the map to the selected location
                    await _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: newLatLng, zoom: 17),
                      ),
                    );

                    // Update your center variable
                    _currentMapCenter = newLatLng;

                    // Clear the search bar text (Important for good UX)
                    _searchController.clear();

                    // Manually trigger reverse geocoding (important!)
                    _getAddressFromLatLng(newLatLng);

                    if(!context.mounted) return;
                    // Optional: Remove keyboard focus
                    FocusScope.of(context).unfocus();
                  } catch (e) {
                    print("Error parsing lat/lng: $e");
                    // You can show a snackbar here if parsing fails
                  }
                } else {
                  print("Latitude or Longitude is null");
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
