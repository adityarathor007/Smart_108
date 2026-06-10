import 'package:flutter/material.dart';


Widget buildTextField(
  TextEditingController controller,
  String hint,
  IconData icon,
  String? Function(String?)? validator, {
  bool isEmail = false,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(),
    ),
  );
}



//build Password Field
Widget buildPasswordField(
  TextEditingController controller,
  String hint,
  IconData icon,
  bool isVisible,
  VoidCallback onToggle,
  String? Function(String?)? validator,
) {
  return TextFormField(
    controller: controller,
    obscureText: !isVisible, //if visible is false, obscure is true
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(),
    ),
  );
}
