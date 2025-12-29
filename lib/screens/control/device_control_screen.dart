import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../../services/house_service.dart';
import 'widgets/light_control_widget.dart';
import 'widgets/socket_control_widget.dart';

class DeviceControlScreen extends StatefulWidget {
  final Device device;
  const DeviceControlScreen({super.key, required this.device});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late bool _isDeviceOn;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isDeviceOn = widget.device.isOn;
  }

  Future<void> _toggleDevice(bool value) async {
    setState(() { _isDeviceOn = value; _isLoading = true; });
    try {
      bool success = await HouseService().toggleDevice(widget.device.id.toString(), value);
      if (success) {
        widget.device.isOn = value;
      } else {
        setState(() => _isDeviceOn = !value);
      }
    } catch (e) {
      setState(() => _isDeviceOn = !value);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // ĐƯA TÊN VÀ PHÒNG LÊN ĐÂY
        title: Column(
          children: [
            Text(
              widget.device.name,
              style: const TextStyle(
                color: Colors.black, 
                fontWeight: FontWeight.bold, 
                fontSize: 18
              ),
            ),
            Text(
              widget.device.roomName,
              style: const TextStyle(
                color: Colors.grey, 
                fontSize: 12, 
                fontWeight: FontWeight.normal
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Đã bỏ hoàn toàn _buildHeader() ở đây
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
          
          // Phần thân chứa các thông số điện năng
          Expanded(child: _buildDeviceBody()), 
          
          // Nút hành động dưới cùng
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
                child: Icon(widget.device.icon, size: 30, color: Colors.black54),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(widget.device.roomName, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          if (widget.device.isSwitchable)
            Switch(
              value: _isDeviceOn,
              activeColor: const Color(0xFF4B6EF6),
              onChanged: _isLoading ? null : _toggleDevice,
            ),
        ],
      ),
    );
  }

Widget _buildDeviceBody() {
  print("🔍 [DEBUG] DeviceControlScreen đang giữ device có ID: ${widget.device.id}"); // <--- THÊM DÒNG NÀY
    switch (widget.device.type.toUpperCase()) {
      case 'LIGHT':
      case 'RELAY':
        // Nếu vợ chưa sửa file LightControlWidget thì cứ để nguyên dòng này
        return LightControlWidget(device: widget.device); 
        
      case 'SOCKET':
        // --- SỬA Ở ĐÂY NÈ VỢ ---
        // Thay vì truyền cả device, giờ mình chỉ truyền ID thôi
        return SocketControlWidget(deviceId: widget.device.id);
        
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.device.icon, size: 80, color: Colors.grey[200]),
              const SizedBox(height: 16),
              Text(
                "Giao diện cho ${widget.device.type}\nđang được cập nhật",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }
  // Nút bấm dưới cùng cho giống mẫu thiết kế
  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEEF2FF),
            foregroundColor: const Color(0xFF4B6EF6),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            // Logic mở trang hẹn giờ
          },
          child: const Text(
            "Schedule Automatic ON/OFF", 
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }
}