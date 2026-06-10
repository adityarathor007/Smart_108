import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:smart_108_cc/utils/dp_dashboard.dart';
import 'package:google_maps_utils/google_maps_utils.dart';

// dictionary storing the city and their coordinates of their city center
final Map<String, LatLng> cityCenters = {
  'Jodhpur': const LatLng(26.2389, 73.0243),
  'Delhi': const LatLng(28.6139, 77.2090),
  'Bangalore': const LatLng(12.9716, 77.5946),
  'Bhopal': const LatLng(23.2599, 77.4126),
  // Add other cities here
};


class DispatchDashboard extends StatefulWidget {
  const DispatchDashboard({super.key});

  @override
  _DispatchDashboardState createState() => _DispatchDashboardState();
}

class _DispatchDashboardState extends State<DispatchDashboard> {
    // Mock Google Map Controller
    final LatLng _initialCenter = const LatLng(20.5937, 78.9629);
    String? dispatcherCity;
    bool isLoading=true;
    String _selectedStatus='pending';
    String? _selectedRequestId;

    // Variables releated to map
    BitmapDescriptor? _victimMarkerIcon;
    GoogleMapController? _mapController;
    Marker? _victimMarker;
    Set<Marker> _responderMarkers = {};
    Set<Marker> _markers = {};
    LatLng? _selectedVictimLocation;
    List<Map<String,dynamic>> _nearestResponders = [];

    String? _selectedResponderId; // Track highlighted responder
    List<LatLng> polylineCoordinates = [];
    Set<Polyline> _polylines = {};


    @override
    void initState() {
    super.initState();

    _getDispatcherCity(); //function the get the dispatcher assigned city
    _loadCustomMarker();
  }

