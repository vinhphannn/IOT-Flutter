import 'package:flutter/material.dart';
import '../../routes.dart';
import 'add_device_screen.dart'; // Để dùng DeviceItem và chuyển trang

class ManualAddTab extends StatefulWidget {
  const ManualAddTab({super.key});

  @override
  State<ManualAddTab> createState() => _ManualAddTabState();
}

class _ManualAddTabState extends State<ManualAddTab> {
  // Danh mục thiết bị
  final List<String> _categories = ["Popular", "Lighting", "Camera", "Electrical", "Sensor", "Lock"];
  int _selectedCategoryIndex = 0;

  // Danh sách thiết bị mẫu (Y như thiết kế)
  final List<DeviceItem> _devices = [
    DeviceItem(icon: Icons.camera_outdoor, name: "Smart V1 CCTV", color: Colors.grey),
    DeviceItem(icon: Icons.camera_indoor, name: "Smart Webcam", color: Colors.grey),
    DeviceItem(icon: Icons.video_camera_front, name: "Smart V2 CCTV", color: Colors.grey),
    DeviceItem(icon: Icons.lightbulb, name: "Smart Lamp", color: Colors.orange), // Màu cam cho đèn
    DeviceItem(icon: Icons.speaker, name: "Smart Speaker", color: Colors.grey),
    DeviceItem(icon: Icons.router, name: "Wifi Router", color: Colors.grey),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        // 1. CATEGORY FILTER (Scroll Ngang)
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = _selectedCategoryIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // 2. GRID VIEW THIẾT BỊ
        Expanded( // Dùng Expanded để chiếm hết phần còn lại
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cột
              crossAxisSpacing: 16, // Khoảng cách ngang
              mainAxisSpacing: 16, // Khoảng cách dọc
              childAspectRatio: 0.85, // Tỷ lệ khung hình (Cao hơn rộng xíu)
            ),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return _buildDeviceCard(device, primaryColor);
            },
          ),
        ),
      ],
    );
  }

  // Widget Thẻ Thiết Bị
  Widget _buildDeviceCard(DeviceItem device, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        // Bấm vào thì cũng sang trang Connect giống bên Nearby
        Navigator.pushNamed(
          context, 
          AppRoutes.connectDevice, 
          arguments: device
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50], // Nền xám rất nhạt
          borderRadius: BorderRadius.circular(16),
          // border: Border.all(color: Colors.grey.shade200), // Có thể thêm viền nếu thích
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hình ảnh thiết bị (Tạm dùng Icon to)
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                // color: Colors.white, // Nếu muốn nền trắng cho icon
                shape: BoxShape.circle,
              ),
              child: Icon(device.icon, size: 60, color: device.color),
            ),
            const SizedBox(height: 12),
            // Tên thiết bị
            Text(
              device.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87
              ),
            ),
          ],
        ),
      ),
    );
  }
}