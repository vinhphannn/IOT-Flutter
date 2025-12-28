import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../models/device_model.dart';
import '../../../services/house_service.dart';
import '../../../config/app_config.dart';


class SocketControlWidget extends StatefulWidget {
  final Device device;
  const SocketControlWidget({super.key, required this.device});

  @override
  State<SocketControlWidget> createState() => _SocketControlWidgetState();
}

class _SocketControlWidgetState extends State<SocketControlWidget> {
  // 1. Khai báo biến khớp với Key từ Backend
  double currentAmpere = 0.0; // Key "I"
  double currentWatt = 0.0;   // Key "P"
  double todayKwh = 0.0;      // Key "totalKwh"
  
  late StompClient stompClient;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    stompClient = StompClient(
      config: StompConfig(
        url: AppConfig.webSocketUrl, // Thay IP Server của vợ vào đây
        onConnect: onConnect,
        onStompError: (frame) => debugPrint("Lỗi Stomp: ${frame.body}"),
        webSocketConnectHeaders: {
        "transports": ["websocket"],
      },
      ),
    );
    stompClient.activate();
  }

void onConnect(StompFrame frame) {
  final macUpper = widget.device.macAddress.toUpperCase();
  
  stompClient.subscribe(
    destination: '/topic/device/$macUpper/data',
    callback: (frame) {
      if (frame.body != null) {
        // Log để vợ thấy dữ liệu đã vào đến callback
        debugPrint("DA NHAN TRONG CALLBACK: ${frame.body}");
        
        Map<String, dynamic> data = jsonDecode(frame.body!);
        
        if (mounted) {
          setState(() {
            // 1. Cập nhật Status (On/Off)
            if (data.containsKey('status')) {
              widget.device.isOn = data['status'];
            }

            // 2. Cập nhật Power (W) - Check cả P hoa và p thường
            var pVal = data['p'] ?? data['P'];
            if (pVal != null) {
              currentWatt = double.tryParse(pVal.toString()) ?? 0.0;
            }

            // 3. Cập nhật Current (A) - Check i thường, I hoa và A hoa
            var iVal = data['i'] ?? data['I'] ?? data['A'];
            if (iVal != null) {
              currentAmpere = double.tryParse(iVal.toString()) ?? 0.0;
            }

            // 4. Cập nhật Energy (kWh)
            var kwhVal = data['totalKwh'];
            if (kwhVal != null) {
              todayKwh = double.tryParse(kwhVal.toString()) ?? 0.0;
            }
          });
        }
      }
    },
  );
}

  Future<void> _handleToggle() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      // Optimistic UI: Đổi trạng thái ngay lập tức cho mướt
      widget.device.isOn = !widget.device.isOn;
    });

    try {
      bool success = await HouseService().toggleDevice(
        widget.device.id.toString(), 
        widget.device.isOn
      );
      if (!success) {
        setState(() => widget.device.isOn = !widget.device.isOn);
      }
    } catch (e) {
      setState(() => widget.device.isOn = !widget.device.isOn);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    stompClient.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PHẦN 1: NÚT BẤM TRUNG TÂM
                _buildCentralButton(primaryColor),

                // PHẦN 2: CHỈ SỐ THỰC TẾ (Sử dụng dữ liệu từ WebSocket)
                _buildPowerStats(),

                // PHẦN 3: THÔNG TIN PHỤ
                _buildExtraInfo(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCentralButton(Color primaryColor) {
    return GestureDetector(
      onTap: _handleToggle,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: widget.device.isOn ? 180 : 160,
                height: widget.device.isOn ? 180 : 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.device.isOn 
                      ? primaryColor.withValues(alpha: 0.15) 
                      : Colors.grey.withValues(alpha: 0.08),
                  boxShadow: widget.device.isOn ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 30, spreadRadius: 5,
                    )
                  ] : [],
                ),
              ),
              Icon(
                Icons.power_settings_new,
                size: 90,
                color: widget.device.isOn ? primaryColor : Colors.grey[400],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.device.isOn ? "DEVICE IS ON" : "DEVICE IS OFF",
            style: TextStyle(
              color: widget.device.isOn ? primaryColor : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15, offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Current", "${currentAmpere.toStringAsFixed(2)}A", Icons.bolt),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem("Power", "${currentWatt.toStringAsFixed(1)}W", Icons.speed),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildExtraInfo() {
    return Column(
      children: [
        _buildInfoCard(Icons.timer_outlined, "Usage today", "${todayKwh.toStringAsFixed(3)} kWh", Colors.blue),
        const SizedBox(height: 12),
        _buildInfoCard(Icons.history, "History", "View details", Colors.green),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ],
      ),
    );
  }
}