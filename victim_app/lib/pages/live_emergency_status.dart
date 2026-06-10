// import 'dart:math';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:smart_108/utils/funcs.dart';
// import 'package:smart_108/utils/logger.dart';

// class LiveEmergencyStatusPage extends StatefulWidget {
//   final String requestId;
//   const LiveEmergencyStatusPage({super.key, required this.requestId});

//   @override
//   State<LiveEmergencyStatusPage> createState() => _LiveEmergencyStatusPageState();
// }

// class _LiveEmergencyStatusPageState extends State<LiveEmergencyStatusPage> {
//     final LatLng _initialPosition = const LatLng(20.5937, 78.9629);
//     // late Set<Marker> markers={};
//     BitmapDescriptor? _victimIcon;
//     final Map<String, BitmapDescriptor> _responderIcons = {};
//     bool _iconsLoaded = false;
//     GoogleMapController? _mapController;
//     List<LatLng> polylineCoordinates=[];
//     PolylinePoints polylinePoints=PolylinePoints();

//     Widget _buildFloatingWhiteBox({required Widget child}) {
//     return Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//         color: Colors.white, // Pure white box
//         borderRadius: BorderRadius.circular(15), // Rounded corners
//         boxShadow: [
//             BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05), // Very subtle shadow
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//             ),
//         ],
//         ),
//         child: child,
//     );
//     }

//     void getPolyline(LatLng source, LatLng destination) async {
//         // Use the PolylinePoints class to fetch route coordinates between the responder's current LatLng and the victim's LatLng.
//         PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//         googleApiKey:"",
//         request: PolylineRequest(
//             origin: PointLatLng(source.latitude, source.longitude),
//             destination: PointLatLng(destination.latitude, destination.longitude),
//             mode: TravelMode.driving,
//         ),
//         );

//         if (result.points.isNotEmpty) {
//         setState(() {
//             polylineCoordinates = result.points
//                 .map((point) => LatLng(point.latitude, point.longitude))
//                 .toList();
//         });
//         }
//     }



//     Widget _buildIconRow(IconData icon, String title, String content) {
//     return Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//         Icon(icon, size: 22, color: Colors.black87),
//         const SizedBox(width: 15),
//         Expanded(
//             child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//                 Text(
//                 title,
//                 style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                 ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                 content,
//                 style: TextStyle(
//                     color: Colors.grey[700],
//                     fontSize: 16,
//                     height: 1.4,
//                 ),
//                 ),
//             ],
//             ),
//         ),
//         ],
//     );
//     }



//     Future<void> _loadCustomMarker() async {
//         _victimIcon = await BitmapDescriptor.asset(
//             const ImageConfiguration(size: Size(80, 50)),
//             'assets/markers/my_marker.png',
//         );

//         _responderIcons['Ambulance'] = await BitmapDescriptor.asset(
//             const ImageConfiguration(size: Size(50, 70)),
//             'assets/markers/amb_marker.png',
//         );
//         _responderIcons['Fire Brigade'] = await BitmapDescriptor.asset(
//             const ImageConfiguration(size: Size(50, 70)),
//             'assets/markers/fb_marker.png',
//         );
//         _responderIcons['Police'] = await BitmapDescriptor.asset(
//             const ImageConfiguration(size: Size(50, 70)),
//             'assets/markers/p_marker.png',
//         );

//         setState(() {
//             _iconsLoaded = true;
//         });
//     }

//     @override
//     void initState() {
//     super.initState();
//     _loadCustomMarker();
//     }

//     void _goToDestination(LatLng destination) {
//     if (_mapController != null) {
//         _mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(
//             destination,
//             15,
//         ), // Zoom level 15 is good for streets
//         );
//     }
//     }

//     void _zoomIn() {
//         _mapController?.animateCamera(CameraUpdate.zoomIn());
//     }

//     void _zoomOut() {
//         _mapController?.animateCamera(CameraUpdate.zoomOut());
//     }

