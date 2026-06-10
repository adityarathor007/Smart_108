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
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: const Color(0xFFFF6500)),
      filled: true,
      fillColor: Colors.black,
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
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: const Color(0xFFFF6500)),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility : Icons.visibility_off,
          color: Color(0xFFFF6500),
        ),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: Colors.black,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}


Widget buildDropdownField({
  required String hint,
  required IconData icon,
  required List<String> items,
  required String? value,
  required void Function(String?) onChanged,
  String? Function(String?)? validator,
}) {
  return DropdownButtonFormField<String>(
    value: value,
    hint: Text(hint, style: const TextStyle(color: Colors.white, fontSize: 17)),
    validator: validator,
    onChanged: onChanged,
    dropdownColor: Colors.black,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFFFF6500)),
      filled: true,
      fillColor: Colors.black,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    items: items
        .map(
          (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w400)),
          ),
        )
        .toList(),
  );
}
