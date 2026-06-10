// import 'dart:convert';
// import 'dart:js_interop';
// import 'dart:math';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import 'package:smart_108_cc/utils/dp_dashboard.dart';
// import 'package:smart_108_cc/utils/emergency_req_stream.dart';
// import 'package:smart_108_cc/utils/theme_provider.dart';




// class EmergencyRequest {
//   final String id;
//   final double lat;
//   final double lng;
//   final String address;
//   final String victimName;
//   final String victimPhoneNo;
//   final String serviceType;
//   final String status;
//   final String responderName;

//   EmergencyRequest({
//     required this.id,
//     required this.lat,
//     required this.lng,
//     required this.address,
//     required this.victimName,
//     required this.victimPhoneNo,
//     required this.serviceType,
//     required this.status,
//     required this.responderName
//   });
// }


// final Map<String, LatLng> cityCenters = {
//   'Jodhpur': const LatLng(26.2389, 73.0243),
//   'Delhi': const LatLng(28.6139, 77.2090),
//   'Bangalore': const LatLng(12.9716, 77.5946),
//   'Bhopal': const LatLng(23.2599, 77.4126)
//   // Add other cities here
// };

// class DispatcherDashboard extends StatefulWidget {
//   const DispatcherDashboard({super.key});

//   @override
//   State<DispatcherDashboard> createState() => _DispatcherDashboardState();
// }

// class _DispatcherDashboardState extends State<DispatcherDashboard>
// with SingleTickerProviderStateMixin {
//     late TabController _tabController;
//     String? dispatcherCity;
//     bool _isLoading = true;
//     GoogleMapController? _mapController;
//     final LatLng _initialCenter = const LatLng(20.5937, 78.9629);
//     BitmapDescriptor? _victimMarkerIcon;
//     Set<Marker> _markers={};
//     Set<Marker> _existingMarkers={};
//     Set<Marker> _responderMarkers = {};
//     EmergencyRequest? _selectedRequest;
//     bool _showResponderPanel=false;
//     String? _selectedResponderId;
//     Set<Polyline> _polylines = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadCustomMarker();
//     _getDispatcherCity();
//     _tabController = TabController(length: 2, vsync: this);
//     _tabController.addListener(_handleTabSelection);
//   }

//  // Manual handling of the tabs
//   void _handleTabSelection() {
//     // Check if the tab index actually changed (prevents double triggers)
//     if (_tabController.indexIsChanging) {
//       setState(() {
//         _selectedRequest = null; // Reset the selected request
//         _showResponderPanel = false; // Close the responder panel if open
//         _markers.clear(); // Clear markers from the map
//       });
//       _returnToCityCenter(); // Move map back to city center
//     }
//   }

//   void _returnToCityCenter() {
//     if (dispatcherCity != null && cityCenters.containsKey(dispatcherCity)) {
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(cityCenters[dispatcherCity]!, 12),
//       );
//     }
//   }

//     Future<void> _loadCustomMarker() async {
//         final icon = await BitmapDescriptor.asset(
//             const ImageConfiguration(size: Size(80, 50)),
//             'assets/markers/victim.png',
//         );

//         // responderIcons['Ambulance'] = await BitmapDescriptor.asset(
//         //     const ImageConfiguration(size: Size(50, 70)),
//         //     'assets/markers/amb_marker.png',
//         // );
//         // responderIcons['Fire Brigade'] = await BitmapDescriptor.asset(
//         //     const ImageConfiguration(size: Size(60, 80)),
//         //     'assets/markers/fb_marker.png',
//         // );
//         // responderIcons['Police'] = await BitmapDescriptor.asset(
//         //     const ImageConfiguration(size: Size(70, 90)),
//         //     'assets/markers/p_marker.png',
//         // );


//         setState((){
//             _victimMarkerIcon=icon;
//         });
//     }

//   @override
//   void dispose() {
//     _tabController.dispose(); // Clean up the controller
//     super.dispose();
//   }

//   void _onMapCreated(GoogleMapController controller){
//     _mapController=controller;
//     if (dispatcherCity != null && cityCenters.containsKey(dispatcherCity)) {
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(cityCenters[dispatcherCity]!, 12),
//       );
//     }
//   }

