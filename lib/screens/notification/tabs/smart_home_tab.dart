import 'package:flutter/material.dart';

class SmartHomeTab extends StatelessWidget {
  const SmartHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Nếu chưa có thông báo thì hiện Empty State
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          const Text(
            "No smart notifications yet",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}