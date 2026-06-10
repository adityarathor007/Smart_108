import 'package:flutter/material.dart';
import 'package:smart_108_responders/utils/authService.dart';
import '../components/text_fields.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final TextEditingController confirmPass = TextEditingController();
  String? selectedService;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121A1F),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                //THE ICON
                Image.asset('assets/i0.png', height: 150),

                //THE TITLE
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

                const SizedBox(height: 30),

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(20),
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
                        name,
                        "Full Name",
                        Icons.person,
                        (val) => val!.isEmpty ? "Enter your name" : null,
                      ),

                      const SizedBox(height: 15),

                      buildTextField(
                        phone,
                        "Phone Number",
                        Icons.phone,
                        (val) =>
                            val!.length != 10 ? "Enter 10 digit number" : null,
                      ),

                      const SizedBox(height: 15),

                      buildDropdownField(
                        hint: "Select Service",
                        icon: Icons.dashboard_customize,
                        items: ["Ambulance", "Police", "Fire Brigade"],
                        value: selectedService,
                        onChanged: (value) {
                          selectedService = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select the service";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      buildTextField(
                        email,
                        "Email Address",
                        Icons.email,
                        (val) => !val!.contains('@') ? "Invalid Email" : null,
                      ),

                      const SizedBox(height: 15),

                      buildPasswordField(
                        pass,
                        "Password",
                        Icons.lock,
                        _isPasswordVisible,
                        () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                        (val) => val!.length < 6 ? "Min 6 characters" : null,
                      ),

                      const SizedBox(height: 15),

                      buildPasswordField(
                        confirmPass,
                        "Confirm Password",
                        Icons.lock_reset,
                        _isConfirmPasswordVisible,
                        () => setState(
                          () => _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible,
                        ),
                        (val) =>
                            val != pass.text ? "Password don't match" : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // 1. Show a loading dialog or spinner
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      // 2. Call the register function
                      String? error = await AuthService().registerUser(
                        email: email.text.trim(),
                        password: pass.text.trim(),
                        fullName: name.text.trim(),
                        phoneNumber: phone.text.trim(),
                        serviceType: selectedService!,
                      );

                      if (!context.mounted) return;

                      // 3. Remove the loading spinner
                      Navigator.of(context, rootNavigator: true).pop();

                      if (error == null) {
                        // remove RegisterPage
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Account created successfully!"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "REGISTER",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Color(0xFFFF6500)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
