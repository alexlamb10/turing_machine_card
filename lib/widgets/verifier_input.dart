import 'package:flutter/material.dart';

class VerifierInput extends StatelessWidget {
  final String id;
  final int state; // 0=Empty, 1=Fail, 2=Pass
  final VoidCallback onTap;

  const VerifierInput({
    super.key,
    required this.id,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.grey[200]!;
    IconData? icon;
    Color iconColor = Colors.transparent;

    if (state == 1) {
      bgColor = Colors.red[100]!;
      icon = Icons.close;
      iconColor = Colors.red;
    } else if (state == 2) {
      bgColor = Colors.green[100]!;
      icon = Icons.check;
      iconColor = Colors.green;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon != null 
              ? Icon(icon, color: iconColor)
              : null,
          ),
        ],
      ),
    );
  }
}
