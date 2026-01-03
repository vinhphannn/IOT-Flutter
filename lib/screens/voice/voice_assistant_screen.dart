import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // Nhớ import thư viện này
import '/models/device_model.dart';
import '/services/device_service.dart';

import 'package:shared_preferences/shared_preferences.dart'; // <--- NHỚ THÊM CÁI NÀY

class VoiceAssistantScreen extends StatefulWidget {
  // Cần truyền danh sách thiết bị vào để so sánh tên
  final List<Device> devices; 

  const VoiceAssistantScreen({super.key, required this.devices});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _waveController;

  // --- PHẦN NÃO BỘ (LOGIC) ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  final DeviceService _deviceService = DeviceService();
  
  String _statusText = "Đang lắng nghe..."; // Text trạng thái nhỏ
  String _spokenText = ""; // Text to hiển thị câu vợ nói
  bool _isProcessing = false; // Biến check xem có đang xử lý lệnh không
List<Device> _workingDevices = [];
  @override
  void initState() {
    super.initState();
    // 1. Setup Animation (Giữ nguyên của vợ)
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
// --- LOGIC MỚI: TỰ ĐỘNG TẢI THIẾT BỊ ---
    _workingDevices = widget.devices; // Lấy từ bên ngoài truyền vào trước
    
    if (_workingDevices.isEmpty) {
        // Nếu bên ngoài không truyền (ví dụ gọi từ MainScreen), tự đi tải
        _fetchDevicesAndStartListening();
    } else {
        // Có sẵn rồi thì nghe luôn
        _initSpeech();
    }
  }

  // Hàm tự tải thiết bị từ API
  Future<void> _fetchDevicesAndStartListening() async {
      try {
          final prefs = await SharedPreferences.getInstance();
          int? houseId = prefs.getInt('currentHouseId');
          if (houseId != null) {
              var devices = await _deviceService.fetchDevicesByHouseId(houseId);
              if (mounted) {
                  setState(() {
                      _workingDevices = devices;
                      _statusText = "Đã tìm thấy ${_workingDevices.length} thiết bị";
                  });
                  // Tải xong thì bắt đầu nghe
                  _initSpeech(); 
              }
          } else {
              if (mounted) setState(() => _statusText = "Không tìm thấy Nhà!");
          }
      } catch (e) {
          print("Lỗi tải thiết bị: $e");
      }
  }

