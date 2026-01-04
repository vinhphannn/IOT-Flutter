import 'package:flutter/material.dart';
import '../../models/device_model.dart';

class SelectFunctionScreen extends StatefulWidget {
  final Device device;

  const SelectFunctionScreen({super.key, required this.device});

  @override
  State<SelectFunctionScreen> createState() => _SelectFunctionScreenState();
}

class _SelectFunctionScreenState extends State<SelectFunctionScreen> {
  // Mặc định chọn ON
  String _selectedFunction = "ON";

  @override
  Widget build(BuildContext context) {
    // Lấy màu chủ đạo từ Theme
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Function", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // 1. ẢNH THIẾT BỊ TO TRÒN
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade100, width: 1),
                    ),
                    padding: const EdgeInsets.all(40),
                    child: _buildDeviceImage(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 2. TÊN & PHÒNG
                  Text(
                    widget.device.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.device.roomName,
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // 3. DANH SÁCH CHỨC NĂNG (ON / OFF)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Function", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  _buildFunctionOption("ON", primaryColor),
                  const SizedBox(height: 16),
                  _buildFunctionOption("OFF", primaryColor),
                ],
              ),
            ),
          ),

          // 4. NÚT OK
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // Trả về dữ liệu hành động hoàn chỉnh
                  Navigator.pop(context, {
                    "cmd": _selectedFunction, // "ON" hoặc "OFF"
                    // Sau này nếu là máy lạnh có thể thêm temp, mode...
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, // Dùng màu chủ đạo
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Widget hiển thị ảnh hoặc icon
  Widget _buildDeviceImage() {
    // Nếu thiết bị có ảnh thật (sau này Model có trường imageUrl) thì uncomment đoạn dưới
    /*
    if (widget.device.imageUrl != null && widget.device.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(widget.device.imageUrl!, fit: BoxFit.cover),
      );
    }
    */
    return Icon(_getIconData(), size: 80, color: Colors.grey[400]);
  }

  IconData _getIconData() {
    switch (widget.device.type.toUpperCase()) {
      case 'AC': return Icons.ac_unit;
      case 'LIGHT': case 'RELAY': return Icons.lightbulb_outline;
      case 'FAN': return Icons.wind_power;
      case 'SOCKET': case 'PLUG': return Icons.power; // Thêm ổ cắm
      case 'TV': return Icons.tv; // Thêm TV
      case 'LOCK': return Icons.lock; // Thêm khóa
      case 'CAMERA': return Icons.videocam; // Thêm Camera
      case 'SPEAKER': return Icons.speaker; // Thêm Loa
      default: return Icons.devices_other;
    }
  }

  // Widget dòng chọn ON/OFF (Radio Button)
  Widget _buildFunctionOption(String value, Color activeColor) {
    return RadioListTile<String>(
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      value: value,
      groupValue: _selectedFunction,
      activeColor: activeColor,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setState(() => _selectedFunction = val!);
      },
    );
  }
}