//   //   zoom to the selected request's location and creating Emergency Request object
//   void _zoomToRequest(String requestId, Map<String,dynamic> data){
//     double lat = data['location']['lat'];
//     double lng = data['location']['lng'];


//     final destination=LatLng(lat,lng);

//     _mapController?.animateCamera(
//       CameraUpdate.newLatLngZoom(destination, 15),
//     );

//     setState(() {
//       _selectedRequest = EmergencyRequest(
//         id: requestId,
//         lat: lat,
//         lng: lng,
//         address: data['referenceAddress'] ?? '',
//         victimName: data['victimName'] ?? 'Unknown',
//         victimPhoneNo: data['victimPhone'] ?? '-',
//         serviceType: data['serviceType'] ?? '-',
//         status: data['status'] ?? '-',
//         responderName: data['responderName'] ?? '-',
//       );


//       _existingMarkers = {
//         Marker(
//           markerId: MarkerId(requestId),
//           position: destination,
//           icon: _victimMarkerIcon ?? BitmapDescriptor.defaultMarker,
//           infoWindow: const InfoWindow(title: "Victim Location"),
//         ),
//       };

//     //   print(_existingMarkers);
//       _markers=_existingMarkers;
//     });

//   }

//   Future<void> _drawRouteBetween(LatLng responderLatLng, LatLng victimLatLng) async {
//     const apiKey = 'AIzaSyAB6ETR9TOC0rDfy4MSqp0APJ3456FP6ic';
//     final url = Uri.parse(
//         'https://maps.googleapis.com/maps/api/directions/json'
//         '?origin=${responderLatLng.latitude},${responderLatLng.longitude}'
//         '&destination=${victimLatLng.latitude},${victimLatLng.longitude}'
//         '&key=$apiKey',
//     );

//     final response = await http.get(url);
//     if (response.statusCode != 200) return;

//     final data = jsonDecode(response.body);
//     if (data['routes'].isEmpty) return;

//     // Decode the polyline points
//     // final String encodedPolyline =
//         // data['routes'][0]['overview_polyline']['points'];
//     // final List<LatLng> polylinePoints = decodePolyline(encodedPolyline);

//     // if (mounted) {
//     //     setState(() {
//     //     _polylines = {
//     //         Polyline(
//     //         polylineId: const PolylineId('responder_route'),
//     //         points: polylinePoints,
//     //         color: const Color(0xFF2C5E67),
//     //         width: 4,
//     //         patterns: [PatternItem.dash(20), PatternItem.gap(10)], // dashed line
//     //         ),
//     //     };
//     //     });
//     // }
//     }




//     // The top info card above the map
//     Widget _buildTopVictimCard() {
//     String status = _selectedRequest!.status;
//     // print(status);

//     return Card(
//         elevation: 8,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//             Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                 Text(
//                     "Victim: ${_selectedRequest!.victimName}",
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 Text("Phone No.: ${_selectedRequest!.victimPhoneNo}"),
//                 Text("Address: ${_selectedRequest!.address}"),
//                 if (status == 'assigned')
//                     Text(
//                         "Assigned to: ${_selectedRequest!.responderName}",
//                         style: const TextStyle(
//                         color: Colors.green,
//                         fontWeight: FontWeight.w500,
//                         ),
//                     ),
//                 ],
//             ),
//             if (status == 'pending' && !_showResponderPanel)...[ // Only show the button if panel is closed
//                 ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C5E67)),
//                 onPressed: () => setState(() => _showResponderPanel = true),
//                 child: const Text("Assign Dispatcher", style: TextStyle(color: Colors.white)),
//                 ),
//             ]
//             ],
//         ),
//         ),
//     );
//     }

//     // to update the responders markers on the mapz
//     void _updateResponderMarkers(List<QueryDocumentSnapshot> docs) async {
//         final Set<Marker> newMarkers = {};
//         for (int i = 0; i < docs.length; i++) {
//             final doc = docs[i];
//             final data = doc.data() as Map<String, dynamic>;
//             final location = data['location'];
//             if (location == null) continue;

//             final lat = location['lat'];
//             final lng = location['lng'];
//             if (lat == null || lng == null) continue;

