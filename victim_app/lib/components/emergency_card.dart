import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_108/pages/LocationPicker.dart';


Widget buildEmergencyCard(
  String title,
  String subtitle,
  String iconAsset,
  VoidCallback onTap
){
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    // color: iconCircleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(iconAsset, width: 120, height: 300),
                ),

                const SizedBox(width: 20),

                // Text info
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              ],
            ),
            )
      )
    ),
  );
}
