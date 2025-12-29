import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Nhớ import Provider
import '../models/device_model.dart';
import '../providers/device_provider.dart'; // Import kho tổng
import '../routes.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final bool showRoomInfo;

  const DeviceCard({
    super.key, 
    required this.device, 
    this.showRoomInfo = false
  });

  @override
  Widget build(BuildContext context) {
    // Gọi Provider (listen: false vì mình chỉ cần gọi hàm, việc vẽ lại UI đã có Consumer ở cha lo)
    final provider = Provider.of<DeviceProvider>(context, listen: false);
    final isOnline = device.isOnline; // Lấy trạng thái mạng

    return GestureDetector(
      // 1. BẤM VÀO THẺ -> VÀO TRANG CONTROL (Luôn cho phép, kể cả Offline)
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.controlDevice,
          arguments: device,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon Thiết bị
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  // Nếu Offline thì icon màu xám, Online thì màu vàng (khi bật)
                  child: Icon(
                    device.icon, 
                    size: 28, 
                    color: isOnline 
                        ? (device.isOn ? Colors.amber : Colors.grey[700]) 
                        : Colors.grey[400], 
                  ),
                ),
                
                // Switch (Nút gạt)
                if (device.isSwitchable)
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: device.isOn,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF4B6EF6),
                      // LOGIC KHÓA NÚT KHI OFFLINE:
                      // Nếu Online -> Gọi hàm toggle của Provider
                      // Nếu Offline -> Gán null (Nút sẽ bị liệt/xám đi)
                      onChanged: isOnline 
                          ? (val) => provider.toggleDevice(device.id)
                          : null,
                    ),
                  ),
              ],
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                if (showRoomInfo) ...[
                  const SizedBox(height: 4),
                  Text(device.roomName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
                const SizedBox(height: 8),
                
                // HIỂN THỊ TRẠNG THÁI KẾT NỐI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // Offline màu đỏ nhạt, Online màu xám nhạt
                    color: isOnline ? Colors.grey[100] : Colors.red[50], 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off, 
                        size: 10, 
                        color: isOnline ? Colors.green[600] : Colors.red[400]
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? "Online" : "Offline", 
                        style: TextStyle(
                          fontSize: 10, 
                          color: isOnline ? Colors.grey[600] : Colors.red[400], 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}