    Future<void> _getDispatcherCity() async {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
        var doc = await FirebaseFirestore.instance
            .collection('dispatchers')
            .doc(user.uid)
            .get();

        setState(() {
            dispatcherCity = doc.data()?['assigned_city'];
            isLoading = false;
        });
        }
  }

    Future<void> _loadCustomMarker() async {
        final icon = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(80, 50)),
            'assets/markers/victim.png',
        );

        // responderIcons['Ambulance'] = await BitmapDescriptor.asset(
        //     const ImageConfiguration(size: Size(50, 70)),
        //     'assets/markers/amb_marker.png',
        // );
        // responderIcons['Fire Brigade'] = await BitmapDescriptor.asset(
        //     const ImageConfiguration(size: Size(60, 80)),
        //     'assets/markers/fb_marker.png',
        // );
        // responderIcons['Police'] = await BitmapDescriptor.asset(
        //     const ImageConfiguration(size: Size(70, 90)),
        //     'assets/markers/p_marker.png',
        // );


        setState((){
            _victimMarkerIcon=icon;
        });
    }

    // called when creating the google map for the first time
    void _onMapCreated(GoogleMapController controller) {
        _mapController = controller; //intializing the  map controller variable for controlling the map
        if (dispatcherCity != null && cityCenters.containsKey(dispatcherCity)) {
        _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(cityCenters[dispatcherCity]!, 12),
        );
        }
    }


    // called when a victim is selected then in controller showing its location
    void _moveToLocation(double lat, double lng, String requestId) {
        // print(lat);
        final destination = LatLng(lat, lng);

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(destination, 15));

        setState(() {
        // 1. Update the marker set with the new victim location
        _victimMarker =
            Marker(
            markerId: MarkerId(requestId),
            position: destination,
            icon:
                _victimMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: "Victim Location"),
            );

        _markers={_victimMarker!};

        });

        // 2. Animate the camera to the victim
        _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(
            target: destination,
            zoom: 15.0, // Street-level detail for better responder guidance
            ),
        ),
        );
    }


    // To draw routes between the victim and the selected responder
    Future<void> _drawRouteToResponder(Map<String, dynamic> responder) async {
        if (_selectedVictimLocation == null) return;

        final String responderId = responder['id'];
        final double resLat = responder['location']['lat']?.toDouble() ?? 0.0;
        final double resLng = responder['location']['lng']?.toDouble() ?? 0.0;

        setState(() {
        _selectedResponderId = responderId;
        });


        PolylinePoints polylinePoints = PolylinePoints();

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: "api_key",
        request: PolylineRequest(
            origin: PointLatLng(resLat, resLng ),
            destination: PointLatLng(_selectedVictimLocation!.latitude, _selectedVictimLocation!.longitude),
            mode: TravelMode.driving,
        ),
        );

        if (result.points.isNotEmpty) {
        setState(() {
            // Your map architecture works perfectly here
            polylineCoordinates = result.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();

            _polylines = {
            Polyline(
                polylineId: const PolylineId("route"),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
            ),
            };
        });
        }

        fitRouteBounds(LatLng(resLat,resLng), _selectedVictimLocation!, _mapController);
    }

    // Get me the top 5 nearest responders
    Future<void> _fetchAndFilterResponders(String serviceType) async {
        if (_selectedVictimLocation == null) return;

        // 1. Fetch all responders in the same city
        final snapshot = await FirebaseFirestore.instance
            .collection('responders')
            .where('city', isEqualTo: dispatcherCity)
            .where('serviceType', isEqualTo: serviceType) // Filter by matching service
            .get();

        List<Map<String, dynamic>> responderList = [];

        for (var doc in snapshot.docs) {
            var data = doc.data();
            double resLat = data['location']['lat'];
            double resLng = data['location']['lng'];

            // 2. Calculate distance in meters using Haversine formula
            double distanceInMeters = Geolocator.distanceBetween(
            _selectedVictimLocation!.latitude,
            _selectedVictimLocation!.longitude,
            resLat,
            resLng,
            );

            // print(distanceInMeters);

            responderList.add({
            ...data,
            'id': doc.id,
            'distanceKm': (distanceInMeters / 1000).toStringAsFixed(1),
            'rawDistance': distanceInMeters,
            });
        }

        // 3. Sort by distance and take top 5
        responderList.sort((a, b) => a['rawDistance'].compareTo(b['rawDistance']));
        List<Map<String, dynamic>> topResponders = responderList.take(5).toList();

        // 3. Generate Map Markers asynchronously for the top 5
        Set<Marker> newResponderMarkers = {};

        for (int i = 0; i < topResponders.length; i++) {
            final resData = topResponders[i];
            final lat = resData['location']['lat']?.toDouble() ?? 0.0;
            final lng = resData['location']['lng']?.toDouble() ?? 0.0;

            // Call your custom index marker builder (e.g., displaying numbers 1-5)
            final indexIcon = await buildIndexMarker(i + 1, serviceType);

            newResponderMarkers.add(
                Marker(
                markerId: MarkerId(resData['id']),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                    title: "Unit ${resData['full_name'] ?? 'Responder'}",
                    snippet: "${resData['distanceKm']} km away",
                ),
                icon: indexIcon,
                ),
            );
            }

        // 4. Atomically update UI state and append to your map master set
            setState(() {
            _nearestResponders = topResponders;
            _responderMarkers = newResponderMarkers;

            // Combine victim pin and new responder pins
            _markers = {
                ..._markers,
                ..._responderMarkers,
            };
            });
    }


    Future<void> _assignResponder({
        required String requestId,
        required String responderId,
        required String resName,
        required String resPhone,
        // required double resLat, // Pass the location variables you extracted earlier
        // required double resLng,
    }) async {
        // References to the documents we want to update atomically
        final DocumentReference requestRef = FirebaseFirestore.instance
            .collection('emergency_requests')
            .doc(requestId);

        final DocumentReference responderRef = FirebaseFirestore.instance
            .collection('responders')
            .doc(responderId);

        try {
        // Show a loading indicator if needed while transaction runs
        await FirebaseFirestore.instance.runTransaction((transaction) async {
            // 1. Atomically update the Emergency Request
            transaction.update(requestRef, {
            'status': 'assigned',
            'responderId': responderId,
            'responderName': resName,
            'responderPhone': resPhone,
            // 'responderLocation': {'lat': resLat, 'lng': resLng},
            'assignedAt': FieldValue.serverTimestamp(),
            });

            // 2. Atomically update the Responder Status
            transaction.update(responderRef, {
            'status': 'assigned', // Changes from 'idle' or 'available' to 'assigned'
            'currentRequestId': requestId, // Links back to the incident document
            });
        });

        // --- TRANSACTION SUCCESSFUL ---
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text("Unit $resName has been successfully dispatched"),
            backgroundColor: const Color(0xFF2C5E67),
            ),
        );
        } catch (e) {
        print("Critical Assignment Error: $e");
        if (!mounted) return;

        // 1. Show your UI notification feedback immediately
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
            content: Text("Failed to dispatch responder. Please try again."),
            backgroundColor: Colors.redAccent,
            ),
        );

        // 2. Wrap your state mutations in a delay to let the map engine clean up frames safely
        Future.delayed(Duration.zero, () {
            if (!mounted) return;

            setState(() {
                _selectedRequestId = null; // Clears selection highlight safely
                _selectedVictimLocation = null;
                _nearestResponders = [];
                _polylines.clear(); // Wipes paths
                _markers.clear(); // Cleans map markers
        });
      });
        }
    }

    @override
    Widget build(BuildContext context) {
        if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return Scaffold(
            backgroundColor: const Color(0xFF0B0E11), // Dark background
            body: Column(
            children: [
                // 1. Top Header Bar
                _buildHeader(),

                Expanded(
                child: Row(
                    children: [
                    // 2. Left Sidebar (Requests Queue)
                    _buildSidebar(),

                    // 3. Main Map Area with Overlays
                    Expanded(
                        child: Stack(
                        children: [

                            // The Map
                            GoogleMap(
                                initialCameraPosition: CameraPosition(
                                    target: _initialCenter,
                                    zoom: 12,
                                ),
                                onMapCreated: _onMapCreated,
                                markers: _markers, // This listens to the state changes from _moveToLocation
                                myLocationButtonEnabled: false, // Removes the default GPS location tracking button
                                zoomControlsEnabled: false,  // Removes the +/- buttons from bottom-right
                                webCameraControlEnabled: false,
                                mapType: MapType.normal, // Essential for your dual-theme setup
                                polylines: _polylines,

                            ),

                            // Floating Responder List (Right)
                            Positioned(
                            top: 20,
                            right: 20,
                            bottom: 20,
                            child: _buildResponderPanel(),
                            ),


                            // Layer 3: CUSTOM MAP CONTROLS (Bottom-Left)
                            Positioned(
                                bottom: 20,
                                left:
                                    20, // Places it cleanly right next to your fixed left sidebar
                                child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    // 1. ZOOM IN BUTTON
                                    _buildMapControlButton(
                                    icon: Icons.add,
                                    tooltip: "Zoom In",
                                    onPressed: () {
                                        _mapController?.animateCamera(
                                        CameraUpdate.zoomIn(),
                                        );
                                    },
                                    ),
                                    const SizedBox(height: 8),

                                    // 2. ZOOM OUT BUTTON
                                    _buildMapControlButton(
                                    icon: Icons.remove,
                                    tooltip: "Zoom Out",
                                    onPressed: () {
                                        _mapController?.animateCamera(
                                        CameraUpdate.zoomOut(),
                                        );
                                    },
                                    ),
                                ],
                                ),
                            ),
                        ],
                        ),
                    ),
                    ],
                ),
                ),
            ],
            ),
        );
    }


    // Widget builders for the build method
    Widget _buildHeader() {
    return Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Color(0xFF1A1F24),
        child: Row(
        children: [
            Icon(Icons.grid_view, color: Colors.blueGrey),
            SizedBox(width: 10),
            Text("Dispatch Center: $dispatcherCity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Spacer(),
            Text("● SYSTEM LIVE", style: TextStyle(color: Colors.green, fontSize: 12)),
            SizedBox(width: 20),
            // Icon(Icons.logout, color: Colors.white70),
            IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
            },
            )
        ],
        ),
    );
    }

    Widget _buildSidebar() {
    return Container(
      width: 400,
      color: Theme.of(context).cardColor, // Adapts to Dark/Light mode
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.emergency, color: Colors.redAccent),
                const SizedBox(width: 10),
                Text(
                  "Requests Queue",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 1. Tab Switcher (Updates _selectedStatus)
          _buildTabs(),

          // 2. Real-time List from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // We listen to requests filtering by city and current tab status
              stream: FirebaseFirestore.instance
                  .collection('emergency_requests')
                  .where('city', isEqualTo: dispatcherCity)
                  .where('status', isEqualTo: _selectedStatus,) // 'pending' or 'assigned'
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No active requests",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String id = docs[index].id;
                    String? address = "House/FlatNo.: ${data['flatNo']}\nLandmark: ${data['landmark']}\nAddress: ${data['referenceAddress']}";

                    return GestureDetector(
                      onTap: () {

                        // Logic to move the Google Map camera to selected victim's lat/lng
                        double lat = data['location']['lat']?.toDouble() ?? 0.0;
                        double lng = data['location']['lng']?.toDouble() ?? 0.0;
                        String requiredService = data['serviceType'] ?? 'Ambulance';

                        setState(() {
                          _selectedRequestId = id;
                          _selectedVictimLocation = LatLng(lat, lng); //setting the location for the current selected victim
                        });

                        // moving the map to the selected vicitim location
                        _moveToLocation(lat, lng, id);

                        // Trigger the search for responders
                        _fetchAndFilterResponders(requiredService);
                      },
                    //
                      child: _buildRequestCard(
                        victimName: data['victimName'] ?? "Emergency"  ,
                        serviceType: data['serviceType'] ?? 'N/A',
                        address: address ,
                        // timeAgo: _formatTimestamp(data['timestamp']),
                        // requestId: id,
                        isSelected: _selectedRequestId == id,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Compare with 'pending'
          _buildTabItem("PENDING", _selectedStatus == 'pending', () {
            setState(() {
              _selectedStatus = 'pending';
              _selectedRequestId = null; // Clear selection when switching tabs
              _selectedVictimLocation = null;
              _victimMarker = null;
              _responderMarkers.clear();
              _markers.clear();
              _nearestResponders.clear();
            });
          }),
          // Compare with 'assigned'
          _buildTabItem("ASSIGNED", _selectedStatus == 'assigned', () {
            setState(() {
              _selectedStatus = 'assigned';
              _selectedRequestId = null; // Clear selection when switching tabs
              _selectedVictimLocation = null;
              _victimMarker = null;
              _responderMarkers.clear();
              _markers.clear();
              _nearestResponders.clear();
            });
          }),
        ],
      ),
    );
  }

    Widget _buildTabItem(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Use your branding color for active, transparent for inactive
            color: isActive ? const Color(0xFF2C5E67) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }


    Widget _buildResponderPanel() {
    return Container(
        width: 320,
        // Add a height constraint or let the Stack/Positioned handle it
        decoration: BoxDecoration(
        color: const Color(0xFF1A1F24), // Matching your dashboard's panel color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [
            BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
            ),
        ],
        ),
        child: Column(
        mainAxisSize:
            MainAxisSize.min, // Allows panel to shrink if list is short
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // 1. Header Section
            Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    const Text(
                        "Select Responder",
                        style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        ),
                    ),
                    IconButton(
                        icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                        ),
                        onPressed: () {
                        setState(() {
                            _selectedRequestId = null; // Close selection
                            _nearestResponders = [];
                        });
                        },
                    ),
                    ],
                ),
                const SizedBox(height: 10),
                const Text(
                    "NEAREST RESPONDERS",
                    style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    ),
                ),
                ],
            ),
            ),

            // 2. The List Section (Wrapped in Expanded to fix your layout error)
            Expanded(
            child: _nearestResponders.isEmpty
                ? const Center(
                    child: Text(
                        "No matching responders found",
                        style: TextStyle(color: Colors.white38),
                    ),
                    )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _nearestResponders.length,
                    itemBuilder: (context, index) {
                        final res = _nearestResponders[index];
                        final bool isThisResponderSelected = _selectedResponderId == res['id'];
                        return GestureDetector(
                            onTap: () => _drawRouteToResponder(res),
                            child: Container(
                                // Add a visible border highlight if this particular responder card is clicked
                                decoration: BoxDecoration(
                                    border: isThisResponderSelected
                                        ? Border.all(
                                            color: const Color(0xFF2C5E67),
                                            width: 1.5,
                                        )
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                ),
                                child: _buildResponderCard(
                                    index: (index+1).toString(),
                                    name: res['full_name'] ?? 'Unit',
                                    distance: "${res['distanceKm']} km away",
                                    onAssign: () {
                                    //   // We will write the assignment logic next
                                        _assignResponder(
                                            requestId: _selectedRequestId!,
                                            responderId: res['id'],
                                            resName: res['full_name'] ?? 'Unit',
                                            resPhone: res['phone_number'] ?? 'N/A',
                                        );
                                    },
                                ),
                            ),
                        );
                    },
                    ),
            ),

        ],
        ),
    );
  }

    Widget _buildResponderCard({
    required String index,
    required String name,
    required String distance,
    // required bool isBusy,
    required VoidCallback onAssign,
    }) {
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: Theme.of(
            context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
        ),
        child: Row(
        children: [
            // 1. Responder Initial/Avatar
            Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
                index,
                style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                ),
            ),
            ),
            const SizedBox(width: 12),

            // 2. Info Section
            Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                    "Unit $name",
                    style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    ),
                ),
                const SizedBox(height: 4),
                Text(distance, style: TextStyle(fontSize: 11)),

                ],
            ),
            ),

            // 3. Action Button
            SizedBox(
                height: 32,
                child: ElevatedButton(
                    onPressed: onAssign,
                    style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                    ),
                    disabledBackgroundColor: Colors.grey[900],
                    ),
                    child: Text("ASSIGN",
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                    ),
                    ),
                ),
            ),
        ],
      ),
    );
  }

    Widget _buildRequestCard({
    required String victimName,
    required String serviceType,
    required String address,
    // required String timeAgo,
    // required String requestId,
    bool isSelected = false, // All default to false on load
    }) {
        IconData logo=Icons.emergency;

        if(serviceType=="Ambulance"){
            logo = Icons.medical_services;
        }
        else if(serviceType=="Police"){
            logo = Icons.local_police;
        }
        else if(serviceType=="Fire"){
            logo = Icons.fire_truck_sharp;
        }

    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        // Highlight border only if clicked/selected
        border: Border.all(
            color: isSelected ? const Color(0xFFE99E97) : Colors.transparent,
            width: 2,
        ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(
                "Victim: $victimName",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                ),
                ),
                // Text(
                //   "#$requestId",
                //   style: TextStyle(color: Colors.grey[500], fontSize: 12),
                // ),
            ],
            ),
            const SizedBox(height: 8),
            Row(
            children: [
                Icon(logo, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(serviceType, style: const TextStyle(color: Colors.grey)),
            ],
            ),
            const SizedBox(height: 4),
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                child: Text(
                    address,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                ),
                ),
            ],
            ),
            const SizedBox(height: 12),
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                    "PENDING",
                    style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                ),
                // Text(
                //   timeAgo,
                //   style: TextStyle(color: Colors.grey[600], fontSize: 10),
                // ),
            ],
            ),
        ],
        ),
    );
    }

    Widget _buildMapControlButton({
        required IconData icon,
        required String tooltip,
        required VoidCallback onPressed,
    }) {
        return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: const Color(
            0xFF1A1F24,
            ), // Matches your floating responder container background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
            boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
            ),
            ],
        ),
        child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 20),
            tooltip: tooltip,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
        ),
        );
    }

}
