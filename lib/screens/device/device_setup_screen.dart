import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';
import '../../models/room_model.dart';
import '../../routes.dart';
import 'wifi_selection_screen.dart'; // Import để chuyển tiếp sau khi lưu xong

class DeviceSetupScreen extends StatefulWidget {
  final BluetoothDevice device; // Giữ kết nối BLE để truyền sang màn sau
  final String deviceType;
  final String macAddress;

  const DeviceSetupScreen({
    super.key,
    required this.device,
    required this.deviceType,
    required this.macAddress,
  });

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final _nameController = TextEditingController();
  List<Room> _rooms = [];
  int? _selectedRoomId;
  bool _isLoading = false;
  bool _isRoomLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.deviceType; // Tên mặc định là loại thiết bị
    _fetchRooms();
  }

  // 1. Tải danh sách phòng để chọn
  Future<void> _fetchRooms() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      
      // Sửa ID nhà 1 thành ID động nếu cần
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/houses/1/rooms'), 
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _rooms = data.map((e) => Room.fromJson(e)).toList();
          if (_rooms.isNotEmpty) _selectedRoomId = _rooms[0].id; // Chọn mặc định
          _isRoomLoading = false;
        });
      } else {
        throw Exception("Lỗi tải phòng: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi tải phòng: $e");
      setState(() => _isRoomLoading = false);
      _showSnackBar("Không tải được danh sách phòng!", isError: true);
    }
  }

  // 2. Lưu thiết bị vào Backend
  Future<void> _saveDeviceToBackend() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar("Vui lòng nhập tên thiết bị", isError: true);
      return;
    }
    if (_selectedRoomId == null) {
      _showSnackBar("Vui lòng chọn phòng", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      // Payload chuẩn gửi xuống Backend
      Map<String, dynamic> payload = {
        "name": _nameController.text,
        "macAddress": widget.macAddress,
        "type": widget.deviceType, // "RELAY", "SOCKET"...
        "room": { "id": _selectedRoomId } 
      };

      print(">>> Đang gửi Payload: $payload");

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/devices/bind'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Lưu thiết bị thành công! Chuyển sang cấu hình Wifi...");
        
        // Đợi 1 giây rồi chuyển sang màn hình Wifi
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WifiSelectionScreen(
                device: widget.device, // Truyền tiếp kết nối BLE
                deviceType: widget.deviceType,
                macAddress: widget.macAddress,
              ),
            ),
          );
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      debugPrint("Lỗi lưu thiết bị: $e");
      _showSnackBar("Thất bại: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thiết lập thiết bị")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Thông tin thiết bị", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // MAC Address (Read only)
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "MAC Address",
                hintText: widget.macAddress,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              controller: TextEditingController(text: widget.macAddress),
            ),
            const SizedBox(height: 15),

            // Device Type (Read only or Editable if you want)
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Loại thiết bị",
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              controller: TextEditingController(text: widget.deviceType),
            ),
            const SizedBox(height: 15),

            // Name Input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Đặt tên thiết bị",
                hintText: "Ví dụ: Đèn phòng ngủ",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 15),

            // Room Selection
            _isRoomLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    value: _selectedRoomId,
                    decoration: const InputDecoration(
                      labelText: "Chọn phòng",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.room),
                    ),
                    items: _rooms.map((Room room) {
                      return DropdownMenuItem<int>(
                        value: room.id,
                        child: Text(room.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedRoomId = val),
                  ),

            const SizedBox(height: 40),

            // Button Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDeviceToBackend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("LƯU & CẤU HÌNH WIFI", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}