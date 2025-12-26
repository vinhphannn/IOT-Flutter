import 'dart:math';
import 'package:flutter/material.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // 1. Animation cho quả cầu (Orb) ở dưới đáy - Hiệu ứng "thở"
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 2. Animation cho sóng âm (Wave) - Chạy liên tục
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

            // 2. Text hướng dẫn
            Text(
              "We are listening...",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "What do you want to do?",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),

            const SizedBox(height: 40),

            // 3. Text Lệnh giọng nói (To, Đậm)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "“Turn on all the lights in the entire room”",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
            ),

            const Spacer(),

            // 4. SÓNG ÂM (Visualizer)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SiriWavePainter(_waveController.value),
                    size: const Size(double.infinity, 150),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // 5. QUẢ CẦU SIRI (Orb)
            AnimatedBuilder(
              animation: _orbController,
              builder: (context, child) {
                return Container(
                  width: 80 + (_orbController.value * 10), // Phập phồng kích thước
                  height: 80 + (_orbController.value * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF4B6EF6), // Xanh dương tâm
                        Color(0xFF8B5CF6), // Tím
                        Color(0xFFEC4899), // Hồng
                        Colors.blue, // Xanh ngoài cùng
                      ],
                      stops: [0.2, 0.5, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 20 + (_orbController.value * 10), // Bóng cũng thở theo
                        spreadRadius: 5,
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// --- CLASS VẼ SÓNG ÂM (CustomPainter) ---
class SiriWavePainter extends CustomPainter {
  final double animationValue;

  SiriWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;

    // Hàm vẽ 1 đường sóng đơn lẻ
    void drawWave(Color color, double amplitude, double frequency, double speedOffset) {
      final paint = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, centerY);

      for (double x = 0; x <= width; x++) {
        // Công thức sóng Sine: y = A * sin(Bx + C)
        // A: Biên độ (độ cao sóng)
        // B: Tần số (độ dày sóng)
        // C: Pha (chuyển động)
        final double scaling = sin((x / width) * pi); // Làm sóng nhỏ ở 2 đầu, to ở giữa
        final double y = centerY +
            sin((x * frequency) + (animationValue * 2 * pi) + speedOffset) *
                amplitude *
                scaling;
        path.lineTo(x, y);
      }
      
      // Khép kín đường path để tô màu (vẽ đối xứng xuống dưới một chút để tạo độ dày)
      for (double x = width; x >= 0; x--) {
         final double scaling = sin((x / width) * pi);
         final double y = centerY - // Đảo dấu trừ để vẽ phần dưới
            sin((x * frequency) + (animationValue * 2 * pi) + speedOffset) *
                (amplitude * 0.8) * // Phần dưới nhỏ hơn xíu
                scaling;
         path.lineTo(x, y);
      }
      
      path.close();
      canvas.drawPath(path, paint);
    }

    // Vẽ 3 lớp sóng chồng lên nhau với màu khác nhau (Xanh, Tím, Cam, Lục)
    drawWave(Colors.blue, 40, 0.012, 0);       // Sóng xanh chủ đạo
    drawWave(Colors.purpleAccent, 35, 0.015, 2); // Sóng tím
    drawWave(Colors.orangeAccent, 30, 0.018, 4); // Sóng cam
    drawWave(Colors.greenAccent, 25, 0.020, 1);  // Sóng xanh lá
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}