//     void _fitMapToMarkers(LatLng victim, LatLng responder) {
//         if (_mapController == null) return;

//         LatLngBounds bounds;

//         if (victim.latitude > responder.latitude) {
//             // Victim is further North than Responder
//             bounds = LatLngBounds(
//                 southwest: LatLng(
//                     victim.latitude < responder.latitude ? victim.latitude : responder.latitude,
//                     victim.longitude < responder.longitude ? victim.longitude : responder.longitude,
//                 ),
//                 northeast: LatLng(
//                     victim.latitude > responder.latitude ? victim.latitude : responder.latitude,
//                     victim.longitude > responder.longitude ? victim.longitude : responder.longitude,
//                 ),
//             );
//         } else {
//             // Standard bounding logic
//             bounds = LatLngBounds(
//                 southwest: LatLng(
//                     min(victim.latitude, responder.latitude),
//                     min(victim.longitude, responder.longitude),
//                 ),
//                 northeast: LatLng(
//                     max(victim.latitude, responder.latitude),
//                     max(victim.longitude, responder.longitude),
//                 ),
//             );
//         }

//         _mapController!.animateCamera(
//             CameraUpdate.newLatLngBounds(bounds, 80), // 80 is the padding in pixels
//         );
//     }


//     @override
//     Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: Color(0xFFBADFDB),
//         appBar: AppBar(
//             title: const Text("Live Tracking of Dispatcher"),
//             backgroundColor: Colors.transparent,
//         ),

//     // NESTED STREAM BUILDER (First for getting the basic information of the emergency request)
//     body: StreamBuilder<DocumentSnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('emergency_requests')
//             .doc(widget.requestId)
//             .snapshots(),
//         builder: (context, snapshot){
//             if(snapshot.hasError) {
//                 return const Center(child: Text("Something went wrong"));
//             }
//             if(!snapshot.hasData || !snapshot.data!.exists){
//                 return const Center(child: CircularProgressIndicator());
//             }
//             // get data from the snapshot
//             var data=snapshot.data!.data() as Map<String,dynamic>;

//             String status = data['status'] ?? 'pending';
//         // Victim location
//             double victimLat = data['location']['lat'];
//             double victimLng = data['location']['lng'];
//             LatLng victimLatLng = LatLng(victimLat, victimLng);
//             String? responderId = data['responderId']; // Using ID instead of snapshot
//             String serviceType = data['serviceType'] ?? 'Ambulance';

//             BitmapDescriptor responderIcon =_responderIcons[serviceType] ?? BitmapDescriptor.defaultMarker;
//             // print(status);
//             // print(data['respondersLocation']);

//             // if (status == 'assigned' && data['respondersLocation'] != null) {
//             // // double responderLat = data['respondersLocation']['lat'];
//             // // double responderLng = data['respondersLocation']['lng'];

//             // // responderLatLng = LatLng(responderLat, responderLng);
//             // // print(responderLatLng);

//             // }
//             // 2. Nest the second stream to listen to the Responder's Live Collection (the code runs whenever the location of the responder changes)
//             return StreamBuilder<DocumentSnapshot>(
//                 stream: (status == 'assigned' && responderId != null)
//                     ? FirebaseFirestore.instance.collection('responders').doc(responderId).snapshots()
//                     : const Stream.empty(),
//                 builder: (context, responderSnapshot) {

//                     LatLng? responderLatLng;
//                     if (responderSnapshot.hasData && responderSnapshot.data!.exists){
//                         var responderData = responderSnapshot.data!.data() as Map<String, dynamic>;
//                         // Extract live location from the Source of Truth
//                         if (responderData['location'] != null) {
//                             responderLatLng = LatLng(
//                             responderData['location']['lat'],
//                             responderData['location']['lng'],
//                             );
//                         }
//                     }

//                     // logger.d(responderLatLng);

//                     Set<Marker> markers = {};

