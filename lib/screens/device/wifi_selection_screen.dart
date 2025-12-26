import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../routes.dart';

// UUID Phải khớp với Code ESP32 (main.cpp)
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHAR_CREDENTIALS_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; // Ghi
const String CHAR_WIFI_LIST_UUID   = "1c95d5e3-d8f7-413a-bf3d-7a2e5d7be87e"; // Đọc

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
  bool _isBinding = false; // Trạng thái gọi API Server
  List<String> _wifiList = [];
  
  BluetoothCharacteristic? _credCharacteristic; // Để ghi SSID/Pass
  
  final TextEditingController _passController = TextEditingController();
  String? _selectedSsid;

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  // 1. Tìm Service và Đọc danh sách Wifi từ ESP32
  Future<void> _discoverServices() async {
    try {
      // Khám phá dịch vụ (Cần tăng MTU nếu list wifi dài, nhưng mặc định thường ok)
      List<BluetoothService> services = await widget.device.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var c in service.characteristics) {
            
            // Tìm Characteristic để GHI (Credentials)
            if (c.uuid.toString() == CHAR_CREDENTIALS_UUID) {
              _credCharacteristic = c;
            }
            
            // Tìm Characteristic để ĐỌC (Wifi List)
            if (c.uuid.toString() == CHAR_WIFI_LIST_UUID) {
              // Đọc dữ liệu từ ESP32
              List<int> value = await c.read();
              String jsonString = utf8.decode(value);
              debugPrint("Wifi List JSON: $jsonString");
              
              // Parse JSON: ["Wifi A", "Wifi B"]
              List<dynamic> list = jsonDecode(jsonString);
              if (mounted) {
                setState(() {
                  _wifiList = list.map((e) => e.toString()).toList();
                  // Lọc bỏ trùng lặp và wifi rỗng
                  _wifiList = _wifiList.toSet().toList();
                  _wifiList.removeWhere((element) => element.isEmpty);
                });
              }
            }
          }
        }
      }

      if (mounted) setState(() => _isLoading = false);

    } catch (e) {
      debugPrint("Lỗi BLE: $e");
      if (mounted) {
         _showError("Lỗi đọc dữ liệu từ thiết bị. Thử lại...");
         setState(() => _isLoading = false);
      }
    }
  }

  // 2. Gửi SSID/Pass xuống ESP32 -> Sau đó gọi API Bind Device
  Future<void> _connectAndBind() async {
    if (_selectedSsid == null) {
      _showError("Vui lòng chọn một mạng Wifi!");
      return;
    }
    if (_passController.text.isEmpty) {
      _showError("Vui lòng nhập mật khẩu Wifi!");
      return;
    }

    setState(() => _isBinding = true);

    try {
      // BƯỚC 1: Gửi thông tin xuống ESP32 qua Bluetooth
      if (_credCharacteristic != null) {
        Map<String, String> config = {
          "ssid": _selectedSsid!,
          "pass": _passController.text,
        };
        String jsonConfig = jsonEncode(config);
        
        await _credCharacteristic!.write(utf8.encode(jsonConfig));
        debugPrint("Đã gửi Wifi xuống ESP32");
        
        // Ngắt kết nối BLE ngay sau khi gửi để ESP32 rảnh tay kết nối Wifi
        await widget.device.disconnect();
      }

      // BƯỚC 2: Gọi API Server để lưu thiết bị vào phòng
      // (Giả sử User đang chọn phòng hiện tại, hoặc mặc định phòng ID=1)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');
      int? currentHouseId = prefs.getInt('currentHouseId');
      
      // Lấy danh sách phòng để user chọn (hoặc mặc định lấy phòng đầu tiên)
      // Để đơn giản, chồng sẽ lấy ID phòng đầu tiên của nhà hiện tại.
      // (Vợ có thể nâng cấp thêm 1 bước chọn phòng trước khi vào màn hình này)
      int roomId = await _getFirstRoomId(currentHouseId ?? 1); 

      // Gọi API Bind
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/devices/bind'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "name": widget.deviceType, // Tên mặc định là loại thiết bị
          "type": widget.deviceType,
          "macAddress": widget.macAddress,
          "roomId": roomId
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        throw Exception("Server lỗi: ${response.body}");
      }

    } catch (e) {
      debugPrint("Lỗi Bind: $e");
      if (mounted) {
        _showError("Cấu hình thất bại: $e");
        setState(() => _isBinding = false);
      }
    }
  }

  // Hàm phụ: Lấy ID phòng đầu tiên (Chữa cháy nếu chưa chọn phòng)
  Future<int> _getFirstRoomId(int houseId) async {
     // Vợ có thể hardcode return 1; nếu lười viết API lấy phòng
     // Hoặc gọi lại API lấy danh sách phòng ở đây
     return 1; // Tạm thời trả về 1
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Thành công! 🎉"),
        content: const Text("Thiết bị đã được thêm vào nhà của bạn.\nVui lòng đợi 1-2 phút để thiết bị kết nối mạng."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng Dialog
              Navigator.popUntil(context, (route) => route.settings.name == AppRoutes.home); // Về Home
            },
            child: const Text("Về trang chủ", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ==========================================
  // PHẦN 3: GIAO DIỆN UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cấu hình Wifi")),
      body: _isLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Đang đọc danh sách Wifi từ thiết bị...")
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Chọn Wifi cho thiết bị:", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  
                  // Danh sách Wifi
                  Container(
                    height: 300, // Chiều cao cố định cho list
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _wifiList.isEmpty 
                      ? const Center(child: Text("Không tìm thấy Wifi nào"))
                      : ListView.separated(
                          itemCount: _wifiList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final ssid = _wifiList[index];
                            return RadioListTile<String>(
                              title: Text(ssid, style: const TextStyle(fontWeight: FontWeight.w500)),
                              value: ssid,
                              groupValue: _selectedSsid,
                              onChanged: (val) => setState(() => _selectedSsid = val),
                              activeColor: Theme.of(context).primaryColor,
                            );
                          },
                        ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Ô nhập mật khẩu
                  TextField(
                    controller: _passController,
                    obscureText: true, // Ẩn mật khẩu
                    decoration: InputDecoration(
                      labelText: "Mật khẩu Wifi",
                      hintText: "Nhập mật khẩu...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Nút Kết nối
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isBinding ? null : _connectAndBind, // Disable khi đang xử lý
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 5,
                      ),
                      child: _isBinding 
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 10),
                              Text("Đang thiết lập..."),
                            ],
                          )
                        : const Text("KẾT NỐI NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}