import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_108_responders/components/address_bar.dart';
import 'package:smart_108_responders/components/duty_status_card.dart';
import 'package:smart_108_responders/components/full_screen_map.dart';
import 'package:smart_108_responders/components/offline_map_overlay.dart';
import 'package:smart_108_responders/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';


class   UserStatus {
  final String? serviceType;
  final String? status;
  final double? lat;
  final double? lng;
  final String? address;
  final String? requestId;
  final DateTime? lastUpdated;

  UserStatus({this.serviceType, this.status, this.lat, this.lng, this.address, this.requestId, this.lastUpdated});

factory UserStatus.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return UserStatus();
    }

    logger.d("Creating UserStatus object");
    logger.d("$data['location']?['lat'] and $data['location']?['lng']");

    DateTime? timestamp;
    if (data['lastUpdated'] != null) {
      timestamp = (data['lastUpdated'] as Timestamp).toDate();
    }

    return UserStatus(
      serviceType: data['serviceType'],
      status: data['status'],
      lat: data['location']?['lat'],
      lng: data['location']?['lng'],
      address: data['address'],
      requestId: data['currentRequestId'],
      lastUpdated: timestamp,
    );
  }
}

class UserStatusRepository {
  // stream that updates itself only when anything changes expect location of responder (less frequent updates)
  Stream<UserStatus> statusStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('responders')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return UserStatus(
            status: data?['status'],
            requestId: data?['currentRequestId'],
            serviceType: data?['serviceType'],
            address: data?['address'],
            lastUpdated: data?['lastUpdated'] != null
                ? (data?['lastUpdated'] as Timestamp).toDate()
                : null,
          );
        })
        .distinct(
          (a, b) =>
              a.status == b.status &&
              a.requestId == b.requestId &&
              a.serviceType == b.serviceType &&
              a.address == b.address // ✅ ADD THIS
              // a.lastUpdated == b.lastUpdated, // ✅ ADD THIS
        );
  }

  Stream<LatLng> locationStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('responders')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return LatLng(data?['location']['lat'], data?['location']['lng']);
        });
  }

  Future<void> updateLocation(double lat, double lng) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('responders')
        .doc(user.uid)
        .update({
          'location': {'lat': lat, 'lng': lng},
          'lastUpdated':
              FieldValue.serverTimestamp(),
        });
  }
}


