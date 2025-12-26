import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../routes.dart'; // Import routes để dùng AppRoutes

class DeviceCard extends StatefulWidget {
  final Device device;
  final bool showRoomInfo; // Có hiện tên phòng bên dưới tên thiết bị không?

  const DeviceCard({
    super.key,
    required this.device,
    this.showRoomInfo = false,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  @override
  Widget build(BuildContext context) {
    // Bọc toàn bộ Container bằng GestureDetector để bắt sự kiện nhấn
    return GestureDetector(
      onTap: () {
        // Chuyển sang trang điều khiển thiết bị
        // Truyền đối tượng device qua arguments
        Navigator.pushNamed(
          context,
          AppRoutes.controlDevice,
          arguments: widget.device,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row 1: Icon/Image + Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: widget.device.imagePath != null
                      ? Image.asset(widget.device.imagePath!, errorBuilder: (_,__,___) => Icon(widget.device.icon, size: 28, color: Colors.grey[700]))
                      : Icon(widget.device.icon, size: 28, color: Colors.grey[700]),
                ),
                // Switch
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: widget.device.isOn,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF4B6EF6),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey[300],
                    onChanged: (bool value) {
                      setState(() {
                        widget.device.isOn = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            // Row 2: Tên, Phòng, Loại kết nối
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Nếu showRoomInfo = true thì hiện tên phòng (Dùng cho trang Category)
                if (widget.showRoomInfo) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.device.room,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.device.isWiFi ? Icons.wifi : Icons.bluetooth,
                        size: 10,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.device.isWiFi ? "Wi-Fi" : "Bluetooth",
                        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
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