import 'package:flutter/material.dart';
import '../../../routes.dart'; // Lùi 3 cấp để tìm routes.dart
import 'nearby_scan_tab.dart'; // Import file này để lấy class DeviceItem

class ManualAddTab extends StatefulWidget {
  const ManualAddTab({super.key});

  @override
  State<ManualAddTab> createState() => _ManualAddTabState();
}

class _ManualAddTabState extends State<ManualAddTab> {
  // Danh mục thiết bị
  final List<String> _categories = ["Popular", "Lighting", "Camera", "Electrical", "Sensor", "Lock"];
  int _selectedCategoryIndex = 0;

  // DANH SÁCH THIẾT BỊ MẪU - Đã fix lỗi thiếu macAddress và type
  final List<DeviceItem> _devices = [
    DeviceItem(
      icon: Icons.camera_outdoor, 
      name: "Smart V1 CCTV", 
      color: Colors.grey,
      macAddress: "", // Thêm thủ công nên tạm để trống
      type: "CAMERA", // Gán loại tương ứng
    ),
    DeviceItem(
      icon: Icons.camera_indoor, 
      name: "Smart Webcam", 
      color: Colors.grey,
      macAddress: "",
      type: "CAMERA",
    ),
    DeviceItem(
      icon: Icons.video_camera_front, 
      name: "Smart V2 CCTV", 
      color: Colors.grey,
      macAddress: "",
      type: "CAMERA",
    ),
    DeviceItem(
      icon: Icons.lightbulb, 
      name: "Smart Lamp", 
      color: Colors.orange,
      macAddress: "",
      type: "LIGHT",
    ), 
    DeviceItem(
      icon: Icons.speaker, 
      name: "Smart Speaker", 
      color: Colors.grey,
      macAddress: "",
      type: "SPEAKER",
    ),
    DeviceItem(
      icon: Icons.router, 
      name: "Wifi Router", 
      color: Colors.grey,
      macAddress: "",
      type: "ROUTER",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        const SizedBox(height: 20),
        
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
        Expanded( 
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cột
              crossAxisSpacing: 16, 
              mainAxisSpacing: 16, 
              childAspectRatio: 0.85, // Tỷ lệ khung hình
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
        // Chuyển sang trang Connect Device
        Navigator.pushNamed(
          context, 
          AppRoutes.connectDevice, 
          arguments: device
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50], 
          borderRadius: BorderRadius.circular(16),
          // Thêm bóng mờ nhẹ cho đẹp
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hình ảnh thiết bị 
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(device.icon, size: 40, color: device.color),
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