//                     //Victim marker (always visible)
//                     markers.add(
//                         Marker(
//                         markerId: const MarkerId('victim'),
//                         position: victimLatLng,
//                         icon: _victimIcon ?? BitmapDescriptor.defaultMarker,
//                         infoWindow: const InfoWindow(title: "Victim Location"),
//                         ),
//                     );

//                     // Responder marker (only when assigned)
//                     if (status == 'assigned' && responderLatLng != null) {
//                         markers.add(
//                         Marker(
//                             markerId: const MarkerId('responder'),
//                             position: responderLatLng,
//                             icon:responderIcon,
//                             infoWindow: const InfoWindow(title: "Responder Location"),
//                         ),
//                         );
//                     }

//                     if (_mapController != null) {
//                         _mapController!.animateCamera(
//                         CameraUpdate.newLatLngZoom(victimLatLng, 15),
//                         );
//                     }

//                     if (status == 'assigned' &&
//                         responderLatLng != null &&
//                         polylineCoordinates.isEmpty) {
//                         getPolyline(
//                         responderLatLng,
//                         victimLatLng,
//                         ); //converting latlng to polylineCoordinates
//                     } else if (status != 'assigned') {
//                         polylineCoordinates.clear(); // Clear path if not assigned
//                     }

//                     // to fit the zoom
//                     if (status == 'assigned' && responderLatLng != null) {
//                         // Call this once or when locations change significantly
//                         _fitMapToMarkers(victimLatLng, responderLatLng);
//                     }

//                     return Stack(
//                         children: [
//                         Column(
//                             children: [
//                             SizedBox(
//                                 height: MediaQuery.of(context).size.height * 0.5,
//                                 width: double.infinity,
//                                 child: GoogleMap(
//                                     onMapCreated: (controller) =>
//                                         _mapController = controller,
//                                     initialCameraPosition: CameraPosition(
//                                         target: victimLatLng,
//                                         zoom: 15,
//                                     ),
//                                     markers: markers,
//                                     polylines: {
//                                         if (polylineCoordinates
//                                             .isNotEmpty) //only updating if we have the polyline coordinates
//                                         Polyline(
//                                             polylineId: const PolylineId("route"),
//                                             color: const Color(
//                                             0xFF2C5E67,
//                                             ), // Use your brand teal
//                                             points: polylineCoordinates,
//                                             width: 5,
//                                         ),
//                                     },
//                                     myLocationButtonEnabled: false,
//                                     zoomControlsEnabled: false,
//                                 ),
//                             ),

//                             const Expanded(child: SizedBox.shrink()),
//                             ],
//                         ),

//                         // 2. RETURN TO DESTINATION BUTTON
//                         Positioned(
//                             bottom:
//                                 MediaQuery.of(context).size.height *
//                                 0.27, // Adjust this so it's above the collapsed sheet
//                             right: 16,
//                             child: FloatingActionButton(
//                             mini:
//                                 true, // A smaller button looks cleaner on map overlays
//                             backgroundColor: Colors.white,
//                             foregroundColor: const Color(0xFF2C5E67),
//                             onPressed: () => _goToDestination(victimLatLng),
//                             child: const Icon(
//                                 Icons.my_location,
//                             ), // This is the standard "re-center" icon
//                             ),
//                         ),

//                         // ZOOM IN/ZOOM OUT BUTTON
//                         Positioned(
//                             // Positioning them on the right, above your re-center button
//                             bottom: MediaQuery.of(context).size.height * 0.35,
//                             right: 16,
//                             child: Column(
//                             children: [
//                                 FloatingActionButton(
//                                 heroTag:
//                                     "zoomIn", // Unique tag required if using multiple FABs
//                                 mini: true,
//                                 backgroundColor: Colors.white,
//                                 foregroundColor: const Color(0xFF2C5E67),
//                                 onPressed: _zoomIn,
//                                 child: const Icon(Icons.add),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 FloatingActionButton(
//                                 heroTag: "zoomOut",
//                                 mini: true,
//                                 backgroundColor: Colors.white,
//                                 foregroundColor: const Color(0xFF2C5E67),
//                                 onPressed: _zoomOut,
//                                 child: const Icon(Icons.remove),
//                                 ),
//                             ],
//                             ),
//                         ),