//             final String serviceType = data['serviceType'] ?? '';
//             final indexIcon = await buildIndexMarker(i + 1, serviceType);

//             newMarkers.add(
//                 Marker(
//                 markerId: MarkerId(doc.id),
//                 position: LatLng(lat, lng),
//                 infoWindow: InfoWindow(
//                     title: data['name'] ?? 'Responder',
//                     snippet: data['serviceType'] ?? '',
//                 ),
//                 // icon: responderIcons[serviceType] ?? BitmapDescriptor.defaultMarker,
//                 icon: indexIcon,
//                 ),
//             );
//         }

//         // ✅ Only setState if markers actually changed
//         if (_responderMarkers.length != newMarkers.length) {
//         setState(() {
//             _responderMarkers = newMarkers;
//             _markers = {..._existingMarkers, ..._responderMarkers};
//         });
//         }
//   }

// //this is called when we confirm a particular responder for the emergency request
// Future<void> _confirmAssignment(
//     String requestId,
//     String responderId,
//     String resName,
//     String resPhone,
//   ) async {
//     try {
//       //1. Update the Emergency Request
//       await FirebaseFirestore.instance
//           .collection('emergency_requests')
//           .doc(requestId)
//           .update({
//             'status': 'assigned',
//             'responderId': responderId,
//             'responderName': resName,
//             'responderPhone': resPhone,
//             // 'respondersLocation':{
//             //     'lat': lat,
//             //     'lng': lng,
//             // },
//             'assignedAt': FieldValue.serverTimestamp(),
//           });

//       // 2. Update the Responders Status so they dont get two jobs at once
//       await FirebaseFirestore.instance
//           .collection('responders')
//           .doc(responderId)
//           .update({
//             'status': "assigned",
//             'currentRequestId': requestId} //to get the information about the request in the responders app
//             );

//       if (!mounted) return;

//       setState((){
//         _selectedRequest = null;
//       });

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("$resName has been dispatched")));
//     } catch (e) {
//       print("Assignment Error: $e");
//     }
//   }


// // Create a list of active responders
// Widget _buildResponderList(String requestId, String serviceType) {
//   return StreamBuilder<QuerySnapshot>(
//     // Filtering by assigned city, matching service (Ambulance/Police), and availability
//     stream: FirebaseFirestore.instance
//         .collection('responders')
//         .where('city', isEqualTo: dispatcherCity)
//         .where('serviceType', isEqualTo: serviceType)
//         .where('status', isEqualTo: "free")
//         .snapshots(),
//     builder: (context, snapshot) {
//       if (snapshot.hasError) {
//         return const Center(child: Text("Error loading responders"));
//       }
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return const Center(child: CircularProgressIndicator());
//       }

//       final docs = snapshot.data!.docs;
//         //   print(docs);
//        // ✅ Update map markers whenever responder list updates
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _updateResponderMarkers(docs);
//         });


//       if (docs.isEmpty) {
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.person_off, size: 40, color: Colors.grey[400]),
//               const SizedBox(height: 10),
//               const Text("No available responders found",
//                 style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         );
//       }

//       return ListView.separated(
//         padding: const EdgeInsets.all(10),
//         itemCount: docs.length,
//         separatorBuilder: (context, index) => const Divider(),
//         itemBuilder: (context, index) {
//             final doc = docs[index];
//             // Safely cast data - using the exact keys we debugged earlier
//             final data = doc.data() as Map<String, dynamic>;
//             // print(data);

//             // Ensure keys match your Firestore exactly (removing those extra spaces!)
//             String name = data['full_name'] ?? 'Unknown Unit';
//             String phone = data['phone_number'] ?? 'No Phone';

//             Map<String, dynamic>? location = data['location'];
//             double lat = location?['lat'] ?? 0.0;
//             double lng = location?['lng'] ?? 0.0;

//             LatLng responderLatLng = LatLng(lat,lng);
//             LatLng victimlatLng = LatLng(_selectedRequest!.lat,_selectedRequest!.lng);

