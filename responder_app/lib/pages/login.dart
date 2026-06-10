import 'package:flutter/material.dart';
import 'package:smart_108_responders/components/text_fields.dart';
import 'package:smart_108_responders/routes/app_routes.dart';
import 'package:smart_108_responders/utils/authService.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121A1F),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [

              //1. THE ICON
              Image.asset('assets/i0.png', height: 200),

              // THE TITLE
              const Text(
                "Smart 108 Responders",
                style: TextStyle(
                color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                ),
              ),

              //Caption
              const Text(
                "Coordinate. Dispatch. Respond.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Color(0xFF404258),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.transparent,
                  ),
                ),

                child: Column(
                  children: [

                    buildTextField(
                      emailController,
                      "Email Address",
                      Icons.email_outlined,
                      (val) => !val!.contains('@') ? "Invalid Email" : null,
                    ),

                    const SizedBox(height: 15),

                    // Password Field
                    buildPasswordField(
                      passwordController,
                      'Password',
                      Icons.lock,
                      _isPasswordVisible,
                      () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                      (val) => val!.length < 6 ? "Min 6 characters" : null,
                    ),

                    const SizedBox(height: 5),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/forgot_pass'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color(0xFFFF6500),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Firebase Email Login
                          String? result = await AuthService().loginUser(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );

                          if (!context.mounted) return;

                          if (result != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }, //onPressed

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: const Text(
                          "LOGIN SECURELY",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // GOOGLE LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isGoogleLoading
                          ? null
                          : () async {
                              setState(() => _isGoogleLoading = true);

                              final result = await AuthService().signInWithGoogle();

                              if (!mounted) return;

                              setState(() => _isGoogleLoading = false);

                              if (result != null && result != "new_user") {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }, //onPressed

                        icon: _isGoogleLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Image.asset('assets/google.png', height: 20),

                        label: Text(
                          _isGoogleLoading
                              ? "Signing in..."
                              : "Continue with Google",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          side: BorderSide(color: Color(0xFFFF6500)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.register);
                },
                child: const Text(
                  "New User? Create Account",
                  style: TextStyle(color: Color(0xFFFF6500)),
                ),
              ),

              //   const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
