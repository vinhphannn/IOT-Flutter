import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../models/device_model.dart';
import '../../../services/house_service.dart';
import '../../../config/app_config.dart';
import '../../device/log/device_log_screen.dart'; // Vợ nhớ kiểm tra đường dẫn tới file DeviceLogScreen này nhé

class SocketControlWidget extends StatefulWidget {
  final Device device;
  const SocketControlWidget({super.key, required this.device});

  @override
  State<SocketControlWidget> createState() => _SocketControlWidgetState();
}

class _SocketControlWidgetState extends State<SocketControlWidget> {
  double currentAmpere = 0.0;
  double currentWatt = 0.0;
  double todayKwh = 0.0;
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
        url: AppConfig.webSocketUrl,
        onConnect: onConnect,
        onStompError: (frame) => debugPrint("Lỗi Stomp: ${frame.body}"),
        webSocketConnectHeaders: {"transports": ["websocket"]},
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
          Map<String, dynamic> data = jsonDecode(frame.body!);
          if (mounted) {
            setState(() {
              if (data.containsKey('status')) {
                widget.device.isOn = data['status'];
              }
              var pVal = data['p'] ?? data['P'];
              if (pVal != null) currentWatt = double.tryParse(pVal.toString()) ?? 0.0;
              var iVal = data['i'] ?? data['I'] ?? data['A'];
              if (iVal != null) currentAmpere = double.tryParse(iVal.toString()) ?? 0.0;
              var kwhVal = data['totalKwh'];
              if (kwhVal != null) todayKwh = double.tryParse(kwhVal.toString()) ?? 0.0;
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
      widget.device.isOn = !widget.device.isOn;
    });

    try {
      bool success = await HouseService().toggleDevice(
        widget.device.id.toString(),
        widget.device.isOn,
      );
      if (!success) setState(() => widget.device.isOn = !widget.device.isOn);
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

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          // Ép chiều cao tối thiểu để Column dãn cách MainAxisAlignment.spaceBetween hoạt động
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. NÚT BẤM TRUNG TÂM (Đã chỉnh lại tỉ lệ cho cân đối)
              _buildCentralButton(primaryColor),

              // 2. CHỈ SỐ THỰC TẾ
              _buildPowerStats(),

              // 3. THÔNG TIN PHỤ
              _buildExtraInfo(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCentralButton(Color primaryColor) {
    return GestureDetector(
      onTap: _handleToggle,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Vòng tròn hiệu ứng lan tỏa
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: widget.device.isOn ? 200 : 180,
                height: widget.device.isOn ? 200 : 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.device.isOn
                      ? primaryColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.05),
                  border: Border.all(
                    color: widget.device.isOn 
                        ? primaryColor.withOpacity(0.2) 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              // Icon nút nguồn
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.device.isOn ? primaryColor : Colors.grey[200],
                  boxShadow: widget.device.isOn ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ] : [],
                ),
                child: Icon(
                  Icons.power_settings_new,
                  size: 50,
                  color: widget.device.isOn ? Colors.white : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.device.isOn ? "TRẠNG THÁI: ĐANG BẬT" : "TRẠNG THÁI: ĐANG TẮT",
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 1.5,
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
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Dòng điện", "${currentAmpere.toStringAsFixed(2)}A", Icons.bolt_rounded),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          _buildStatItem("Công suất", "${currentWatt.toStringAsFixed(1)}W", Icons.speed_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildExtraInfo() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.eco_outlined, 
          title: "Điện năng hôm nay", 
          sub: "${todayKwh.toStringAsFixed(3)} kWh", 
          color: Colors.green,
          onTap: () {}, // Hiện tại chưa có trang điện năng nên để trống
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.history_rounded, 
          title: "Lịch sử hoạt động", 
          sub: "Xem chi tiết", 
          color: Colors.blue,
          onTap: () {
            // SỰ KIỆN NHẤN VÀO ĐỂ CHUYỂN TRANG ĐÂY VỢ ƠI
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceLogScreen(deviceId: widget.device.id),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon, 
    required String title, 
    required String sub, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Đảm bảo nhấn vào toàn bộ vùng thẻ đều nhận
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}