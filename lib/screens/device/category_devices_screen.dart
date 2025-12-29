import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Import Provider
import '../../models/device_model.dart';
import '../../providers/device_provider.dart'; // 2. Import Kho tổng
import '../../widgets/device_card.dart';

class CategoryDevicesScreen extends StatelessWidget {
  final String categoryType; 
  final String title;
  // Bỏ biến allDevices ở đây đi, không cần truyền thủ công nữa

  const CategoryDevicesScreen({
    super.key,
    required this.categoryType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // 3. Dùng Consumer để lắng nghe thay đổi
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        // Lấy danh sách tươi mới nhất từ Kho tổng
        final allDevices = provider.devices;
        
        // Lọc theo loại (Socket, Relay...)
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
                    final device = filteredList[index];
                    final isOnline = device.isOnline; // Lấy trạng thái từ Model

                    // --- CODE HIỂN THỊ OFFLINE GIỐNG TRANG HOME ---
                    return Stack(
                      children: [
                        // 1. Thẻ thiết bị (Mờ đi nếu Offline)
                        Opacity(
                          opacity: isOnline ? 1.0 : 0.4,
                          child: DeviceCard(
                            device: device,
                            showRoomInfo: true, 
                          ),
                        ),

                        // 2. Icon Mất kết nối (Nằm giữa)
                        if (!isOnline)
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.cloud_off_rounded,
                                  size: 32,
                                  color: Colors.grey[600]!.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}