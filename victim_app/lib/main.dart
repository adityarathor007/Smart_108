import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_108/firebase_options.dart';
import 'package:smart_108/pages/forgot_pass.dart';
import 'package:smart_108/routes/routes_generator.dart';
import 'package:smart_108/utils/wrapper.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
