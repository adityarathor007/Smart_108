import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:smart_108_responders/pages/home.dart';
import 'package:smart_108_responders/utils/app_logger.dart';
import 'package:smart_108_responders/utils/funcs.dart';

// class AddressBar extends StatefulWidget {
//   final UserStatus userStatus;
//   const AddressBar({super.key, required this.userStatus});

//   @override
//   State<AddressBar> createState() => _AddressBarState();
// }

// class _AddressBarState extends State<AddressBar> {
//     bool isResetLoading = false;

//     int cooldownSeconds = 0;
//     Timer? cooldownTimer;

//     void startCooldown() {
//         setState(() => cooldownSeconds = 120); // Set to 120 seconds
//         cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//         if (cooldownSeconds == 0) {
//             timer.cancel();
//         } else {
//             setState(() => cooldownSeconds--);
//         }
//         });
//     }

//     Future<void> _refreshLocationManual() async {
//         if (cooldownSeconds > 0 || isResetLoading) return; //preventing loading if in cooldown period or already request sent for updating the location

//         final user = FirebaseAuth.instance.currentUser;
//         if (user == null) return;

//         setState(() => isResetLoading = true); // Start the rotation/loading

//         try {
//             // 1. Get high-accuracy position
//             final position = await getCurrentLocation();

//             // 2. Reverse Geocode (Get Address)
//             final placemarks = await placemarkFromCoordinates(
//             position.latitude,
//             position.longitude,
//             );
//             final place = placemarks.first;
//             final address =
//                 "${place.street}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea} - ${place.postalCode}";
//             final city = place.locality;

//             logger.d("The address is: ");
//             logger.d(address);

//             // 3. Update Firestore
//             await FirebaseFirestore.instance
//                 .collection('responders')
//                 .doc(user.uid)
//                 .update({
//                 'city': city,
//                 'location': {'lat': position.latitude, 'lng': position.longitude},
//                 'address': address,
//                 'lastUpdated': FieldValue.serverTimestamp(),
//                 });

//             logger.d("Location manually reset successfully");
//         } catch (e) {
//             logger.e("Error resetting location: $e");
//         } finally {
//             setState(() => isResetLoading = false); // Stop the loading animation
//         }
//     }



//   @override
//   void dispose() {
//     cooldownTimer?.cancel();
//     super.dispose();
//   }
//   @override
//   Widget build(BuildContext context) {


//     logger.d(widget.userStatus.status);
//     logger.d(widget.userStatus.address);

//     String timeLabel = widget.userStatus.lastUpdated != null
//         ? formatTimeAgo(widget.userStatus.lastUpdated!)
//         : "Checking...";

//     return Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//         color: Colors.black.withValues(alpha: 0.6),
//         borderRadius: BorderRadius.circular(14),
//         ),
//         child: Row(
//         children: [

//             //1. The location icon
//             Icon(
//                 Icons.location_on,
//                 color: widget.userStatus.status!="offline" ? Colors.green : Colors.orange,
//             ),
//             const SizedBox(width: 8),

//              //2. The address and last update stat
//             Expanded(
//             child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                 Text(
//                     widget.userStatus.status != "offline"
//                         ? (widget.userStatus.address ?? "Fetching location...")
//                         : "To show your location, go online",
//                     style: const TextStyle(color: Colors.white, fontSize: 14),
//                     maxLines: 3,
//                     overflow: TextOverflow.ellipsis,
//                 ),
//                 if (widget.userStatus.status != "offline" && widget.userStatus.lastUpdated != null)
//                     Padding(
//                     padding: const EdgeInsets.only(top: 2),
//                     child: Text(
//                         "Updated: $timeLabel",
//                         style: TextStyle(
//                         color: Colors.white.withValues(alpha: 0.8),
//                         fontSize: 12,
//                         ),
//                     ),
//                     ),
//                 ],
//             ),
//             ),

//             const SizedBox(width: 12),

