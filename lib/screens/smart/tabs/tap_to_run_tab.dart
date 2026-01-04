import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/../models/scene_model.dart';
import '/../providers/smart_provider.dart';

class TapToRunTab extends StatelessWidget {
  final List<Scene> scenes;

  const TapToRunTab({super.key, required this.scenes});

  @override
  Widget build(BuildContext context) {
    if (scenes.isEmpty) {
      return const Center(child: Text("No Tap-to-Run scenes yet", style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: scenes.length,
          itemBuilder: (context, index) {
            return _buildTapCard(context, scenes[index]);
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTapCard(BuildContext context, Scene scene) {
    return Container(
      decoration: BoxDecoration(
        color: scene.color, // Màu từ API
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scene.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Gọi API chạy kịch bản
            context.read<SmartProvider>().executeScene(scene.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Executed: ${scene.name}")),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(scene.iconData, color: scene.color, size: 20),
                    ),
                    const Icon(Icons.play_arrow, color: Colors.white, size: 20), // Nút Play
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${scene.actionCount} tasks",
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}