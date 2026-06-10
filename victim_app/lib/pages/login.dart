import 'package:flutter/material.dart';
import 'package:smart_108/components/text_fields.dart';
import 'package:smart_108/routes/app_routes.dart';
import 'package:smart_108/utils/auth_service.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible=false;
  bool _isGoogleLoading = false;

  @override
  Widget build(BuildContext context) {



    return Scaffold(
      backgroundColor: Color(0xFFBADFDB),
      body:Center(
        child:SingleChildScrollView(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // const SizedBox(height: 10),

              //1. THE ICON
              Image.asset('assets/i0.png',height:100),

              const SizedBox(height:10),

              // THE TITLE
              const Text(
                "Smart 108",
                style: TextStyle(
                  color: Color(0xFF2596be),
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                )),

              //Caption
              const Text(
                "Your Safety, Connected.",
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/i2.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6), // Semi-transparent
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),

                child: Column(
                  children: [
                    // Email Field
                    // TextField(
                    //   controller: emailController,
                    //   decoration: InputDecoration(
                    //     hintText: 'Email Address',
                    //     prefixIcon: const Icon(Icons.email_outlined),
                    //     filled: true,
                    //     fillColor: Colors.white.withValues(alpha: 0.8),
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //       borderSide: BorderSide.none,
                    //     ),
                    //   ),
                    // ),
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
                      _isPasswordVisible, () => setState(() => _isPasswordVisible=!_isPasswordVisible),
                      (val) => val!.length < 6 ? "Min 6 characters" : null
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
                            color: Colors.blueGrey,
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
                              SnackBar(content: Text(result), backgroundColor: Colors.red),
                            );
                          }
                        }, //onPressed

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),

                        child: const Text("LOGIN SECURELY",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

                                final result = await AuthService()
                                    .signInWithGoogle();

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
                          style: TextStyle(color: Colors.black87),
                        ),

                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                child: const Text("New User? Create Account", style: TextStyle(color: Color(0xFF00796B))),
              ),
            //   const SizedBox(height: 10),

            ],
          ),
        )
      )
    );
  }
}
