import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../routes.dart';
import '../../models/room_model.dart'; // <--- Thêm dòng này ở đầu file

// --- IMPORT MODEL CỦA VỢ (Để hứng danh sách phòng) ---
// Vợ nhớ kiểm tra đường dẫn import cho đúng nhé
// import '../../models/room_model.dart'; 

const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHAR_CREDENTIALS_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; 
const String CHAR_WIFI_LIST_UUID   = "1c95d5e3-d8f7-413a-bf3d-7a2e5d7be87e"; 

class WifiSelectionScreen extends StatefulWidget {
  final BluetoothDevice device;
  final String deviceType;
  final String macAddress;

  const WifiSelectionScreen({
    super.key, 
    required this.device, 
    required this.deviceType, 
    required this.macAddress
  });

  @override
  State<WifiSelectionScreen> createState() => _WifiSelectionScreenState();
}

class _WifiSelectionScreenState extends State<WifiSelectionScreen> {
  bool _isLoading = true;
  String _statusMessage = "Đang đọc danh sách Wifi..."; 
  List<String> _wifiList = [];
  
  BluetoothCharacteristic? _credCharacteristic;
  final TextEditingController _passController = TextEditingController();
  String? _selectedSsid;

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  // ... (Giữ nguyên phần _discoverServices như cũ) ...
  Future<void> _discoverServices() async {
    try {
      if (Platform.isAndroid) await widget.device.requestMtu(512);
      List<BluetoothService> services = await widget.device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var c in service.characteristics) {
            if (c.uuid.toString() == CHAR_CREDENTIALS_UUID) _credCharacteristic = c;
            if (c.uuid.toString() == CHAR_WIFI_LIST_UUID) {
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) => _handleNotify(value));
              List<int> value = await c.read();
              _handleNotify(value);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi BLE: $e");
      if (mounted) setState(() { _isLoading = false; _statusMessage = "Lỗi kết nối Bluetooth!"; });
    }
  }

  void _handleNotify(List<int> value) {
    if (value.isEmpty) return;
    String data = utf8.decode(value);
    debugPrint(">>> BLE Notify: $data");

    if (data == "CONNECTING") {
      setState(() => _statusMessage = "Thiết bị đang thử kết nối Wifi...");
    } else if (data == "SUCCESS") {
      // --- THAY ĐỔI Ở ĐÂY: KHÔNG BIND NGAY MÀ HIỆN POPUP CHỌN PHÒNG ---
      _fetchRoomsAndShowDialog(); 
    } else if (data == "FAIL") {
      setState(() { _isLoading = false; _statusMessage = "Kết nối thất bại. Thử lại."; });
      _showError("Sai mật khẩu hoặc sóng yếu!");
    } else {
      try {
        List<dynamic> list = jsonDecode(data);
        if (mounted) {
          setState(() {
            _wifiList = list.map((e) => e.toString()).toList();
            _wifiList = _wifiList.toSet().toList();
            _wifiList.removeWhere((element) => element.isEmpty);
            _isLoading = false;
          });
        }
      } catch (e) { }
    }
  }

  // ... (Giữ nguyên _sendConfig và _refreshWifi) ...
  Future<void> _sendConfig() async {
    if (_selectedSsid == null || _passController.text.isEmpty) {
      _showError("Vui lòng chọn Wifi và nhập mật khẩu!");
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _statusMessage = "Đang gửi cấu hình xuống thiết bị..."; });
    try {
      if (_credCharacteristic != null) {
        String jsonConfig = jsonEncode({ "ssid": _selectedSsid!, "pass": _passController.text });
        await _credCharacteristic!.write(utf8.encode(jsonConfig));
      }
    } catch (e) {
      _showError("Lỗi gửi dữ liệu: $e");
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _refreshWifi() async {
     setState(() { _isLoading = true; _statusMessage = "Đang quét lại Wifi..."; _wifiList.clear(); });
     try { if (_credCharacteristic != null) await _credCharacteristic!.write(utf8.encode("SCAN")); } catch (e) {}
  }

  // ============================================================
  // --- PHẦN MỚI: XỬ LÝ CHỌN PHÒNG & BIND DEVICE ---
  // ============================================================

  // 1. Lấy danh sách phòng từ API -> Rồi hiện Dialog
Future<void> _fetchRoomsAndShowDialog() async {
    setState(() => _statusMessage = "Wifi OK! Đang lấy danh sách phòng...");
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      
      // Giả sử lấy tất cả phòng của nhà mặc định (ID=1)
      // Vợ nhớ sửa URL API cho đúng với Backend nhé (ví dụ: /houses/1/rooms)
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/houses/1/rooms'), 
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        
        // --- SỬA CHỖ NÀY: Dùng Model Room ---
        List<Room> rooms = data.map((json) => Room.fromJson(json)).toList();

        if (mounted) {
           _showRoomSelectionDialog(rooms);
        }
      } else {
        throw Exception("Không lấy được danh sách phòng");
      }
    } catch (e) {
      debugPrint("Lỗi lấy phòng: $e");
      if (mounted) _showError("Lỗi tải phòng: $e");
    }
  }

  // 2. Hiện Popup chọn phòng
