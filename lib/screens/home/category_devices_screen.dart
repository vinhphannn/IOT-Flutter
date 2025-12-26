import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../../widgets/device_card.dart';

class CategoryDevicesScreen extends StatelessWidget {
  final String categoryType; // Ví dụ: 'Light', 'Camera'
  final String title;        // Ví dụ: 'Lighting'

  const CategoryDevicesScreen({
    super.key,
    required this.categoryType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Lọc thiết bị theo loại
    final filteredList = demoDevices.where((d) => d.type == categoryType).toList();

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
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: filteredList.isEmpty
          ? const Center(child: Text("No devices found"))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Tỉ lệ thẻ dài hơn xíu để chứa tên phòng
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return DeviceCard(
                  device: filteredList[index],
                  showRoomInfo: true, // Quan trọng: Bật hiển thị tên phòng
                );
              },
            ),
    );
  }
}