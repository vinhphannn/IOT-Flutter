import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../models/scene_model.dart';
import '/../providers/smart_provider.dart';
import '../widgets/smart_task_card.dart';

class AutomationTab extends StatelessWidget {
  final List<Scene> scenes;

  const AutomationTab({super.key, required this.scenes});

  @override
  Widget build(BuildContext context) {
    if (scenes.isEmpty) {
      return const Center(child: Text("No automations yet", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: scenes.length,
      itemBuilder: (context, index) {
        final scene = scenes[index];
        return SmartTaskCard(
          title: scene.name,
          subtitle: "${scene.actionCount} tasks",
          icons: [scene.iconData], // Hiện 1 icon đại diện
          initialValue: scene.enabled, // Trạng thái từ API
          iconColor: scene.color,      // Màu từ API
          onTap: () {
            // Sau này làm trang Edit Scene thì mở ở đây
          },
          onToggle: (val) {
            // Gọi Provider để Bật/Tắt
            context.read<SmartProvider>().toggleAutomation(scene.id, scene.enabled);
          },
        );
      },
    );
  }
}