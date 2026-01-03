import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../routes.dart';
import '../../config/app_config.dart';
import '../../models/device_model.dart'; 
import 'tabs/nearby_scan_tab.dart'; 

import 'package:provider/provider.dart'; // Để gọi Provider
import '../../providers/device_provider.dart'; // Để lấy hàm fetchDevices

class ConnectDeviceScreen extends StatefulWidget {
  final DeviceItem device; 

  const ConnectDeviceScreen({super.key, required this.device});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  double _progress = 0.0; 
  Timer? _timer;
  StompClient? stompClient;
  bool _isConnected = false; 

  @override
  void initState() {
    super.initState();
    _startProgress(); 
    _initWebSocket(); 
  }

  void _initWebSocket() {
    stompClient = StompClient(
      config: StompConfig(
        url: AppConfig.webSocketUrl,
        onConnect: (frame) {
          // LỖI ĐỎ Ở ĐÂY SẼ HẾT VÌ DEVICEITEM ĐÃ CÓ MACADDRESS
          final macUpper = widget.device.macAddress.toUpperCase();
          
          stompClient!.subscribe(
            destination: '/topic/device/$macUpper/data',
            callback: (frame) {
              if (frame.body != null) {
                debugPrint("🎯 Tín hiệu từ ESP: Đã nhận data đầu tiên!");
                _completeConnection(); 
              }
            },
          );
        },
        onStompError: (frame) => debugPrint("❌ Lỗi Stomp: ${frame.body}"),
      ),
    );
    stompClient!.activate();
  }

  void _startProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          if (_progress < 0.90) { _progress += 0.01; }
        });
      }
    });
  }

void _completeConnection() async {
    if (_isConnected) return;
    
    // Ngắt lắng nghe ngay lập tức (nếu vợ đã thêm biến _unsubscribeFn như chồng dặn trước đó)
    // if (_unsubscribeFn != null) { _unsubscribeFn!(); _unsubscribeFn = null; }

    _timer?.cancel();

    if (mounted) {
      setState(() {
        _progress = 1.0;
        _isConnected = true;
      });

      // --- SỬA TỪ ĐÂY ---
      
      // 1. Gọi Provider tải lại danh sách thiết bị từ Server về
      // Mục đích: Để lấy được con thiết bị mới thêm (có ID xịn từ Database)
      final provider = Provider.of<DeviceProvider>(context, listen: false);
      await provider.fetchDevices(); 

      if (!mounted) return; // Check lại mounted sau khi await

      try {
        // 2. Tìm lại con thiết bị vừa thêm bằng MAC Address trong danh sách mới tải
        final realDevice = provider.devices.firstWhere(
          (d) => d.macAddress.toUpperCase() == widget.device.macAddress.toUpperCase(),
          orElse: () => Device( // Fallback phòng hờ (ít khi xảy ra)
            id: 0, 
            name: widget.device.name, 
            macAddress: widget.device.macAddress, 
            type: widget.device.type, 
            isOn: true, 
            roomName: "Smart Home"
          )
        );

        print("✅ Đã lấy được ID thật: ${realDevice.id}");

        // 3. Chờ xíu cho hiệu ứng 100% hiện lên rồi chuyển trang
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.pushReplacementNamed( 
              context, 
              AppRoutes.connectedSuccess, 
              arguments: realDevice // <--- Truyền con XỊN này đi
            );
          }
        });

      } catch (e) {
        print("❌ Lỗi tìm thiết bị: $e");
      }
    }
  }
  @override
  void dispose() {
    _timer?.cancel();
    stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final int percentage = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: const Text("Connecting", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200, height: 200,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    strokeCap: StrokeCap.round, 
                  ),
                  Icon(widget.device.icon, size: 80, color: primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text("$percentage%", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: primaryColor)),
            const SizedBox(height: 10),
            Text(
              _progress < 0.9 ? "Configuring your device..." : "Waiting for device to go online...",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}