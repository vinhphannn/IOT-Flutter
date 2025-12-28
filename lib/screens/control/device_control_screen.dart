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
        // SỬA Ở ĐÂY: Thay widget.device.name thành "Control Device"
        title: const Text(
          "Control Device", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          _buildHeader(), // Tên thiết bị thật sự nằm ở đây này
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
          Expanded(child: _buildDeviceBody()), 
          
          // Chồng thêm cái nút Schedule ở dưới cùng cho giống thiết kế của vợ luôn nhé
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
    switch (widget.device.type.toUpperCase()) {
      case 'LIGHT':
      case 'RELAY':
        return LightControlWidget(device: widget.device);
      case 'SOCKET':
        return SocketControlWidget(device: widget.device);
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