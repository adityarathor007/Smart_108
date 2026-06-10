import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_108_responders/pages/home.dart';
import 'package:smart_108_responders/utils/app_logger.dart';


class FullScreenMap extends StatefulWidget {
  final UserStatus userStatus;
  final UserStatusRepository repo;
// NEW: Callback to send victim location back to Home Screen
  final Function(LatLng)? onVictimLocationUpdate;
  final Function(String)? onVictimAddressUpdate;
  const FullScreenMap({GlobalKey<FullScreenMapState>? key, required this.userStatus, required this.repo, this.onVictimLocationUpdate, this.onVictimAddressUpdate}) : super(key: key);
  // const FullScreenMap({GlobalKey<FullScreenMapState>? key, required this.userStatus}) : super(key: key);

  @override
  State<FullScreenMap> createState() => FullScreenMapState();
}

class FullScreenMapState extends State<FullScreenMap> {
    GoogleMapController? _controller;
    LatLng? _lastPosition;
    BitmapDescriptor? _victimIcon;
    Map<String, BitmapDescriptor> responderIcons = {};
    bool iconsLoaded = false;
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    LatLng? myLocation;
    LatLng? _previousLocation;
    double _currentBearing = 0.0;
    Set<Marker> markers = {};
    LatLng? _lastVictimLocation;


    double getBearing(LatLng start, LatLng end) {
        double lat1 = start.latitude * pi / 180;
        double lon1 = start.longitude * pi / 180;
        double lat2 = end.latitude * pi / 180;
        double lon2 = end.longitude * pi / 180;

        double dLon = lon2 - lon1;

        double y = sin(dLon) * cos(lat2);
        double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

        double bearing = atan2(y, x);

        bearing = bearing * 180 / pi;
        bearing = (bearing + 360) % 360;

        return bearing;
    }

    bool hasChanged(LatLng a, LatLng b) {
      return (a.latitude - b.latitude).abs() > 0.00001 ||
          (a.longitude - b.longitude).abs() > 0.00001;
    }


