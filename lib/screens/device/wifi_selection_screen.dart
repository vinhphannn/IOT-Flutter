import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// UUID Phải khớp với Code ESP32
const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

class WifiSelectionScreen extends StatefulWidget {
  final BluetoothDevice device;
  final String deviceId;

  const WifiSelectionScreen({super.key, required this.device, required this.deviceId});

  @override
  State<WifiSelectionScreen> createState() => _WifiSelectionScreenState();
}

class _WifiSelectionScreenState extends State<WifiSelectionScreen> {
  bool _isLoading = true;
  List<String> _wifiList = [];
  BluetoothCharacteristic? _targetCharacteristic;
  
  final TextEditingController _passController = TextEditingController();
  String? _selectedSsid;

  @override
  void initState() {
    super.initState();
    _discoverServices();
  }

  // 1. Tìm Service và Characteristic để giao tiếp
  Future<void> _discoverServices() async {
    try {
      // Khám phá dịch vụ
      List<BluetoothService> services = await widget.device.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var c in service.characteristics) {
            if (c.uuid.toString() == CHARACTERISTIC_UUID) {
              _targetCharacteristic = c;
              break;
            }
          }
        }
      }

      if (_targetCharacteristic != null) {
        // Nếu ESP hỗ trợ đọc danh sách wifi qua BLE thì đọc ở đây
        // (Tạm thời giả lập list wifi để demo nhanh, vì đọc list dài qua BLE hơi phức tạp)
        // Vợ có thể cải tiến sau bằng cách gửi lệnh "SCAN" và lắng nghe notify.
        setState(() {
          _wifiList = ["Wifi_Nha_Minh", "Wifi_Tang_1", "Wifi_Hang_Xom", "Cafe_Free"];
          _isLoading = false;
        });
      } else {
        _showError("Không tìm thấy dịch vụ cấu hình trên thiết bị!");
      }
    } catch (e) {
      _showError("Lỗi kết nối dịch vụ: $e");
    }
  }

  // 2. Gửi thông tin Wifi xuống ESP
  Future<void> _sendConfig() async {
    if (_selectedSsid == null || _passController.text.isEmpty) {
      _showError("Vui lòng chọn Wifi và nhập mật khẩu!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tạo JSON cấu hình
      Map<String, String> config = {
        "ssid": _selectedSsid!,
        "pass": _passController.text,
        "uid": "USER_123", // Lấy ID user thật từ AuthService sau này
      };
      
      String jsonConfig = jsonEncode(config);
      
      // Gửi xuống ESP
      if (_targetCharacteristic != null) {
        await _targetCharacteristic!.write(utf8.encode(jsonConfig));
        
        // Gửi xong -> Ngắt kết nối
        await widget.device.disconnect();
        
        if (mounted) {
          // Quay về Home hoặc màn hình thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cấu hình thành công! Thiết bị đang khởi động lại.")),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      _showError("Gửi cấu hình thất bại: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chọn Wifi cho thiết bị")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chọn Wifi để thiết bị kết nối:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _wifiList.length,
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
                    decoration: const InputDecoration(
                      labelText: "Mật khẩu Wifi",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _sendConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("KẾT NỐI NGAY"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}