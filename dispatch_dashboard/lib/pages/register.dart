import 'package:flutter/material.dart';
import 'package:smart_108_cc/components/text_fields.dart';
import 'package:smart_108_cc/utils/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible=false;
  bool _isConfirmPasswordVisible=false;

  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);

    //call the register service
    String? result = await AuthService().registerDispatcher(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text
      );

    setState(() => _isLoading = false);

     if(result=="success"){
       Navigator.pushReplacementNamed(context, '/login');

       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account Created successfully, now you can use those credentials to login"), backgroundColor: Colors.green),
      );
     }
     else{
      //Show the error message returned from service
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result!), backgroundColor: Colors.red),
      );
     }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () =>  Navigator.pop(context),
        )
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Dispatcher Registration",style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
              const SizedBox(height: 20),

              buildTextField(
                _nameController,
                "Full Name",
                Icons.person,
                (val) => val!.isEmpty ? "Enter your name" : null,
              ),

             const SizedBox(height: 15),

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
                () => setState(() => _isPasswordVisible=!_isPasswordVisible),
                (val) => val!.length < 6 ? "Min 6 characters" : null,
              ),

            const SizedBox(height: 15),

             buildPasswordField(
                _confirmPasswordController,
                "Confirm Password",
                Icons.lock_reset,
                _isConfirmPasswordVisible,
                () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                (val) => val != _passwordController.text ? "Password don't match" : null,
              ),


              const SizedBox(height: 25),

              _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('REGISTER'),
                )

            ],
          )
        )
      )

    );
  }
}
