import 'package:flutter/material.dart';
import 'package:smart_108_responders/theme/app_colors.dart';

Widget buildFloatingBox({required Widget child}) {
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: AppColors.brown,
            borderRadius: BorderRadius.circular(15), // Rounded corners
            boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), // Very subtle shadow
                blurRadius: 10,
                offset: const Offset(0, 4),
            ),
            ],
        ),
        child: child,
    );
}
