import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/smart_provider.dart';
import '../../models/scene_model.dart';

class ManageScenesScreen extends StatefulWidget {
  const ManageScenesScreen({super.key});

  @override
  State<ManageScenesScreen> createState() => _ManageScenesScreenState();
}

class _ManageScenesScreenState extends State<ManageScenesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Manage Smart Scenes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 1. TAB BAR (Segmented Style)
          Container(
            margin: const EdgeInsets.all(20),
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF4B6EF6), // Màu xanh nút
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Automation"),
                Tab(text: "Tap-to-Run"),
              ],
            ),
          ),

          // 2. DANH SÁCH SCENE
          Expanded(
            child: Consumer<SmartProvider>(
              builder: (context, smartProvider, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSceneList(smartProvider.automationScenes, context),
                    _buildSceneList(smartProvider.tapToRunScenes, context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget danh sách dùng chung
  Widget _buildSceneList(List<Scene> scenes, BuildContext context) {
    if (scenes.isEmpty) {
      return const Center(child: Text("No scenes available"));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: scenes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final scene = scenes[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              // Icon 6 chấm (Drag handle)
              const Icon(Icons.drag_indicator, color: Colors.black54, size: 24),
              const SizedBox(width: 16),
              
              // Tên Scene
              Expanded(
                child: Text(
                  scene.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              
              // Nút Thùng rác đỏ
              InkWell(
                onTap: () => _showDeleteConfirmDialog(context, scene),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  // POPUP XÁC NHẬN XÓA
  void _showDeleteConfirmDialog(BuildContext context, Scene scene) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Smart Scene", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Text(
          'Are you sure you want to delete the scene "${scene.name}"?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx); // Đóng popup confirm
                    
                    // Gọi API Xóa
                    bool success = await Provider.of<SmartProvider>(context, listen: false).deleteScene(scene.id);
                    
                    if (success && context.mounted) {
                      _showSuccessDialog(context, scene.name); // Hiện popup thành công
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B6EF6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Yes, Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // POPUP THÔNG BÁO THÀNH CÔNG
  void _showSuccessDialog(BuildContext context, String sceneName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Tự động đóng sau 1.5 giây
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFF4B6EF6), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                'Scene "$sceneName" successfully deleted!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}