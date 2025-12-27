import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../../widgets/device_card.dart';

class CategoryDevicesScreen extends StatelessWidget {
  final String categoryType; 
  final String title;
  final List<Device> allDevices; // <-- THÊM DÒNG NÀY: Để nhận dữ liệu thật từ Home gửi sang

  const CategoryDevicesScreen({
    super.key,
    required this.categoryType,
    required this.title,
    required this.allDevices, // <-- THÊM DÒNG NÀY
  });

  @override
  Widget build(BuildContext context) {
    // SỬA DÒNG 18: Lọc từ danh sách thật được truyền vào thay vì demoDevices
    final filteredList = allDevices.where((d) => d.type == categoryType).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "$title (${filteredList.length})",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: filteredList.isEmpty
          ? const Center(child: Text("No devices found in this category"))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85, 
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return DeviceCard(
                  device: filteredList[index],
                  showRoomInfo: true, 
                );
              },
            ),
    );
  }
}