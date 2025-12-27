import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../../services/house_service.dart';
// import 'bodies/light_control_body.dart'; // Tạm thời comment vì chưa có file này

class DeviceControlScreen extends StatefulWidget {
  final Device device;

  const DeviceControlScreen({super.key, required this.device});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late bool _isDeviceOn;
  bool _isLoading = false; // Để hiện loading khi đang gọi API

  @override
  void initState() {
    super.initState();
    _isDeviceOn = widget.device.isOn;
  }

  // Hàm gọi API Bật/Tắt
  Future<void> _toggleDevice(bool value) async {
    setState(() {
      _isDeviceOn = value;
      _isLoading = true;
    });

    try {
      // Gọi API Backend
      bool success = await HouseService().toggleDevice(widget.device.id, value);
      
      if (success) {
        // Nếu thành công, cập nhật luôn vào object device để khi back về Home nó cập nhật theo
        widget.device.isOn = value; 
      } else {
        // Nếu thất bại, quay về trạng thái cũ
        setState(() => _isDeviceOn = !value);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối!")));
      }
    } catch (e) {
      debugPrint("Lỗi toggle: $e");
      setState(() => _isDeviceOn = !value);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

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
        title: Text(
          widget.device.name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 1. HEADER (Thông tin & Nút Switch To)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                      child: Icon(widget.device.icon, size: 30, color: Colors.black54),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(widget.device.roomName, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                
                // Nút Switch
                widget.device.isSwitchable 
                ? Transform.scale(
                    scale: 1.2,
                    child: Switch(
                      value: _isDeviceOn,
                      activeColor: Colors.white,
                      activeTrackColor: primaryColor,
                      onChanged: _isLoading ? null : _toggleDevice, // Disable khi đang load
                    ),
                  )
                : const SizedBox(), // Nếu thiết bị không bật tắt được (Sensor) thì ẩn nút
              ],
            ),
          ),

          const Divider(height: 30, thickness: 1, color: Color(0xFFF5F5F5)),

          // 2. BODY (Hiển thị chi tiết theo loại)
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    // Tạm thời hiển thị text đơn giản vì chưa có file `LightControlBody`
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.device.icon, size: 100, color: _isDeviceOn ? Colors.amber : Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            _isDeviceOn ? "DEVICE IS ON" : "DEVICE IS OFF",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          if (widget.device.type == 'SENSOR')
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text("Giá trị cảm biến: 25°C (Demo)", style: TextStyle(fontSize: 18)),
            )
        ],
      ),
    );
  }
}