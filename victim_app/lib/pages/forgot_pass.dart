import 'package:flutter/material.dart';
import 'package:smart_108/components/text_fields.dart';
import 'package:smart_108/utils/auth_service.dart';

class ForgotPassPage extends StatefulWidget {
  const ForgotPassPage({super.key});

  @override
  State<ForgotPassPage> createState() => _ForgotPassPageState();
}

class _ForgotPassPageState extends State<ForgotPassPage> {
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBADFDB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2596be)),
          onPressed: () {
            // Manually trigger the pop to return to the Login Screen
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsetsGeometry.symmetric(horizontal: 25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Smart 108",
              style: TextStyle(
                color: Color(0xFF2596be),
                fontWeight: FontWeight.bold,
                fontSize: 35,
              ),
            ),
            const Icon(Icons.lock_reset,size: 100, color: Color(0xFF2596be)),
            const SizedBox(height: 20),
            const Text(
              "Don’t worry, we’ll help you reset it",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6), // Semi-transparent
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),

                child: Column(
                  children: [
                      buildTextField(
                        emailController,
                        "Enter your registered email id",
                        Icons.email,
                        (val) => !val!.contains('@') ? "Invalid Email" : null,
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {

                          // 1. Send Reset Email
                          String? error = await AuthService().sendPasswordResetEmail(
                            emailController.text,
                          );

                          if(!context.mounted) return;

                          if (error == null) {
                            // 2. Show Success Message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Reset link sent! Check your email.")),
                            );

                            // 3. POP back to Login Page
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
                        child: const Text("RESET PASSWORD", style: TextStyle(color: Colors.white)),
                        ),
                      )
                  ]),
            )

          ],
        ),
        )
    );
  }
}
