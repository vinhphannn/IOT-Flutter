import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../routes.dart';
import '../../config/app_config.dart';
import '../../models/device_model.dart'; 
import 'tabs/nearby_scan_tab.dart'; 

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

  void _completeConnection() {
    if (_isConnected) return;
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _progress = 1.0; 
        _isConnected = true; 
      });

      // KHỚP VỚI MODEL DEVICE MỚI CỦA VỢ
      Device successDevice = Device(
        id: 0, 
        name: widget.device.name,
        macAddress: widget.device.macAddress,
        type: widget.device.type, // Lấy từ DeviceItem
        isOn: true,
        roomName: "Smart Home",
        isWiFi: true, // Kết nối qua App thì mặc định là true
      );

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.pushReplacementNamed( 
            context, 
            AppRoutes.connectedSuccess, 
            arguments: successDevice
          );
        }
      });
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