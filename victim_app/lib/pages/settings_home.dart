import 'package:flutter/material.dart';
import 'package:smart_108/utils/auth_service.dart';

class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool hasActiveRequest=true;

    return Scaffold(
      backgroundColor: Color(0xFFBADFDB),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text("My Profile"),
            subtitle: const Text("View and manage your details"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: (){
              //Navigate to profile
               Navigator.pushNamed(context, '/profile');
            }
          ),

          // const Divider(),

          // Emergency Request Tile
          ListTile(
             leading: const CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.emergency_share, color: Colors.white),
            ),
            title: const Text("Emergency Requests"),
            subtitle: const Text("Track live responders or view history"),
            trailing: SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if(hasActiveRequest)
                    const Badge(
                      label: Text("Active"),
                      backgroundColor: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
            onTap: (){
              //Navigate to History Page
              Navigator.pushNamed(context,'/e_requests');
            },
          ),

          const Divider(),

          // ---ADDITIONAL OPTIONS ---
         ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.info_rounded, color: Colors.white),
            ),
            title: const Text("About Smart 112"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              //Navigate to profile
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),

      //signout button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await AuthService().signOut();
        },
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        backgroundColor: Colors.redAccent,
      ),

    );
  }
}
