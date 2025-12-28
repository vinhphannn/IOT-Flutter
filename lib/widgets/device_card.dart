import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../../routes.dart';
import '../../services/house_service.dart'; // Import service để gọi API
import '../../models/device_model.dart';
import '../../services/house_service.dart';

class DeviceCard extends StatefulWidget {
  final Device device;
  final bool showRoomInfo; 

  const DeviceCard({
    super.key,
    required this.device,
    this.showRoomInfo = false,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  late bool _isOn;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isOn = widget.device.isOn;
  }

  // Hàm toggle nhanh ngay trên Card
  Future<void> _toggleQuick(bool value) async {
    setState(() { _isOn = value; _isLoading = true; });
    try {
      bool success = await HouseService().toggleDevice(widget.device.id, value);
      if (success) {
        widget.device.isOn = value;
      } else {
        setState(() => _isOn = !value); // Revert
      }
    } catch (e) {
      setState(() => _isOn = !value);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.controlDevice,
          arguments: widget.device,
        ).then((_) {
          // Khi quay lại từ màn hình chi tiết, cập nhật lại trạng thái
          setState(() => _isOn = widget.device.isOn);
        });
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
                // Icon
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(widget.device.icon, size: 28, color: _isOn ? Colors.amber : Colors.grey[700]),
                ),
                // Switch (Chỉ hiện nếu thiết bị switchable)
                if (widget.device.isSwitchable)
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _isOn,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF4B6EF6),
                      onChanged: _isLoading ? null : _toggleQuick,
                    ),
                  ),
              ],
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                if (widget.showRoomInfo) ...[
                  const SizedBox(height: 4),
                  Text(widget.device.roomName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi, size: 10, color: Colors.grey[600]), // Mặc định là Wifi
                      const SizedBox(width: 4),
                      Text("Wi-Fi", style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
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