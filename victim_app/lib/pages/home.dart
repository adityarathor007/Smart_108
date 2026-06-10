import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_108/components/emergency_card.dart';
import 'package:smart_108/pages/LocationPicker.dart';
import 'package:smart_108/pages/address_options.dart';
import 'package:smart_108/utils/location_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _handleEmergency(String serviceName) async {
    try {
      // 1. Show a loading dialog (optional but recommended so user knows GPS is working)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 3. Close the loading dialog
      if (mounted) Navigator.pop(context);

      // 4. Guard against async gaps
      if (!mounted) return;

      // 5. Navigate to your Map Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectLocationScreen(
            selectedService: serviceName,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if error occurs
      if (mounted) Navigator.pop(context);

      // Show error (e.g., GPS turned off)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFFBADFDB),
      body:Center(
        child:SingleChildScrollView(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const SizedBox(height: 40),

               const Text(
                "Emergency Services",
                style: TextStyle(
                  color: Color(0xFF2C5E67),
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                ),
              ),

              const SizedBox(height: 8),


              const Text(
                "Tap for immediate help",
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),

              const SizedBox(height: 20),


              buildEmergencyCard(
                "Ambulance",
                "Medical emergency",
                'assets/icons/amb.png',
                () => _handleEmergency("Ambulance")
              ),

             const SizedBox(height: 10),

              buildEmergencyCard(
                "Police",
                "Crime or threat",
                'assets/icons/pol.png',
                () => _handleEmergency("Police")
              ),

              const SizedBox(height: 10),

              buildEmergencyCard(
                "Fire Brigade",
                "Fire or explosion",
                'assets/icons/fire.png',
                () => _handleEmergency("Fire Brigade")
              ),


            ]
          )
        )
      )
    );
  }
}
