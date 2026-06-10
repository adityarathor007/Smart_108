import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_108_responders/pages/home.dart';

class OfflineMapOverlay extends StatelessWidget {
  final UserStatus userStatus;
  const OfflineMapOverlay({super.key,required this.userStatus});

  @override
  Widget build(BuildContext context) {
    String? currStatus= userStatus.status;

    if(currStatus!="offline") return const SizedBox.shrink();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off,color: Colors.white,size: 42),
            SizedBox(height: 12),
            Text(
              "To show you location, \ngo online",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500
              )
            )
          ],
        )
      )
    );
  }
}
