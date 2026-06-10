import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_108/pages/main_screen.dart';
import 'package:smart_108/utils/funcs.dart';
import 'package:smart_108/utils/status_helper.dart';

class LiveTracking extends StatefulWidget {
  final String requestId;
  final bool fromEmergencyFlow;
  const LiveTracking({super.key, required this.requestId, this.fromEmergencyFlow=false});

  @override
  State<LiveTracking> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTracking> {
  final LatLng _initialPosition = const LatLng(20.5937, 78.9629);
  BitmapDescriptor? _victimIcon;
  final Map<String, BitmapDescriptor> _responderIcons = {};
  bool _iconsLoaded = false;
  GoogleMapController? _mapController;
  List<LatLng> polylineCoordinates=[];
  PolylinePoints polylinePoints=PolylinePoints();
  String _eta = 'Calculating...';
  DateTime? _lastEtaFetch;



    Widget _buildFloatingWhiteBox({required Widget child}) {
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: Colors.white, // Pure white box
        borderRadius: BorderRadius.circular(15), // Rounded corners
        boxShadow: [
            BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Very subtle shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
            ),
        ],
        ),
        child: child,
    );
    }

  Map<String, String> _getHeaderText(String status) {
    switch (status) {
    case 'assigned':
        return {
        'label': 'ARRIVING IN',
        'value': _eta, // 🔁 Replace with dynamic ETA
        };
    case 'pending':
        return {'label': 'PLEASE WAIT', 'value': 'Assigning Responder'};
    case 'arrived':
        return {'label': 'RESPONDER', 'value': 'Reached Your Location'};
    case 'completed':
        return {'label': 'REQUEST', 'value': 'Completed'};
    default:
        return {'label': 'STATUS', 'value': 'Fetching...'};
    }
}

    Future<void> _loadCustomMarker() async {
        _victimIcon = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(80, 50)),
            'assets/markers/my_marker.png',
        );

        _responderIcons['Ambulance'] = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(50, 70)),
            'assets/markers/amb_marker.png',
        );
        _responderIcons['Fire Brigade'] = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(50, 70)),
            'assets/markers/fb_marker.png',
        );
        _responderIcons['Police'] = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(50, 70)),
            'assets/markers/p_marker.png',
        );

        setState(() {
            _iconsLoaded = true;
        });
    }

    void getPolyline(LatLng source, LatLng destination) async {
    // Use the PolylinePoints class to fetch route coordinates between the responder's current LatLng and the victim's LatLng.
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: "<your api key>",
        request: PolylineRequest(
        origin: PointLatLng(source.latitude, source.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
        ),
    );

    if (result.points.isNotEmpty) {
        setState(() {
        polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        });
    }
    }

    void _fitMapToMarkers(LatLng victim, LatLng responder) {
        if (_mapController == null) return;

        LatLngBounds bounds;

        if (victim.latitude > responder.latitude) {
            // Victim is further North than Responder
            bounds = LatLngBounds(
            southwest: LatLng(
                victim.latitude < responder.latitude
                    ? victim.latitude
                    : responder.latitude,
                victim.longitude < responder.longitude
                    ? victim.longitude
                    : responder.longitude,
            ),
            northeast: LatLng(
                victim.latitude > responder.latitude
                    ? victim.latitude
                    : responder.latitude,
                victim.longitude > responder.longitude
                    ? victim.longitude
                    : responder.longitude,
            ),
            );
        } else {
            // Standard bounding logic
            bounds = LatLngBounds(
            southwest: LatLng(
                min(victim.latitude, responder.latitude),
                min(victim.longitude, responder.longitude),
            ),
            northeast: LatLng(
                max(victim.latitude, responder.latitude),
                max(victim.longitude, responder.longitude),
            ),
            );
    }

    _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80), // 80 is the padding in pixels
    );
    }

    void _zoomIn() {
        _mapController?.animateCamera(CameraUpdate.zoomIn());
    }

    void _zoomOut() {
        _mapController?.animateCamera(CameraUpdate.zoomOut());
    }

    @override
    void initState() {
        super.initState();
        _loadCustomMarker();
    }

    Future<void> _refreshETA(LatLng responderLatLng, LatLng victimLatLng) async {
        final eta = await fetchETA(responderLatLng, victimLatLng);
        if (mounted) {
            setState(() => _eta = eta);
        }
    }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBADFDB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
              .collection('emergency_requests')
              .doc(widget.requestId)
              .snapshots(),
        builder: (context,snapshot){
          if(snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }
          if(!snapshot.hasData || !snapshot.data!.exists){
              return const Center(child: CircularProgressIndicator());
          }
          // get data from the snapshot
          var victimData=snapshot.data!.data() as Map<String,dynamic>;

          String status = victimData['status'] ?? 'pending';
          // Victim location
          double victimLat = victimData['location']['lat'];
          double victimLng = victimData['location']['lng'];
          LatLng victimLatLng = LatLng(victimLat, victimLng);
          String? responderId = victimData['responderId']; // Using ID instead of snapshot
          String serviceType = victimData['serviceType'] ?? 'Ambulance';
          BitmapDescriptor responderIcon =_responderIcons[serviceType] ?? BitmapDescriptor.defaultMarker;


          // 2. Nest the second stream to listen to the Responder's Live Collection (VIMP: the code runs whenever the location of the responder changes)
            return StreamBuilder<DocumentSnapshot>(
                stream: (status == 'assigned' && responderId != null)
                    ? FirebaseFirestore.instance.collection('responders').doc(responderId).snapshots()
                    : const Stream.empty(),
                builder: (context, responderSnapshot) {

                    LatLng? responderLatLng;
                    Map<String, dynamic>? responderData;
                    if (responderSnapshot.hasData && responderSnapshot.data!.exists){
                        responderData = responderSnapshot.data!.data() as Map<String, dynamic>;
                        // Extract live location from the Source of Truth
                        if (responderData['location'] != null) {
                            responderLatLng = LatLng(
                            responderData['location']['lat'],
                            responderData['location']['lng'],
                            );
                        }
                    }

                    if (responderLatLng != null) {
                        final now = DateTime.now();
                        if (_lastEtaFetch == null || now.difference(_lastEtaFetch!) > const Duration(seconds: 30)) {  //even if the responder location changes still updating after 30 seconds
                            _lastEtaFetch = now;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                _refreshETA(responderLatLng!, victimLatLng);
                            });
                        }
                    }

                    Set<Marker> markers = {};

                    //Victim marker (always visible)
                    markers.add(
                        Marker(
                        markerId: const MarkerId('victim'),
                        position: victimLatLng,
                        icon: _victimIcon ?? BitmapDescriptor.defaultMarker,
                        infoWindow: const InfoWindow(title: "Victim Location"),
                        ),
                    );


                     // Responder marker (only when assigned)
                    if (responderLatLng != null) {
                        markers.add(
                        Marker(
                            markerId: const MarkerId('responder'),
                            position: responderLatLng,
                            icon: responderIcon,
                            infoWindow: const InfoWindow(title: "Responder Location"),
                        ),
                        );
                    }


                    if (_mapController != null) {
                        _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(victimLatLng, 15),
                        );
                    }

                    // draw the path
                    if (responderLatLng != null && polylineCoordinates.isEmpty) {
                      getPolyline(
                        responderLatLng,
                        victimLatLng,
                      ); //converting latlng to polylineCoordinates
                    } else if (status != 'assigned') {
                      polylineCoordinates.clear(); // Clear path if not assigned
                    }

                     // to fit the zoom
                    if (status == 'assigned' && responderLatLng != null) {
                      // Call this once or when locations change significantly
                      _fitMapToMarkers(victimLatLng, responderLatLng);
                    }


                    return buildUI(context,markers,victimData,responderData);
                },

          );
        }
      )
    );
  }

  Stack buildUI(BuildContext context,Set<Marker> markers,Map<String,dynamic> victimData,Map<String,dynamic>? data) {

    String status = victimData['status'] ?? 'pending';
    final headerText = _getHeaderText(status);
    String serviceType = victimData['serviceType'] ?? 'Ambulance';
    double victimLat = victimData['location']['lat'];
    double victimLng = victimData['location']['lng'];
    LatLng victimLatLng = LatLng(victimLat, victimLng);

    return Stack(
            children: [

              //1. Placeholder for your map widget
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8, //screen occupied by google map container
                    width: double.infinity,
                    child: GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: victimLatLng,
                        zoom: 15,
                      ),
                      markers: markers,
                      polylines: {
                        if (polylineCoordinates
                            .isNotEmpty) //only updating if we have the polyline coordinates
                          Polyline(
                            polylineId: const PolylineId("route"),
                            color: const Color(0xFF2C5E67), // Use your brand teal
                            points: polylineCoordinates,
                            width: 5,
                          ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),

                  const Expanded(child: SizedBox.shrink()),
                ],
              ),

              // 2. Floating Header Card
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0F7), // light blue-grey
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [

                        // Back Button
                        GestureDetector(
                          onTap: () {
                            if (widget.fromEmergencyFlow) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => MainScreen()),
                                (route) => false,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),


                        //Text Section (take the left out space between the two)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                headerText['label']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.4,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                headerText['value']!,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                ),
              ),

              //3. ZOOM IN/ZOOM OUT BUTTON
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.25,
                right: 16,
                child: Column(
                children: [
                    FloatingActionButton(
                      heroTag:
                          "zoomIn", // Unique tag required if using multiple FABs
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2C5E67),
                      onPressed: _zoomIn,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: "zoomOut",
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2C5E67),
                      onPressed: _zoomOut,
                      child: const Icon(Icons.remove),
                    ),
                ],
                ),
              ),

              //4. Swipeable information sheet
              DraggableScrollableSheet(
                initialChildSize: 0.25,
                minChildSize: 0.25,
                maxChildSize: 0.55,
                builder: (context,scrollController){
                  return Container(
                    decoration: BoxDecoration(
                                  color: Color(0xFFBADFDB), // 1. Light grey background for the "base"
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
                      children: [
                        //1. Pull handle for visual cue
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20,top: 10),
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          )
                        ),

                        //3. Responder Info Box (Visible only if assigned)
                        if (status == 'assigned' &&  data!=null)
                          _buildFloatingWhiteBox(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage(
                                    getServicePersonIconPath(serviceType),
                                  ),
                                ), //In future to add the responder profile picture

                                // Icon(Icons.person, size: 22),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Responders details",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        data['full_name'] ?? 'Hero Name',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.green),
                                  onPressed: () {}, // Add dialer logic
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 15),

                        buildReqSummaryUI(victimData, context, serviceType),

                        const SizedBox(height: 15),

                        if(status == 'pending')
                          buildCancelButton(context,widget.requestId),

                      ],
                    ),
                  );
                },
              )
            ]
          );
  }
}