class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});

    @override
    State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
    final _repo = UserStatusRepository();
    final GlobalKey<FullScreenMapState> _mapKey = GlobalKey();
    String? _lastStatus;
    LatLng?_currentVictimLocation; // To store the coordinate for the Navigate button
    String? _currentVictimAddress;
    StreamSubscription<UserStatus>? _statusSubscription;
    StreamSubscription<Position>? _positionStream;


  // @override
  // void initState() {
  //   super.initState();
  //   // Listen to the stream. If they were 'assigned' and closed the app,
  //   // this will resume the broadcast as soon as they re-open it.
  //   _repo.stream().listen((userStatus) {
  //     if (userStatus.status == "assigned") {
  //       _startLiveBroadcast();
  //     } else {
  //       _stopLiveBroadcast();
  //     }
  //   });
  // }

    @override
    void initState() {
      super.initState();

      // listener for starting/stoping GPS as when the status changes from assigned to onsite it triggers
      _statusSubscription =_repo.statusStream().listen((userStatus) {

        // logger.d(userStatus.status);
        // logger.d(userStatus.lat);
        if (userStatus.status != _lastStatus) {
          _handleStatusChange(userStatus.status);
          _lastStatus = userStatus.status;
        }
      });
    }


    @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

    // used to update the location in db
    void _startLiveBroadcast() {
        if (_positionStream != null) return; // Already broadcasting

        _positionStream =
            Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, // Necessary for real-time tracking
                distanceFilter: 5, // Update every 5 meters moved
            ),
            ).listen((position) {
            // logger.d("Updating the location: $position");
            _repo.updateLocation(position.latitude, position.longitude); //sends that data to Firebase Firestore.
            },
            onError: (error) {
                logger.e(
                "GPS Stream Error: $error",
                ); // This will tell you if permissions are missing
            },
            );

    }

    void _stopLiveBroadcast() {
        _positionStream?.cancel();
        _positionStream = null;
    }



    Future<void> _checkPermissions() async {
        bool serviceEnabled;
        LocationPermission permission;

        // Check if location services are enabled
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
        logger.e('Location services are disabled.');
        return;
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission(); // This triggers the popup
        if (permission == LocationPermission.denied) {
            logger.e('Location permissions are denied');
            return;
        }
        }

        if (permission == LocationPermission.deniedForever) {
        logger.e(
            'Location permissions are permanently denied, we cannot request permissions.',
        );
        return;
    }

    logger.d("Live Broadcast started");
    // If we reach here, permissions are granted!
    _startLiveBroadcast();
  }

  void _handleStatusChange(String? newStatus) {
    if (newStatus == "assigned") {
          // This now only runs ONCE when you get assigned
          _checkPermissions();
          // _stopLiveBroadcast();
      } else {
          _stopLiveBroadcast();
      }
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    // Mode 'd' starts turn-by-turn navigation directly
    final url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback for iOS/Browser if the protocol above fails
      final fallbackUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
  }


    @override
    Widget build(BuildContext context) {

    // reacting the changes based on fields changed in statusStream so that home screen UI can be updated
    return StreamBuilder<UserStatus>(
      stream: _repo.statusStream(),
      builder: (context, snapshot) {

        logger.d("Home screen BUILD CALLED");

        final userStatus = snapshot.data ?? UserStatus();
        return _buildUI(userStatus);
      },
    );
  }



    Widget _buildUI(UserStatus userStatus) {
        return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Stack(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Column(
                    children: [
                    FullScreenMap(
                        key: _mapKey,
                        userStatus: userStatus,
                        repo: _repo,
                        onVictimLocationUpdate: (location) {
                          setState(() {
                            _currentVictimLocation = location;
                          });
                        },
                        onVictimAddressUpdate: (address) {
                          setState(() {
                            _currentVictimAddress = address;
                          });
                        },
                    ),
                    ],
                ),

                Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: AddressBar(
                    status: userStatus.status,
                    responderAddress: userStatus.address,
                    victimAddress: _currentVictimAddress,
                    lastUpdated: userStatus.lastUpdated,
              )
                ),

                Positioned.fill(child: OfflineMapOverlay(userStatus: userStatus)),

                // Your Navigate Button:
                if (userStatus.status == "assigned" && _currentVictimLocation != null)
                  Positioned(
                    bottom: 210,
                    left: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () => _launchNavigation(
                        _currentVictimLocation!.latitude,
                        _currentVictimLocation!.longitude,
                      ),
                      label: const Text("Navigate"),
                      icon: const Icon(Icons.navigation),
                    ),
                  ),


                Positioned(
                    bottom: 320,
                    right: 16,
                    child: FloatingActionButton(
                        mini: true,
                        heroTag: "mylocation",
                        onPressed:() => _mapKey.currentState?.goToMyLocation(),
                        child: const Icon(Icons.my_location),
                        ),
                ),


                // Zoom In/Out buttons
                Positioned(
                    right:16,
                    bottom: 210,
                    child: Column(
                    children: [
                        FloatingActionButton(
                        mini: true,
                        heroTag: "zoomIn",
                        onPressed:() => _mapKey.currentState?.zoomIn(),
                        child: const Icon(Icons.add),
                        ),
                        const SizedBox(height:5),
                        FloatingActionButton(
                        mini: true,
                        heroTag: 'zoomOut',
                        onPressed: () => _mapKey.currentState?.zoomOut(),
                        child: const Icon(Icons.remove),
                        )
                    ],
                    ),
                ),


                Positioned.fill(
                  child: DutyStatusCard(userStatus: userStatus),
                ),
            ],
            ),
        ),
        );
    }

}
