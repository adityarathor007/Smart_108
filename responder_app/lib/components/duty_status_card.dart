import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_108_responders/pages/home.dart';
import 'package:smart_108_responders/theme/app_colors.dart';
import 'package:smart_108_responders/utils/app_logger.dart';
import 'package:smart_108_responders/utils/draggable_comps.dart';
import 'package:smart_108_responders/utils/funcs.dart';

class DutyStatusCard extends StatefulWidget {
    final UserStatus userStatus;
    const DutyStatusCard({super.key, required this.userStatus});


  @override
  State<DutyStatusCard> createState() => _DutyStatusCardState();
}

class _DutyStatusCardState extends State<DutyStatusCard> {
    bool _isToggleLoading = false;



    Future<void> _toggleAvailabilityWithLocation(String? status) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        setState(() => _isToggleLoading = true); // Start Loading

        try{
            final userRef = FirebaseFirestore.instance
            .collection('responders')
            .doc(user.uid);

            // Going online
            if (status=="offline") {
                final position = await getCurrentLocation();

                final placemarks = await placemarkFromCoordinates(position.latitude,position.longitude);
                final place = placemarks.first;
                final address = "${place.street}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea} - ${place.postalCode}";
                final city=place.locality;

                await userRef.set({
                    'status': "free",
                    'city': city,
                    'location': {'lat': position.latitude, 'lng': position.longitude},
                    'address': address,
                    'lastUpdated': FieldValue.serverTimestamp()},
                    SetOptions(merge: true));
            }

             // Going offline
            else if(status=="free"){
                await userRef.set({
                    'status': "offline",
                    'lastUpdated': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
            }
        }finally{
            if(mounted) setState(() => _isToggleLoading=false);
        }

    }


    Future<void> _markAsArrived(String requestId) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // 2. Update Responder Collection
        await FirebaseFirestore.instance
            .collection('responders')
            .doc(user.uid)
            .update({
                'status': 'on-site', // This stops the stream in your HomeScreen logic
            });

        // 3. Update Emergency Request Collection
        await FirebaseFirestore.instance
            .collection('emergency_requests')
            .doc(requestId)
            .update({
                'status': 'arrived',
                'arrivalTime': FieldValue.serverTimestamp(), // Useful for analytics
            });

        logger.d("Status changed to On-Site. Broadcast stopped.");
    }


    Future<void> _markAsCompleted(String requestId) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // 2. Update Responder Collection
        await FirebaseFirestore.instance
            .collection('responders')
            .doc(user.uid)
            .update({
            'status': 'free', // This stops the stream in your HomeScreen logic
            'currentRequestId': null,
            });

        // 3. Update Emergency Request Collection
        await FirebaseFirestore.instance
            .collection('emergency_requests')
            .doc(requestId)
            .update({
            'status': 'completed',
            'completionTime': FieldValue.serverTimestamp(), // Useful for analytics
            });