  // Hàm khởi tạo và bắt đầu nghe
  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
            // Cập nhật trạng thái (Listening, NotListening...)
            if (status == 'listening') {
                 setState(() => _statusText = "Mình đang nghe đây...");
            } else if (status == 'notListening') {
                 if (!_isProcessing) setState(() => _statusText = "Nhấn mic để nói lại");
            }
        }
      },
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      _startListening();
    } else {
      setState(() => _statusText = "Quyền truy cập bị từ chối!");
    }
  }

  void _startListening() {
    _speech.listen(
      localeId: 'vi_VN', // Nghe tiếng Việt
      onResult: (val) {
        setState(() {
          _spokenText = val.recognizedWords; // Hiện chữ vợ nói lên màn hình
        });

        // Nếu câu nói đã xong (ngừng nói khoảng 1s)
        if (val.finalResult) {
          _processCommand(val.recognizedWords.toLowerCase());
        }
      },
    );
  }

  // Hàm Xử Lý Lệnh (Brain)
  // SỬA HÀM XỬ LÝ LỆNH: Dùng _workingDevices thay vì widget.devices
  void _processCommand(String command) async {
    setState(() {
      _isProcessing = true;
      _statusText = "Đang xử lý...";
      _orbController.stop();
    });

    bool? turnOn;
    if (command.contains("bật") || command.contains("mở")) {
      turnOn = true;
    } else if (command.contains("tắt") || command.contains("đóng")) {
      turnOn = false;
    }

    if (turnOn == null) {
       _showResult("Không hiểu lệnh bật hay tắt", success: false);
       return;
    }

    bool found = false;
    // --- SỬA Ở ĐÂY: Dùng _workingDevices ---
    for (var device in _workingDevices) { 
      if (command.contains(device.name.toLowerCase())) {
        bool success = await _deviceService.toggleDevice(device.id.toString(), turnOn);
        if (success) {
           _showResult("Đã ${turnOn ? 'bật' : 'tắt'} ${device.name}", success: true);
        } else {
           _showResult("Lỗi kết nối Server", success: false);
        }
        found = true;
        break;
      }
    }

    if (!found) {
      _showResult("Không tìm thấy thiết bị nào khớp tên", success: false);
    }
  }
  // Hàm hiển thị kết quả rồi tự đóng
  void _showResult(String message, {required bool success}) {
    if (!mounted) return;
    setState(() {
      _statusText = success ? "Thành công!" : "Thử lại nhé";
      _spokenText = message;
    });
    
    // Đợi 1.5 giây rồi đóng màn hình
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.pop(context); 
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _waveController.dispose();
    _speech.stop(); // Dừng nghe khi thoát
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Nút Floating Action Button để bấm nghe lại nếu cần
      floatingActionButton: FloatingActionButton(
        backgroundColor: _speech.isListening ? Colors.red : Colors.blueAccent,
        onPressed: () {
            if (_speech.isListening) {
                _speech.stop();
            } else {
                _startListening();
                _orbController.repeat(reverse: true); // Chạy lại animation
            }
        },
        child: Icon(_speech.isListening ? Icons.mic : Icons.mic_none),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
      body: SafeArea(
        child: Column(
          children: [
            // 1. Nút Đóng (X)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 30, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 2. Text hướng dẫn (Dynamic)
            Text(
              _statusText, // Thay đổi theo trạng thái: Đang nghe, Đang xử lý...
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            
            const SizedBox(height: 40),

            // 3. Text Lệnh giọng nói (Cái vợ nói sẽ hiện ở đây)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                _spokenText.isEmpty ? "“Đang chờ vợ nói...”" : "“$_spokenText”",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isProcessing ? Colors.blue : Colors.black, // Đổi màu khi xử lý
                  height: 1.3,
                ),
              ),
            ),

            const Spacer(),

            // 4. SÓNG ÂM (Giữ nguyên)
         // 4. SÓNG ÂM
            SizedBox(
              height: 150,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  // LOGIC: Nếu đang nghe -> Cao 1.0 (Sóng to)
                  //        Nếu không nghe -> Cao 0.0 (Đường thẳng)
                  double waveScale = _speech.isListening ? 1.0 : 0.0; 
                  
                  // Muốn hiệu ứng mượt hơn (sóng nhỏ dần rồi tắt) khi đang xử lý:
                  if (_isProcessing) waveScale = 0.1; 

                  return CustomPaint(
                    // Truyền 2 tham số: Giá trị animation và Độ cao sóng
                    painter: SiriWavePainter(_waveController.value, waveScale),
                    size: const Size(double.infinity, 150),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // 5. QUẢ CẦU SIRI (Giữ nguyên)
            AnimatedBuilder(
              animation: _orbController,
              builder: (context, child) {
                return Container(
                  width: 80 + (_orbController.value * 20),
                  height: 80 + (_orbController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF4B6EF6),
                        Color(0xFF8B5CF6),
                        Color(0xFFEC4899),
                        Colors.blue,
                      ],
                      stops: [0.2, 0.5, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 20 + (_orbController.value * 10),
                        spreadRadius: 5,
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 80), // Chừa chỗ cho nút Mic ở dưới
          ],
        ),
      ),
    );
  }
}

// --- CLASS VẼ SÓNG ÂM (GIỮ NGUYÊN CỦA VỢ) ---
// --- CLASS VẼ SÓNG ÂM (ĐÃ NÂNG CẤP) ---
class SiriWavePainter extends CustomPainter {
  final double animationValue;
  final double waveformHeight; // <--- Biến mới để chỉnh độ cao sóng

  SiriWavePainter(this.animationValue, this.waveformHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;

    void drawWave(Color color, double amplitude, double frequency, double speedOffset) {
      final paint = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, centerY);

      // Nếu waveformHeight = 0 thì vẽ đường thẳng luôn cho nhanh
      if (waveformHeight == 0) {
         path.lineTo(width, centerY);
         path.close();
         canvas.drawPath(path, paint);
         return;
      }

      for (double x = 0; x <= width; x++) {
        final double scaling = sin((x / width) * pi); 
        final double y = centerY +
            sin((x * frequency) + (animationValue * 2 * pi) + speedOffset) *
                (amplitude * waveformHeight) * // <--- Nhân thêm waveformHeight vào đây
                scaling;
        path.lineTo(x, y);
      }
      
      for (double x = width; x >= 0; x--) {
          final double scaling = sin((x / width) * pi);
          final double y = centerY - 
            sin((x * frequency) + (animationValue * 2 * pi) + speedOffset) *
                (amplitude * 0.8 * waveformHeight) * // <--- Và nhân vào đây nữa
                scaling;
          path.lineTo(x, y);
      }
      
      path.close();
      canvas.drawPath(path, paint);
    }

    // Vẽ các lớp sóng
    drawWave(Colors.blue, 40, 0.012, 0);       
    drawWave(Colors.purpleAccent, 35, 0.015, 2); 
    drawWave(Colors.orangeAccent, 30, 0.018, 4); 
    drawWave(Colors.greenAccent, 25, 0.020, 1);  
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}