//                         // 3. SWIPEABLE INFORMATION SHEET
//                         DraggableScrollableSheet(
//                             initialChildSize:
//                                 0.35, // Height when first loaded (35% of screen)
//                             minChildSize: 0.35, // Minimum height when collapsed
//                             maxChildSize: 0.85, // Maximum height when fully pulled up
//                             builder: (context, scrollController) {
//                             return Container(
//                                 decoration: BoxDecoration(
//                                 color: Color(
//                                     0xFFBADFDB,
//                                 ), // 1. Light grey background for the "base"
//                                 borderRadius: BorderRadius.vertical(
//                                     top: Radius.circular(25),
//                                 ),
//                                 ),
//                                 child: ListView(
//                                 controller:
//                                     scrollController, // Vital: Syncs swipe with scrolling
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 10,
//                                 ),
//                                 children: [
//                                     //1. Pull handle for visual cue
//                                     Center(
//                                     child: Container(
//                                         margin: const EdgeInsets.only(
//                                         bottom: 20,
//                                         top: 10,
//                                         ),
//                                         width: 40,
//                                         height: 5,
//                                         decoration: BoxDecoration(
//                                         color: Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(10),
//                                         ),
//                                     ),
//                                     ),

//                                     //2. Current Status Box
//                                     _buildFloatingWhiteBox(
//                                     child: Text(
//                                         status == 'pending'
//                                             ? "Waiting for Dispatcher..."
//                                             : status,
//                                         style: const TextStyle(
//                                         fontSize: 20,
//                                         fontWeight: FontWeight.bold,
//                                         ),
//                                     ),
//                                     ),

//                                     //3. Responder Info Box (Visible only if assigned)
//                                     if (status == 'assigned')
//                                     _buildFloatingWhiteBox(
//                                         child: Row(
//                                         children: [
//                                             CircleAvatar(radius: 30, backgroundImage: AssetImage(getServicePersonIconPath(serviceType))), //In future to add the responder profile picture
//                                             // Icon(Icons.person, size: 22),

//                                             const SizedBox(width: 15),
//                                             Expanded(
//                                             child: Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                 Text(
//                                                     "Responders details",
//                                                     style: const TextStyle(
//                                                     fontWeight: FontWeight.bold,
//                                                     fontSize: 18,
//                                                     ),
//                                                 ),
//                                                 Text(
//                                                     data['responderName'] ??
//                                                         'Hero Name',
//                                                     style: const TextStyle(
//                                                     fontSize: 12,
//                                                     ),
//                                                 ),
//                                                 ],
//                                             ),
//                                             ),

//                                             IconButton(
//                                             icon: const Icon(
//                                                 Icons.call,
//                                                 color: Colors.green,
//                                             ),
//                                             onPressed: () {}, // Add dialer logic
//                                             ),
//                                         ],
//                                         ),
//                                     ),

//                                     // 4. Emergency & Order Details Box(Icon + Text format)
//                                     _buildFloatingWhiteBox(
//                                     child: Column(
//                                         children: [
//                                         _buildIconRow(
//                                             Icons.assignment_outlined,
//                                             "Emergency Details",
//                                             "Type:  ${data['serviceType']}\nAddress: ${data['flatNo']}, ${data['landmark']}, ${data['referenceAddress']}",
//                                         ),
//                                         const Divider(height: 30),
//                                         _buildIconRow(
//                                             Icons.info_outline,
//                                             "Instructions: ",
//                                             "Stay calm and keep your line free.",
//                                         ),
//                                         ],
//                                     ),
//                                     ),
//                                 ],
//                                 ),
//                             );
//                             },
//                         ),
//                         ],
//                     );



//                 }
//             );


//       }
//     )

//     );
//   }
// }
