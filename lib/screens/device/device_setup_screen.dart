import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/room_model.dart';
import '../../services/room_service.dart'; 
import '../../services/api_client.dart'; 
import 'wifi_selection_screen.dart';

class DeviceSetupScreen extends StatefulWidget {
  final BluetoothDevice device;
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
    _nameController.text = widget.deviceType;
    _fetchRooms();
  }

  // --- LOGIC BACKEND (Đã chuẩn hóa) ---
  Future<void> _fetchRooms() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? currentHouseId = prefs.getInt('currentHouseId');

      if (currentHouseId == null) throw Exception("Chưa chọn nhà!");

      // Gọi API qua ApiClient (Tự động gắn Token)
      final response = await ApiClient.get('/rooms/house/$currentHouseId');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _rooms = data.map((e) => Room.fromJson(e)).toList();
          if (_rooms.isNotEmpty) _selectedRoomId = _rooms[0].id;
          _isRoomLoading = false;
        });
      } else {
        throw Exception("Lỗi tải phòng: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi: $e");
      setState(() => _isRoomLoading = false);
      _showSnackBar("Không tải được danh sách phòng", isError: true);
    }
  }

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
      // --- CHỖ NÀY ĐÃ SỬA ---
      // Gửi roomId dạng phẳng (số), không lồng object nữa
// ... đoạn code cũ ...
      
      // Gửi roomId dạng phẳng (số), không lồng object nữa
      Map<String, dynamic> payload = {
        "name": _nameController.text,
        "macAddress": widget.macAddress,
        
        // --- SỬA DÒNG NÀY: Ép sang chữ hoa ---
        "type": widget.deviceType.toUpperCase(), // Ví dụ: "Relay" -> "RELAY"
        // -------------------------------------
        
        "roomId": _selectedRoomId 
      };

      // ... đoạn code dưới giữ nguyên ...

      final response = await ApiClient.post('/devices/bind', payload);

      if (response.statusCode == 200) {
        _showSnackBar("Đã lưu thiết bị! Đang chuyển...");
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WifiSelectionScreen(
                device: widget.device,
                deviceType: widget.deviceType,
                macAddress: widget.macAddress,
              ),
            ),
          );
        }
      } else {
        throw Exception("Lỗi server: ${response.body}");
      }
    } catch (e) {
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

  // --- GIAO DIỆN STYLE APP ---
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
        title: const Text(
          "Setup Device",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon to ở giữa cho đẹp
            Center(
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.settings_remote, size: 50, color: primaryColor),
              ),
            ),
            const SizedBox(height: 30),

            const Text("Device Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 1. MAC Address (Read Only - Style xám)
            _buildReadOnlyField("MAC Address", widget.macAddress, Icons.fingerprint),
            const SizedBox(height: 16),

            // 2. Type (Read Only)
            _buildReadOnlyField("Device Type", widget.deviceType, Icons.category),
            const SizedBox(height: 16),

            // 3. Name Input (Style App)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Device Name",
                hintText: "Ex: Living Room Light",
                prefixIcon: const Icon(Icons.edit_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // 4. Room Selection (Dropdown Style App)
            _isRoomLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    value: _selectedRoomId,
                    decoration: InputDecoration(
                      labelText: "Assign to Room",
                      prefixIcon: const Icon(Icons.meeting_room_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.white,
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

            // 5. Button Save (Bo tròn, bóng đổ)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDeviceToBackend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SAVE & CONFIGURE WIFI",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget con để vẽ ô ReadOnly cho đẹp
  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: Colors.grey[100], // Màu nền xám nhạt để chỉ thị không sửa được
      ),
    );
  }
}