//             return GestureDetector(
//               onTap: () {
//                 setState(() => _selectedResponderId = doc.id);
//                 _fitMapToVictimAndResponder(responderLatLng); // pass responder's LatLng
//                 _drawRouteBetween(responderLatLng, victimlatLng);
//               },
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   // ✅ Highlight if this responder is selected
//                   color: _selectedResponderId == doc.id
//                       ? const Color(0xFF2C5E67).withValues(alpha: 0.15)
//                       : Colors.transparent,
//                   borderRadius: BorderRadius.circular(10),
//                   border: _selectedResponderId == doc.id
//                       ? Border.all(color: const Color(0xFF2C5E67), width: 1.5)
//                       : null,
//                 ),
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: _selectedResponderId == doc.id
//                         ? const Color(0xFF2C5E67)
//                         : const Color(0xFF2C5E67).withValues(alpha: 0.1),
//                     child: Text(
//                       "${index + 1}",
//                       style: TextStyle(
//                         color: _selectedResponderId == doc.id
//                             ? Colors.white
//                             : const Color(0xFF2C5E67),
//                       ),
//                     ),
//                   ),
//                   title: Text(
//                     name,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(phone),
//                   trailing: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green[700],
//                       foregroundColor: Colors.white,
//                     ),
//                     onPressed: () =>
//                         _confirmAssignment(requestId, doc.id, name, phone),
//                     child: const Text("Assign"),
//                   ),
//                 ),
//               ),
//             );
//         },
//       );
//     },
//   );
// }


//    // Get dispatcherCity from the database
//   Future<void> _getDispatcherCity() async {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user != null) {
//       var doc = await FirebaseFirestore.instance
//           .collection('dispatchers')
//           .doc(user.uid)
//           .get();

//       setState(() {
//         dispatcherCity = doc.data()?['assigned_city'];
//         _isLoading = false;
//       });
//     }
//   }


//   void _logout() async {
//     await FirebaseAuth.instance.signOut();
//     if (!mounted) return;
//     Navigator.pushReplacementNamed(context, '/login');
//   }


// void _fitMapToVictimAndResponder(LatLng responderLatLng) {
//     if (_mapController == null) return;

//     // ✅ Build bounds that include both victim and responder
//     final bounds = LatLngBounds(
//       southwest: LatLng(
//         min(_selectedRequest!.lat, responderLatLng.latitude),
//         min(_selectedRequest!.lng, responderLatLng.longitude),
//       ),
//       northeast: LatLng(
//         max(_selectedRequest!.lat, responderLatLng.latitude),
//         max(_selectedRequest!.lng, responderLatLng.longitude),
//       ),
//     );

//     _mapController!.animateCamera(
//       CameraUpdate.newLatLngBounds(
//         bounds,
//         80.0, // padding in pixels around the bounds
//       ),
//     );
//   }


//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

//     // Check if the dispatcher has been assigned a city yet
//     bool isAssigned = dispatcherCity !=null && dispatcherCity!.isNotEmpty;


//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           isAssigned
//               ? "Dispatch Center: $dispatcherCity"
//               : "Status: Pending City Assignment",
//         ),
//         centerTitle: true,
//         backgroundColor: const Color(0xFF2C5E67),
//         foregroundColor: Colors.white,
//         actions: [
//           // THEME TOGGLE BUTTON
//           IconButton(
//             icon: Icon(
//               Provider.of<ThemeProvider>(context).isDarkMode
//                   ? Icons.light_mode
//                   : Icons.dark_mode,
//             ),
//             onPressed: () {
//               Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
//             },
//           ),
//           IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
//         ]
//       ),
//       body: isAssigned
//         ? _buildActiveDashboard()
//         : _buildPendingStateUI()
//     );
// }


