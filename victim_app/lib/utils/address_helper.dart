import 'package:flutter/material.dart';

IconData getIcon(String? tag) {
  switch (tag) {
    case "Home":
      return Icons.home;
    case "Work":
      return Icons.work;
    default:
      return Icons.location_on;
  }
}

Color getIconColor(String? tag) {
  switch (tag) {
    case "Home":
      return Colors.green;
    case "Work":
      return Colors.blue;
    default:
      return Colors.grey;
  }
}


class Profile {
  final String id;
  final String name;
  final String phone;
  final String? bloodGroup;
  final bool isSelf;

  Profile({
    required this.id,
    required this.name,
    required this.phone,
    this.bloodGroup,
    this.isSelf = false,
  });

  // 🔥 Convert Firestore → Profile
  factory Profile.fromMap(Map<String, dynamic> map, String documentId) {
    return Profile(
      id: documentId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      bloodGroup: map['bloodGroup'],
      isSelf: false, // Firestore profiles are never "self"
    );
  }

  // 🔥 Convert Profile → Firestore
  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'bloodGroup': bloodGroup};
  }

  // ✅ Useful for debugging
  @override
  String toString() {
    return 'Profile(id: $id, name: $name, phone: $phone, bloodGroup: $bloodGroup)';
  }

  // ✅ Optional: equality (helps later with state mgmt)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
