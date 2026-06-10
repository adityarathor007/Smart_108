import 'package:flutter/material.dart';
import 'package:smart_108_responders/theme/app_colors.dart';
import 'package:smart_108_responders/utils/authService.dart';

Widget listWidget(BuildContext context, IconData icon, String main, String submain, Widget tw, String page){
    return ListTile(
        leading: CircleAvatar(
            backgroundColor: AppColors.card,
            child: Icon(icon, color: Colors.white),
        ),
        title: Text(
                    main,
                    style: TextStyle(
                        color: AppColors.iconColor,
                    ),
                ),
        subtitle: Text(submain,style: TextStyle(color: Colors.white)),
        trailing: tw,
        onTap: () {
            //Navigate to profile
            Navigator.pushNamed(context, page);
        },
    );
}

class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({super.key});

@override
Widget build(BuildContext context) {


    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        ),
        body: ListView(
        children: [
            const SizedBox(height: 20),

            listWidget(
                context,
                Icons.person,
                "My Profile",
                "View and manage your details",
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconColor),
                '/profile'
            ),

            listWidget(
                context,
                Icons.history_sharp,
                "Previous Requests",
                "View your completed requests",
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconColor),
                '/e_requests'
            ),


            const Divider(),

            listWidget(context, Icons.info_rounded, "About Smart 112", "",  Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconColor,), '/profile')

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
