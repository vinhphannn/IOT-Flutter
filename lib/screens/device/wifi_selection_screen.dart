import 'dart:convert';
import 'dart:io'; // Để check Platform (Android/iOS)
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../routes.dart';

// UUID Phải khớp với Code ESP32
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHAR_CREDENTIALS_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; // Ghi
const String CHAR_WIFI_LIST_UUID   = "1c95d5e3-d8f7-413a-bf3d-7a2e5d7be87e"; // Đọc/Notify

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
  String _statusMessage = "Đang đọc danh sách Wifi..."; // Biến hiển thị trạng thái
  List<String> _wifiList = [];
  
  BluetoothCharacteristic? _credCharacteristic; // Để ghi SSID/Pass hoặc lệnh SCAN

  final TextEditingController _passController = TextEditingController();
  String? _selectedSsid;

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  // 1. Tìm Service, Đọc Wifi và Đăng ký nhận thông báo (Notify)
  Future<void> _discoverServices() async {
    try {
      // Android cần xin MTU cao hơn để nhận chuỗi JSON dài
      if (Platform.isAndroid) {
        await widget.device.requestMtu(512);
      }

      List<BluetoothService> services = await widget.device.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var c in service.characteristics) {
            
            // Tìm Characteristic để GHI (Gửi Wifi hoặc lệnh SCAN)
            if (c.uuid.toString() == CHAR_CREDENTIALS_UUID) {
              _credCharacteristic = c;
            }
            
            // Tìm Characteristic để ĐỌC & NOTIFY (Nhận List Wifi & Trạng thái)
            if (c.uuid.toString() == CHAR_WIFI_LIST_UUID) {
              // A. Đăng ký lắng nghe (Notify)
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) {
                _handleNotify(value);
              });

              // B. Đọc dữ liệu lần đầu
              List<int> value = await c.read();
              _handleNotify(value);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi BLE: $e");
      if (mounted) {
         setState(() {
           _isLoading = false;
           _statusMessage = "Lỗi kết nối Bluetooth!";
         });
         _showError("Không thể đọc dữ liệu từ thiết bị.");
      }
    }
  }

  // Hàm xử lý dữ liệu ESP32 gửi lên
  void _handleNotify(List<int> value) {
    if (value.isEmpty) return;
    
    String data = utf8.decode(value);
    debugPrint(">>> BLE Notify: $data");

    // Xử lý các trạng thái từ ESP32
    if (data == "CONNECTING") {
      setState(() => _statusMessage = "Thiết bị đang thử kết nối Wifi...");
    } else if (data == "SUCCESS") {
      // ESP32 báo đã có Wifi -> Giờ mới gọi API Server
      _onWifiConnectedSuccess();
    } else if (data == "FAIL") {
      setState(() {
        _isLoading = false;
        _statusMessage = "Kết nối thất bại. Vui lòng thử lại.";
      });
      _showError("Sai mật khẩu hoặc sóng yếu!");
    } else {
      // Giả sử đây là JSON danh sách Wifi
      try {
        List<dynamic> list = jsonDecode(data);
        if (mounted) {
          setState(() {
            _wifiList = list.map((e) => e.toString()).toList();
            _wifiList = _wifiList.toSet().toList(); // Xóa trùng
            _wifiList.removeWhere((element) => element.isEmpty);
            
            _isLoading = false; // Đã tải xong danh sách
          });
        }
      } catch (e) {
        // Dữ liệu không phải JSON (có thể là rác hoặc chưa đủ gói, bỏ qua)
      }
    }
  }

  // 2. Gửi SSID/Pass xuống ESP32 (Chỉ gửi BLE, KHÔNG gọi API ngay)
  Future<void> _sendConfig() async {
    if (_selectedSsid == null) {
      _showError("Vui lòng chọn một mạng Wifi!");
      return;
    }
    if (_passController.text.isEmpty) {
      _showError("Vui lòng nhập mật khẩu Wifi!");
      return;
    }

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _statusMessage = "Đang gửi cấu hình xuống thiết bị...";
    });

    try {
      if (_credCharacteristic != null) {
        Map<String, String> config = {
          "ssid": _selectedSsid!,
          "pass": _passController.text,
        };
        String jsonConfig = jsonEncode(config);
        
        // Gửi xuống ESP
        await _credCharacteristic!.write(utf8.encode(jsonConfig));
        debugPrint("Đã gửi thông tin Wifi. Đợi ESP phản hồi...");
        
        // QUAN TRỌNG: Không disconnect ở đây. Đợi Notify "SUCCESS" hoặc "FAIL".
      }
    } catch (e) {
      _showError("Lỗi gửi dữ liệu: $e");
      setState(() => _isLoading = false);
    }
  }

  // 3. Hàm gọi API Bind (Chỉ chạy khi nhận được "SUCCESS" từ ESP)
// Trong file wifi_selection_screen.dart

  // 3. Xử lý khi Wifi kết nối thành công
  Future<void> _onWifiConnectedSuccess() async {
    setState(() => _statusMessage = "Cấu hình hoàn tất!");

    // Vì thiết bị đã được lưu ở màn hình trước (DeviceSetupScreen)
    // Nên giờ chỉ cần ngắt kết nối BLE và báo tin vui thôi.
    
    try {
      await widget.device.disconnect(); // Ngắt BLE để ESP chạy Wifi
    } catch (e) {
      debugPrint("Lỗi ngắt kết nối: $e");
    }

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Thành công mỹ mãn! 🎉"),
        content: const Text("Thiết bị đã được lưu vào hệ thống và kết nối Wifi thành công."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng Dialog
              // Về thẳng trang chủ, xóa hết lịch sử setup
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false); 
            },
            child: const Text("Về Trang Chủ", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // 4. Hàm Refresh (Quét lại Wifi)
  Future<void> _refreshWifi() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Đang yêu cầu quét lại Wifi...";
      _wifiList.clear();
    });

    try {
      if (_credCharacteristic != null) {
        // Gửi lệnh "SCAN" xuống ESP (ESP sẽ quét và gửi lại list mới qua Notify)
        await _credCharacteristic!.write(utf8.encode("SCAN"));
      }
    } catch (e) {
      _showError("Lỗi refresh: $e");
      setState(() => _isLoading = false);
    }
  }


  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cấu hình Wifi"),
        actions: [
          // Nút Refresh xịn xò
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshWifi,
            tooltip: "Quét lại Wifi",
          )
        ],
      ),
      body: _isLoading
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
                    height: 300,
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
                    obscureText: true,
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
                      onPressed: _isLoading ? null : _sendConfig, // Disable khi đang xử lý
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 5,
                      ),
                      child: const Text("KẾT NỐI NGAY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}