    Future<void> _loadCustomMarker() async {
        _victimIcon = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(80, 50)),
            'assets/marker.png',
        );

          responderIcons['Ambulance'] = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(50, 70)),
            'assets/markers/amb_marker.png',
          );
          responderIcons['Fire Brigade'] = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(60, 80)),
            'assets/markers/fb_marker.png',
          );
          responderIcons['Police'] = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(70, 90)),
            'assets/markers/p_marker.png',
          );

        setState((){
            iconsLoaded = true;
        });
    }

    @override
    void initState() {
        super.initState();
        _loadCustomMarker();
    }

    static const LatLng _fallbackLocation = LatLng(20.5937, 78.9629); // India Center


    void zoomIn() {
        _controller?.animateCamera(CameraUpdate.zoomIn());
    }

    void zoomOut() {
        _controller?.animateCamera(CameraUpdate.zoomOut());
    }

    void goToMyLocation() {
        if (myLocation != null) {
          _animateCamera(myLocation!);
        }

    }




    void _animateCamera(LatLng target) {
        if (_controller == null || _lastPosition == target) return;

        _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(
            target: target,
            zoom: 16,
            ),
        ),
        );

        _lastPosition = target;
    }


    void _fitMapToMarkers(LatLng p1, LatLng p2) {
        if (_controller == null) return;

        // Create the bounds
        LatLngBounds bounds;
        if (p1.latitude > p2.latitude && p1.longitude > p2.longitude) {
        bounds = LatLngBounds(southwest: p2, northeast: p1);
        } else if (p1.longitude > p2.longitude) {
        bounds = LatLngBounds(
            southwest: LatLng(p1.latitude, p2.longitude),
            northeast: LatLng(p2.latitude, p1.longitude),
        );
        } else if (p1.latitude > p2.latitude) {
        bounds = LatLngBounds(
            southwest: LatLng(p2.latitude, p1.longitude),
            northeast: LatLng(p1.latitude, p2.longitude),
        );
        } else {
        bounds = LatLngBounds(southwest: p1, northeast: p2);
        }

        // Animate the camera to fit these bounds
        _controller!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 140), // 80 is the padding in pixels
        );
    }


    void getPolyline(LatLng source, LatLng destination) async {
        // Use the PolylinePoints class to fetch route coordinates between the responder's current LatLng and the victim's LatLng.
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: "<api key>",
            request: PolylineRequest(
            origin: PointLatLng(source.latitude, source.longitude),
            destination: PointLatLng(destination.latitude, destination.longitude),
            mode: TravelMode.driving,
            ),
        );

        // converting the coordinates to polyline object
        if (result.points.isNotEmpty) {
        setState(() {
            polylineCoordinates = result.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
        });
        }
    }

    @override
    Widget build(BuildContext context) {
      return StreamBuilder<LatLng>(
         // rebuilds the map ui as the location is updated in the firestore causing the locationStream to trigger
          stream: widget.repo.locationStream(),
          builder: (context, locationSnapshot) {

            logger.d("Map Rebuild called because responder location is updated ");

            if (!locationSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // logger.d(myLocation);

            final newLocation = locationSnapshot.data!;

            // Update myLocation + bearing
            if (myLocation == null || hasChanged(myLocation!, newLocation)) {
              if (myLocation != null) {
                _currentBearing = getBearing(myLocation!, newLocation);
              }
              myLocation = newLocation;
            }

            markers.clear();

        // 2. Handle the "Assigned" state with a StreamBuilder
        if (widget.userStatus.status == "assigned" && widget.userStatus.requestId != null) {
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('emergency_requests')
                .doc(widget.userStatus.requestId)
                .snapshots(),
            builder: (context, snapshot) {

                if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong"));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                    // logger.d("snapshot has no data");
                    return const Center(child: CircularProgressIndicator());
                }



                // Add Responder Marker
                markers.add(Marker(
                    markerId: const MarkerId('responder'),
                    position: myLocation!,
                    icon: responderIcons[widget.userStatus.serviceType] ?? BitmapDescriptor.defaultMarker,
                    anchor: const Offset(0.5, 0.5),
                    infoWindow: const InfoWindow(title: "My Location"),
                    flat: true,
                    rotation: _currentBearing,
                ));

                // add victim marker
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data()!;
                  LatLng victimLocation = LatLng(data['location']['lat'], data['location']['lng']);
                  String victimAddress =data['referenceAddress'];

                  if (_lastVictimLocation == null ||
                      _lastVictimLocation!.latitude != victimLocation.latitude ||
                      _lastVictimLocation!.longitude != victimLocation.longitude) {

                    _lastVictimLocation = victimLocation;

                    // Updating the victim location
                    logger.d("Victim location updated for parent screen");

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      widget.onVictimLocationUpdate?.call(victimLocation);
                      widget.onVictimAddressUpdate?.call(victimAddress);
                    });
                  }

                  // Add Victim Marker
                  markers.add(Marker(
                      markerId: const MarkerId('victim'),
                      position: victimLocation,
                      icon: _victimIcon ?? BitmapDescriptor.defaultMarker,
                      infoWindow: const InfoWindow(title: "Victim Location"),
                  ));




                    if(polylineCoordinates.isEmpty){
                      getPolyline(myLocation!,victimLocation);
                    }

                    // In assigned mode, fit both markers instead of just animating to one
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fitMapToMarkers(myLocation!, victimLocation);
                    });
                }

                return _buildMap(myLocation!, markers);
            },
            );
        }

        // 3. Handle Free/Offline state (Return standard map)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // now when the responder is free we will be following its location
          _animateCamera(myLocation!);
        });


        markers = {
            Marker(
            markerId: const MarkerId('responder'),
            position: myLocation!,
            icon: responderIcons[widget.userStatus.serviceType] ?? BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: "My Location"),
            flat:true,
            rotation: _currentBearing,
            )
        };

        if(polylineCoordinates.isNotEmpty) polylineCoordinates.clear();



        return _buildMap(myLocation!, markers);
        }
      );
    }

    // Helper method to keep the GoogleMap code DRY (Don't Repeat Yourself)
    Widget _buildMap(LatLng target, Set<Marker> markers) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          width: double.infinity,
          child: GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 16),
              onMapCreated: (controller) => _controller = controller,
              markers: markers,
              polylines:{
                if(polylineCoordinates.isNotEmpty) Polyline(
                  polylineId: const PolylineId("route"),
                  color: const Color(0xFF2C5E67),
                  points: polylineCoordinates,
                  width: 5,
                )
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              compassEnabled: false,
              tiltGesturesEnabled: false,
          ),
        );
    }


}
