
import 'package:flutter/material.dart';

// build text field
Widget buildTextField(
  TextEditingController controller,
  String hint,
  IconData icon,
  String? Function(String?)? validator, {
  bool isPhone = false,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFf2596be)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
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
      prefixIcon: Icon(icon, color: const Color(0xFf2596be)),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