// // UI when the city is assigned
//   Widget _buildActiveDashboard(){
//     return Row(
//     children: [
//       // 1. Sidebar (Existing list of requests)
//       SizedBox(
//         width: 350,
//         child: DefaultTabController(
//           length: 2,
//           child: Column(
//             children: [
//               Container(
//                 color: Colors.white,
//                 child: TabBar(
//                   controller: _tabController,
//                   labelColor: const Color(0xFF2C5E67),
//                   unselectedLabelColor: Colors.grey,
//                   indicatorColor: const Color(0xFF2C5E67),
//                   tabs: [
//                     Tab(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.pending_actions, size: 18),
//                           const SizedBox(width: 8),
//                           const Text("Pending"),
//                         ],
//                       ),
//                     ),
//                     Tab(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(Icons.assignment_turned_in, size: 18),
//                           const SizedBox(width: 8),
//                           const Text("Assigned"),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//             ),
//             Expanded(
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [
//                   // Tab 1: Pending Requests
//                   EmergencyRequestStream(
//                     city: dispatcherCity!,
//                     status: 'pending', // Filter for pending
//                     onLocationSelected: (id, data) {
//                       _zoomToRequest(id, data);
//                     },
//                   ),
//                   // Tab 2: Assigned Requests
//                   EmergencyRequestStream(
//                     city: dispatcherCity!,
//                     status: 'assigned', // Filter for assigned
//                     onLocationSelected: (id, data) {
//                       _zoomToRequest(id, data);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         ),
//       ),

//       // 2. Map Area (This will now shrink automatically)
//         Expanded(
//             child: Stack(
//                 children: [
//                 Row(
//                     children: [
//                     // THE MAP - Wrapped in Expanded to respond to the Row's width
//                     Expanded(
//                         child: GoogleMap(
//                         onMapCreated: _onMapCreated,
//                         initialCameraPosition: CameraPosition(target: _initialCenter, zoom: 12),
//                         markers: _markers,
//                         // polylines: _polylines
//                         ),
//                     ),

//                     // THE RESPONDER PANEL - Only exists in the Row when _showResponderPanel is true
//                     if (_showResponderPanel && _selectedRequest != null)
//                         Container(
//                         width: 400, // Fixed width for the panel
//                         decoration: BoxDecoration(
//                             color: Colors.white,
//                             border: Border(left: BorderSide(color: Colors.grey.shade300)),
//                         ),
//                         child: Column(
//                             children: [
//                             // Header with Cross Button
//                             Container(
//                                 padding: const EdgeInsets.all(16),
//                                 color: const Color(0xFF2C5E67),
//                                 child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                     const Text(
//                                     "Select Responder",
//                                     style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                                     ),
//                                     IconButton(
//                                         icon: const Icon(
//                                             Icons.close,
//                                             color: Colors.white,
//                                         ),
//                                         onPressed: () {
//                                             setState(() {
//                                             _showResponderPanel = false;
//                                             _responderMarkers = {};
//                                             _markers = _existingMarkers; // revert to only victim markers
//                                             _polylines = {};
//                                             });
//                                         },
//                                         ),
//                                 ],
//                                 ),
//                             ),
//                             // The List of Responders
//                             Expanded(
//                                 child: _buildResponderList(_selectedRequest!.id, _selectedRequest!.serviceType),
//                             ),
//                             ],
//                         ),
//                         ),
//                 ],
//             ),

//             // 3. TOP OVERLAY CARD (Victim Details)
//             // We keep this in a Stack so it floats "over" the Map
//             if (_selectedRequest != null)
//               Positioned(
//                 top: 10,
//                 left: 16,
//                 // We use a specific width or constraint so it doesn't overlap the side panel
//                 // right: _showResponderPanel ? 416 : 16,
//                 child: ConstrainedBox(
//                   constraints: const BoxConstraints(maxWidth: 600),
//                   child: _buildTopVictimCard()
//                   ),
//               ),
//         ],
//       ),
//     ),
//     ],
//   );

// }


// // Dashboard UI when the city is not assigned
//   Widget _buildPendingStateUI() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.domain_disabled, size: 80, color: Colors.grey),
//           const SizedBox(height: 20),
//           const Text(
//             "Account Not Yet Assigned",
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           const Text(
//             "Please contact your branch admin to get assigned to a city control center.",
//             style: TextStyle(fontSize: 16, color: Colors.blueGrey),
//           ),
//           const SizedBox(height: 30),
//           ElevatedButton.icon(
//             onPressed:
//                 _getDispatcherCity, // Allow them to refresh and check again
//             icon: const Icon(Icons.refresh),
//             label: const Text("Check Assignment Status"),
//           ),
//         ],
//       ),
//     );
//   }


// }
