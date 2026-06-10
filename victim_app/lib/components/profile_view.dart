import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileView({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHeader(userData: userData),
          const SizedBox(height: 24),
          _ProfileInfoTile(
            label: 'Full Name',
            value: userData['full_name'] ?? '-',
            icon: Icons.person,
          ),
          _ProfileInfoTile(
            label: 'Email',
            value: userData['email'] ?? '-',
            icon: Icons.email,
          ),
          _ProfileInfoTile(
            label: 'Phone',
            value: userData['phone_number'] ?? '-',
            icon: Icons.phone,
          ),
          _ProfileInfoTile(
            label: 'Role',
            value: userData['role'] ?? '-',
            icon: Icons.security,
          ),
        ],
      ),
    );
  }

}




class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _ProfileHeader({required this.userData});

  @override
  Widget build(BuildContext context) {
    final String name = userData['full_name'] ?? 'User';

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 24),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                userData['email'] ?? '',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

      ],
    );
  }
}


class _ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
