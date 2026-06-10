import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_108_cc/components/text_fields.dart';
import 'package:smart_108_cc/utils/auth_service.dart';
import 'package:smart_108_cc/utils/theme_provider.dart';

enum UserRole { dispatcher, admin }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.dispatcher;
  bool _isLoading = false;
  bool _isPasswordVisible=false;

  void _handleLogin() async{
    setState(() => _isLoading = true);

    //call the service
    String? result = await AuthService().loginUser(
      email: _emailController.text,
      password: _passwordController.text,
      isAdmin: _selectedRole == UserRole.admin
    );

    setState(() => _isLoading = false);

    if(result=="admin_success"){
      Navigator.pushReplacementNamed(context, '/admin-dash');
    } else if(result == "dispatcher_success"){
      Navigator.pushReplacementNamed(context, '/dispatcher-dash');
    } else{
      //Show the error message returned from service
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result!), backgroundColor: Colors.red),
      );
    }


  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children:[

          // 1. The Theme Toggle (Top Right)
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                // Optional: change color based on theme for better visibility
                color: themeProvider.isDarkMode
                    ? Colors.yellow[700]
                    : Colors.grey[800],
              ),
              tooltip: 'Toggle Theme',
            ),
          ),


          Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Login to Portal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // SELECT login user role
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(
                      value: UserRole.dispatcher,
                      label: SizedBox(
                        width: 100, // Fixed width for both
                        child: Center(child: Text("Dispatcher")),
                        ),
                      ),
                    ButtonSegment(
                      value: UserRole.admin,
                      label: SizedBox(
                        width: 100, // Fixed width for both
                        child: Center(child: Text("Admin")),
                        ),
                      ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (set) => setState(() => _selectedRole = set.first),
                ),
                const SizedBox(height: 20),

                // login text fields
                buildTextField(
                  _emailController,
                  "Email",
                  Icons.email,
                  (val) => !val!.contains('@') ? "Invalid Email" : null,
                ),

                const SizedBox(height: 15),

                buildPasswordField(
                  _passwordController,
                  "Password",
                  Icons.lock,
                  _isPasswordVisible,
                  () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  (val) => val!.length < 6 ? "Min 6 characters" : null,
                ),

                const SizedBox(height: 25),

                _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text("SIGN IN")
                  ),

                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('New Dispatcher? Register here')
                )

              ],
            )
          )
        ),
        ]
      )
    );
  }
}
