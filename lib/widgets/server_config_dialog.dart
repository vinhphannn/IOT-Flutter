import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback onSaved; // Gọi lại hàm này khi lưu xong

  const ServerConfigDialog({super.key, required this.onSaved});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Hiển thị IP hiện tại lên ô nhập (cắt bỏ http:// và /api cho dễ nhìn)
    String current = AppConfig.baseUrl
        .replaceAll("http://", "")
        .replaceAll("/api", "");
    _ipController.text = current;
  }

  void _save(String ip) async {
    if (ip.isEmpty) return;
    // Tự động thêm http và /api nếu vợ lười gõ
    String fullUrl = "http://$ip/api";
    await AppConfig.setBaseUrl(fullUrl);
    
    if (mounted) {
      Navigator.pop(context); // Đóng popup
      widget.onSaved(); // Báo cho Splash Screen biết là đã lưu
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Cấu hình Server"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Không kết nối được Server. Vui lòng kiểm tra IP."),
          const SizedBox(height: 20),
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: "Nhập IP (VD: 192.168.1.5:8080)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Nút chọn nhanh Máy Ảo
              ActionChip(
                label: const Text("Máy ảo (Emulator)"),
                onPressed: () => _ipController.text = "10.0.2.2:8080",
              ),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Nút chọn nhanh Máy Thật (lấy IP Wifi ví dụ)
            // Vợ thay số 192.168.1.X bằng số hay dùng để đỡ phải gõ
            _ipController.text = "192.168.1.12:8080"; 
          },
          child: const Text("Gợi ý IP thật"),
        ),
        ElevatedButton(
          onPressed: () => _save(_ipController.text.trim()),
          child: const Text("LƯU & THỬ LẠI"),
        ),
      ],
    );
  }
}