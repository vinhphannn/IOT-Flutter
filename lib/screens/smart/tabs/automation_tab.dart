import 'package:flutter/material.dart';
import '../widgets/smart_task_card.dart';

class AutomationTab extends StatelessWidget {
  const AutomationTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả (sau này sẽ lấy từ API)
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        SmartTaskCard(
          title: "Turn ON All the Lights",
          subtitle: "1 task",
          icons: const [Icons.access_time_filled, Icons.wb_sunny],
          initialValue: true,
          iconColor: Colors.orange, // Icon mặt trời màu cam
          onTap: () {},
          onToggle: (val) {},
        ),
        SmartTaskCard(
          title: "Go to Office",
          subtitle: "2 tasks",
          icons: const [Icons.location_on, Icons.access_time_filled, Icons.local_offer],
          initialValue: true,
          iconColor: Colors.green, // Icon location màu xanh
          onTap: () {},
          onToggle: (val) {},
        ),
        SmartTaskCard(
          title: "Energy Saver Mode",
          subtitle: "2 tasks",
          icons: const [Icons.work, Icons.security, Icons.notifications],
          initialValue: false,
          iconColor: Colors.blue,
          onTap: () {},
          onToggle: (val) {},
        ),
        // Khoảng trống để không bị nút FAB che mất cái cuối
        const SizedBox(height: 80),
      ],
    );
  }
}