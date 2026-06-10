import 'package:flutter/material.dart';
import 'package:smart_108_responders/theme/app_colors.dart';

//

class InlineEditCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isEditable;
  final Function(String)? onSave;

  const InlineEditCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isEditable = true,
    this.onSave,
  });

  @override
  State<InlineEditCard> createState() => _InlineEditCardState();
}

class _InlineEditCardState extends State<InlineEditCard> {
  bool isEditing = false;
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: AppColors.textPrimary),

          const SizedBox(width: 25),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(color: AppColors.iconColor, fontSize: 13),
                ),
                const SizedBox(height: 2),
                isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary
                        ),
                      )
                    : Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary
                        ),
                      ),
              ],
            ),
          ),

          if (widget.isEditable)
            IconButton(
              icon: Icon(
                isEditing ? Icons.check_circle : Icons.edit,
                color: isEditing ? Colors.grey : Colors.grey,
              ),
              onPressed: () {
                if (isEditing) {
                  widget.onSave!(controller.text); //Trigger flutter update
                }
                setState(() {
                  isEditing = !isEditing;
                });
              },
            ),
        ],
      ),
    );
  }
}
