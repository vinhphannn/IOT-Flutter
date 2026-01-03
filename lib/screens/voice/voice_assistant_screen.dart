import 'dart:async';
import 'dart:math'; // Import để dùng hàm sin, pi, pow cho sóng
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '/models/device_model.dart';
import '/services/device_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final List<Device> devices; 

  const VoiceAssistantScreen({super.key, required this.devices});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _waveController;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final DeviceService _deviceService = DeviceService();
  
  String _statusText = "Nhấn vào quả cầu để nói..."; 
  String _spokenText = ""; 
  bool _isProcessing = false; 
  List<Device> _workingDevices = [];

  @override
  void initState() {
    super.initState();
    // 1. Animation Quả cầu (Thở)
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    ); 

    // 2. Animation Sóng âm
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _workingDevices = widget.devices; 
    
    if (_workingDevices.isEmpty) {
      _fetchDevices();
    } else {
      _initSpeech();
    }
  }

  Future<void> _fetchDevices() async {
      try {
          final prefs = await SharedPreferences.getInstance();
          int? houseId = prefs.getInt('currentHouseId');
          if (houseId != null) {
              var devices = await _deviceService.fetchDevicesByHouseId(houseId);
              if (mounted) {
                  setState(() {
                      _workingDevices = devices;
                  });
                  _initSpeech(); 
              }
          }
      } catch (e) {
          debugPrint("Lỗi tải thiết bị: $e");
      }
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
            if (status == 'listening') {
                 setState(() => _statusText = "Mình đang nghe đây...");
                 _orbController.repeat(reverse: true); 
            } else if (status == 'notListening') {
                 if (!_isProcessing) {
                   setState(() => _statusText = "Nhấn vào quả cầu để nói lại");
                   _orbController.stop(); 
                   _orbController.value = 0.0;
                 }
            }
        }
      },
      onError: (error) => debugPrint('Error: $error'),
    );

    if (!available) {
      setState(() => _statusText = "Quyền truy cập bị từ chối!");
    }
  }

  void _toggleListening() {
    if (_speech.isListening) {
      _speech.stop();
      _orbController.stop();
      _orbController.value = 0.0;
    } else {
      _startListening();
    }
  }

  void _startListening() {
    _speech.listen(
      localeId: 'vi_VN', 
      onResult: (val) {
        setState(() {
          _spokenText = val.recognizedWords; 
        });

        if (val.finalResult) {
          _processCommand(val.recognizedWords.toLowerCase());
        }
      },
    );
  }

  void _processCommand(String command) async {
    setState(() {
      _isProcessing = true;
      _statusText = "Đang xử lý...";
      _orbController.stop(); 
      _orbController.value = 1.0; 
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

  void _showResult(String message, {required bool success}) {
    if (!mounted) return;
    setState(() {
      _statusText = success ? "Thành công!" : "Thử lại nhé";
      _spokenText = message;
      _isProcessing = false; 
      _orbController.value = 0.0; 
    });
    
    if (success) {
      Timer(const Duration(milliseconds: 2000), () {
        if (mounted) Navigator.pop(context); 
      });
    }
  }

  @override
  void dispose() {
    _orbController.dispose();
    _waveController.dispose();
    _speech.stop(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: SafeArea(
        child: Column(
          children: [
            // 1. Nút Đóng
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

            const SizedBox(height: 20),

            // 2. Trạng thái
            Text(
              _statusText, 
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            
            const SizedBox(height: 40),

            // 3. Lời nói
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                _spokenText.isEmpty ? "..." : "“$_spokenText”",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isProcessing ? Colors.blue : Colors.black, 
                  height: 1.3,
                ),
              ),
            ),

            const Spacer(),

            // 4. Sóng âm
            SizedBox(
              height: 120, 
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  double waveScale = _speech.isListening ? 1.0 : 0.0;
                  if (_isProcessing) waveScale = 0.3; 

                  return CustomPaint(
                    painter: SiriWavePainter(_waveController.value, waveScale),
                    size: const Size(double.infinity, 120),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // 5. NÚT QUẢ CẦU SIRI
            GestureDetector(
              onTap: _toggleListening, 
              child: AnimatedBuilder(
                animation: _orbController,
                builder: (context, child) {
                  double size = 80 + (_orbController.value * 25);
                  
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        // --- SỬA LỖI Ở ĐÂY: Đảm bảo cả 2 trường hợp đều có đủ 4 màu ---
                        colors: _speech.isListening || _isProcessing
                            ? [ // 4 màu
                                const Color(0xFF4B6EF6),
                                const Color(0xFF8B5CF6),
                                const Color(0xFFEC4899),
                                Colors.blue,
                              ]
                            : [ // 4 màu (Đã thêm màu cuối cho đủ bộ)
                                Colors.blueGrey.shade100,
                                Colors.blueGrey.shade200,
                                Colors.blueGrey.shade300,
                                Colors.blueGrey.shade400, 
                              ],
                        // stops có 4 phần tử -> colors bắt buộc phải có 4 phần tử
                        stops: const [0.2, 0.5, 0.8, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_speech.isListening || _isProcessing)
                              ? Colors.blueAccent.withOpacity(0.5) 
                              : Colors.transparent,
                          blurRadius: 20 + (_orbController.value * 20),
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _speech.isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// --- CLASS VẼ SÓNG ÂM ---
class SiriWavePainter extends CustomPainter {
  final double animationValue;
  final double waveformHeight;

  SiriWavePainter(this.animationValue, this.waveformHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;

    void drawLineWave(Color color, double amplitude, double frequency, double speed, double strokeWidth) {
        final paint = Paint()
          ..color = color.withOpacity(0.8) 
          ..style = PaintingStyle.stroke 
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
          
        final path = Path();
        path.moveTo(0, centerY);
        
        if (waveformHeight <= 0.05) {
           return;
        }

        for (double x = 0; x <= width; x++) {
            double scaling = 1 - pow((x / width * 2 - 1).abs(), 2).toDouble();
            double y = centerY + sin(x * frequency + animationValue * 10 + speed) * amplitude * waveformHeight * scaling;
            path.lineTo(x, y);
        }
        canvas.drawPath(path, paint);
    }

    drawLineWave(Colors.redAccent, 40, 0.015, 1.0, 3.0);       
    drawLineWave(Colors.blueAccent, 35, 0.018, 2.2, 2.5); 
    drawLineWave(Colors.purpleAccent, 30, 0.022, 4.5, 2.0); 
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}