//             // 3. Refresh the location
//             GestureDetector(
//                 onTap: widget.userStatus.status != "offline" && !isResetLoading
//                     ? _refreshLocationManual
//                     : null,
//                 child: isResetLoading
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                     )
//                     : cooldownSeconds > 0
//                         ? Text(
//                             "${cooldownSeconds}s",
//                             style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             ),
//                         )
//                         : Icon(
//                             Icons.refresh_rounded,
//                             color: Colors.green,
//                             size: 24,
//                         ),
//             )

//             // if (widget.userStatus.status != "offline" && widget.userStatus.lastUpdated != null)
//             // Icon(
//             //     Icons.refresh_rounded,
//             //     color: Colors.green,
//             // )
//         ],
//         ),
//     );
//     }
// }


class AddressBar extends StatefulWidget {
  final String? status;
  final String? responderAddress;
  final String? victimAddress;
  final DateTime? lastUpdated;
  final bool isLoading;
  final int cooldownSeconds;
  final VoidCallback? onRefresh;

  const AddressBar({
    super.key,
    required this.status,
    this.responderAddress,
    this.victimAddress,
    this.lastUpdated,
    this.isLoading = false,
    this.cooldownSeconds = 0,
    this.onRefresh,
  });

  @override
  State<AddressBar> createState() => _AddressBarState();
}

class _AddressBarState extends State<AddressBar> {
    bool isResetLoading=false;
    int cooldownSeconds=0;
    Timer? cooldownTimer;

    void startCooldown(){
        setState(() => cooldownSeconds = 60); //set 120 seconds;
        cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer){
            if(cooldownSeconds==0){
                timer.cancel();
            }
            else{
                setState(() => cooldownSeconds--);
            }
        });
    }



    Future<void> _refreshLocationManual() async {
        if (cooldownSeconds > 0 || isResetLoading) return; //preventing loading if in cooldown period or already request sent for updating the location

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        setState(() => isResetLoading = true); // Start the rotation/loading

        try {
            // 1. Get high-accuracy position
            final position = await getCurrentLocation();

            // 2. Reverse Geocode (Get Address)
            final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
            );
            final place = placemarks.first;
            final address =
                "${place.street}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea} - ${place.postalCode}";
            final city = place.locality;

            // logger.d("The address is: ");
            // logger.d(address);

            // 3. Update Firestore (trigger home screen update where the location stream and status stream both get triggered)
            await FirebaseFirestore.instance
                .collection('responders')
                .doc(user.uid)
                .update({
                'city': city,
                'location': {'lat': position.latitude, 'lng': position.longitude},
                'address': address,
                'lastUpdated': FieldValue.serverTimestamp(),
                });

            logger.d("Location manually reset successfully");
            startCooldown();
        } catch (e) {
            logger.e("Error resetting location: $e");
        } finally {
            setState(() => isResetLoading = false); // Stop the loading animation
        }
    }

    @override
    void dispose() {
      cooldownTimer?.cancel();
      super.dispose();
    }


  @override
  Widget build(BuildContext context) {
    final bool isAssigned = widget.status == "assigned";
    final bool isOffline = widget.status == "offline";

    final displayAddress = isAssigned
        ? (widget.victimAddress ?? "Fetching destination...")
        : (widget.responderAddress ?? "Fetching location...");

    final titleText = isOffline
        ? "You are offline"
        : isAssigned
        ? "Heading to emergency"
        : "Your current location";

    final timeLabel = widget.lastUpdated != null ? formatTimeAgo(widget.lastUpdated!) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🔴 Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOffline
                  ? Colors.orange.withValues(alpha: 0.2)
                  : Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: isOffline ? Colors.orange : Colors.green,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          // 🧾 Address + Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  titleText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                // Address
                Text(
                  isOffline
                      ? "Go online to share your location"
                      : displayAddress,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Updated time
                if (!isOffline && timeLabel != null && !isAssigned)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "Updated $timeLabel",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 🔄 Refresh Button (only when NOT assigned)
          if (!isOffline && !isAssigned)
            GestureDetector(
              onTap: (!isResetLoading && cooldownSeconds == 0) ? _refreshLocationManual : null,
              child: isResetLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : cooldownSeconds > 0
                  ? Text(
                      "${cooldownSeconds}s",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.green,
                      size: 22,
                    ),
            ),
        ],
      ),
    );
  }
}