        logger.d("Status changed to On-Site. Broadcast stopped.");
    }

    @override
    Widget build(BuildContext context) {
        if (widget.userStatus.status == null) {
            return const Center(child: CircularProgressIndicator());
        }

        return DraggableScrollableSheet(
              initialChildSize: widget.userStatus.status == "assigned" ? 0.25 : 0.25, // Height when first loaded (25% of screen) 
              minChildSize: 0.25, // Minimum height when collapsed
              maxChildSize: 0.55, // Maximum height when fully pulled up
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                  color: AppColors.background, // 1. Light grey background for the "base"
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: ListView(
                  controller:
                      scrollController, // Vital: Syncs swipe with scrolling
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                  ),
                  children: [

                    //1. Pull handle for visual cue
                    Center(
                      child: Container(
                          margin: const EdgeInsets.only(
                          bottom: 20,
                          top: 10,
                          ),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                          ),
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                          children: [
                              const Text(
                              "Duty Status",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                              ),
                              ),
                              const Spacer(),
                              Icon(
                              Icons.circle,
                              size: 10,
                              color: widget.userStatus.status!="offline" ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                              widget.userStatus.status ?? "Loading...", // can be free, offline, assigned
                              style: const TextStyle(color: Colors.white70),
                              ),
                          ],
                        ),

                      ]
                    ),

                    const SizedBox(height: 16),

                    // 2.Victim Information
                    if (widget.userStatus.status == "assigned" ||  widget.userStatus.status == 'on-site')
                      StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
                        stream: FirebaseFirestore.instance
                          .collection('emergency_requests')
                          .doc(widget.userStatus.requestId)
                          .snapshots(),
                        builder:(context,snapshot){

                          // logger.d(widget.userStatus.status);
                          // logger.d(snapshot);

                          if(!snapshot.hasData || !snapshot.data!.exists){
                            return const SizedBox.shrink();
                          }

                          // logger.d("not reached here");

                          final data=snapshot.data!.data()!;
                          final victimName=data['userName'] ?? "Unknown";
                          // final emergency_type
                          final phone=data['userPhone'];

                          return buildFloatingBox(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Victim Details",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    letterSpacing: 0.5
                                  )
                                ),

                                const SizedBox(height: 14),

                                // Victim details
                                Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.blueGrey,
                                      child: const Icon(Icons.person, color: Colors.white),
                                    ),

                                    const SizedBox(width: 12),

                                    Text(
                                      victimName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    Spacer(),

                                    if (phone != null)
                                      SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Material(
                                          color: Colors.blue,
                                          shape: const CircleBorder(),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(Icons.call, color: Colors.white, size: 22),
                                            onPressed: () {
                                              // launch("tel:$phone");
                                            },
                                          ),
                                        ),
                                      ),
                                  ]
                                ),

                                const SizedBox(height: 5),


                              ]
                            )
                          );

                        }
                      ),

                        //3. For Mark as Arrived
                        if (widget.userStatus.status == "assigned")
                        SizedBox(
                                height: 55,
                                child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2C5E67), // Your brand teal
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                    ),
                                    onPressed: () {
                                    if (widget.userStatus.requestId != null) {
                                        _markAsArrived(widget.userStatus.requestId!); // Stops broadcast & updates status
                                    }
                                    },
                                    icon: const Icon(Icons.emergency_share_outlined),
                                    label: const Text(
                                    "MARK AS ARRIVED",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                    ),
                                    ),
                                )
                            ),


                    // 4. for changing on-site to free
                    if (widget.userStatus.status == "on-site")
                        SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xFF2C5E67,
                            ), // Your brand teal
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            ),
                            onPressed: () {
                            if (widget.userStatus.requestId != null) {
                                _markAsCompleted(
                                widget.userStatus.requestId!,
                                ); // Stops broadcast & updates status
                            }
                            },
                            icon: const Icon(Icons.done_outline),
                            label: const Text(
                            "MARK AS COMPLETED",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                            ),
                            ),
                        ),
                        ),


                    if (widget.userStatus.status == "assigned")
                      SizedBox(height: 16),

                    //4. To toogle the status from offline to free and vice versa
                    if (widget.userStatus.status == "offline" || widget.userStatus.status == "free")
                      buildFloatingBox(
                        child: InkWell(
                          onTap: widget.userStatus.status == "assigned"
                          ?(){
                              ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                  "Please complete your active request first",
                                  ),
                              ),
                              );
                          }
                          : () async {
                              try {
                                  await _toggleAvailabilityWithLocation(widget.userStatus.status);
                              } catch (e) {
                                  debugPrint(e.toString());
                              }
                          },
                          hoverColor: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF404258),
                                    borderRadius: BorderRadius.circular(10),
                                ),
                                child: _isToggleLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator( //loader by the time it fetches the location
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                        )
                                        : Icon(
                                            Icons.power_settings_new,
                                            color: widget.userStatus.status == "assigned"
                                                ? Colors.grey
                                                : (widget.userStatus.status == "free"
                                                    ? Colors.red
                                                    : Colors.green),
                                        ),
                            ),

                            const SizedBox(width: 14),

                              Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      Text(
                                          widget.userStatus.status == "assigned"
                                              ? "On Active Duty"
                                              : (widget.userStatus.status == "free"
                                                  ? "Go Offline"
                                                  : "Go Available"),
                                          style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          widget.userStatus.status == "assigned"
                                          ? "Finish request to toggle status"
                                          : (widget.userStatus.status == "free"
                                                  ? "Tap to stop receiving alerts"
                                                  : "Tap to start receiving alerts"),
                                          style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                          ),
                                      ),
                                      ],
                                  ),
                                  ),

                            ],
                          ),
                        )

                      ),
                  ]
                )
                );

              }

        );

    }
}
