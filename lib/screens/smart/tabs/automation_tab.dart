import 'package:flutter/material.dart';
import '../widgets/smart_task_card.dart'; // Đảm bảo đường dẫn import đúng

class AutomationTab extends StatelessWidget {
  final int houseId; // Nhận houseId

  const AutomationTab({super.key, required this.houseId});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả (sau này sẽ lấy từ API dựa trên houseId)
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        SmartTaskCard(
          title: "Turn ON All the Lights",
          subtitle: "1 task",
          icons: const [Icons.access_time_filled, Icons.wb_sunny],
          initialValue: true,
          iconColor: Colors.orange,
          onTap: () {},
          onToggle: (val) {},
        ),
        SmartTaskCard(
          title: "Go to Office",
          subtitle: "2 tasks",
          icons: const [Icons.location_on, Icons.access_time_filled, Icons.local_offer],
          initialValue: true,
          iconColor: Colors.green,
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
        const SizedBox(height: 80),
      ],
    );
  }
}