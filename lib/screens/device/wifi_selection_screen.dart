import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../routes.dart';
import '../../models/device_model.dart';
import 'tabs/nearby_scan_tab.dart'; // QUAN TRỌNG: Import này để hết lỗi DeviceItem

// Đổi tên hằng số sang lowerCamelCase để hết cảnh báo
const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const String charCredentialsUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String charWifiListUuid = "1c95d5e3-d8f7-413a-bf3d-7a2e5d7be87e";

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

  Future<void> _discoverServices() async {
    try {
      if (Platform.isAndroid) {
        await widget.device.requestMtu(512); 
      }

      List<BluetoothService> services = await widget.device.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var c in service.characteristics) {
            String charUuid = c.uuid.toString().toLowerCase();

            if (charUuid == charCredentialsUuid.toLowerCase()) {
              _credCharacteristic = c;
            }
            
            if (charUuid == charWifiListUuid.toLowerCase()) {
              final subscription = c.lastValueStream.listen((value) {
                _handleNotify(value);
              });
              widget.device.cancelWhenDisconnected(subscription);
              await c.setNotifyValue(true);
              try { await c.read(); } catch (e) { /* ignore */ }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) _showError("Lỗi Bluetooth: $e");
    }
  }

  void _handleNotify(List<int> value) {
    if (value.isEmpty) return;
    try {
      String data = utf8.decode(value);
      if (data == "CONNECTING") {
        setState(() => _statusMessage = "Thiết bị đang thử kết nối Wifi...");
      } else if (data == "SUCCESS") {
        // Nếu ESP báo Success ngay (hiếm gặp), mình vẫn xử lý
      } else {
        try {
          List<dynamic> list = jsonDecode(data);
          if (mounted) {
            setState(() {
              _wifiList = list.map((e) => e.toString()).toSet().toList();
              _wifiList.removeWhere((element) => element.isEmpty);
              _isLoading = false;
            });
          }
        } catch (e) { debugPrint("JSON error: $e"); }
      }
    } catch (e) { debugPrint("Decode error: $e"); }
  }

  Future<void> _sendConfig() async {
    if (_selectedSsid == null || _passController.text.isEmpty) {
      _showError("Vui lòng chọn Wifi và nhập mật khẩu!");
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      if (_credCharacteristic != null) {
        Map<String, String> config = {
          "ssid": _selectedSsid!,
          "pass": _passController.text,
        };
        
        await _credCharacteristic!.write(utf8.encode(jsonEncode(config)));

        // CHUYỂN TRANG NGAY LẬP TỨC SANG TRANG %
        if (mounted) {
          DeviceItem tempItem = DeviceItem(
            name: widget.deviceType,
            icon: widget.deviceType == "SOCKET" ? Icons.power : Icons.lightbulb,
            color: Theme.of(context).primaryColor,
            macAddress: widget.macAddress,
            type: widget.deviceType,
          );

          // Ngắt BLE để ESP rảnh tay kết nối Wifi
          await widget.device.disconnect();

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.connectDevice,
              arguments: tempItem,
            );
          }
        }
      }
    } catch (e) {
      _showError("Gửi thất bại: $e");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cấu hình Wifi")),
      body: _isLoading
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_statusMessage),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text("Chọn Wifi cho thiết bị:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      itemCount: _wifiList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return RadioListTile<String>(
                          title: Text(_wifiList[index]),
                          value: _wifiList[index],
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
                    decoration: const InputDecoration(labelText: "Mật khẩu Wifi", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _sendConfig,
                      child: const Text("KẾT NỐI"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}