void _showRoomSelectionDialog(List<Room> rooms) { // <-- Nhận vào List<Room>
    int? selectedRoomId = rooms.isNotEmpty ? rooms[0].id : null; 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Chọn phòng"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Thiết bị đã kết nối Wifi thành công! Chọn phòng để thêm thiết bị:"),
                  const SizedBox(height: 20),
                  DropdownButton<int>(
                    value: selectedRoomId,
                    isExpanded: true,
                    hint: const Text("Chọn phòng"),
                    items: rooms.map((Room room) { // <-- Dùng Model Room
                      return DropdownMenuItem<int>(
                        value: room.id,
                        child: Text(room.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() => selectedRoomId = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    widget.device.disconnect();
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: selectedRoomId == null ? null : () {
                    Navigator.pop(ctx);
                    _bindDeviceToBackend(selectedRoomId!);
                  },
                  child: const Text("Lưu Thiết Bị"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 3. Gọi API Bind (Gửi Payload chuẩn Backend yêu cầu)
  Future<void> _bindDeviceToBackend(int roomId) async {
    setState(() => _statusMessage = "Đang lưu thiết bị vào hệ thống...");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      // Payload chuẩn theo Backend vợ yêu cầu
      Map<String, dynamic> payload = {
        "name": widget.deviceType, // Hoặc cho user nhập tên mới nếu thích
        "macAddress": widget.macAddress,
        "type": "RELAY", // Gửi chuỗi Enum
        "room": { "id": roomId } // Object lồng nhau chuẩn JPA
      };

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/devices/bind'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        await widget.device.disconnect(); // Ngắt BLE
        if (mounted) _showSuccessDialog();
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      debugPrint("Lỗi Bind: $e");
      if (mounted) {
        _showError("Lỗi lưu thiết bị: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // ... (Giữ nguyên _showSuccessDialog, _showError, build UI) ...
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Thành công! 🎉"),
        content: const Text("Thiết bị đã được thêm vào phòng thành công."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.popUntil(context, (route) => route.settings.name == AppRoutes.home);
            },
            child: const Text("Về trang chủ"),
          )
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    // ... (Phần UI giữ nguyên như code cũ của vợ) ...
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cấu hình Wifi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshWifi,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_statusMessage, style: const TextStyle(color: Colors.grey)),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chọn Wifi:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: _wifiList.isEmpty 
                      ? const Center(child: Text("Không tìm thấy Wifi"))
                      : ListView.separated(
                          itemCount: _wifiList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final ssid = _wifiList[index];
                            return RadioListTile<String>(
                              title: Text(ssid),
                              value: ssid,
                              groupValue: _selectedSsid,
                              onChanged: (val) => setState(() => _selectedSsid = val),
                            );
                          },
                        ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu Wifi",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendConfig,
                      child: const Text("KẾT NỐI NGAY"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}