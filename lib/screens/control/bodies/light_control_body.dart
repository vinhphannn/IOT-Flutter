import 'dart:math';
import 'package:flutter/material.dart';

class LightControlBody extends StatefulWidget {
  const LightControlBody({super.key});

  @override
  State<LightControlBody> createState() => _LightControlBodyState();
}

class _LightControlBodyState extends State<LightControlBody> {
  int _selectedTab = 0; // 0: White, 1: Color, 2: Scene
  double _brightness = 85; // Độ sáng

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. SEGMENTED TABS (White - Color - Scene)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTabItem("White", 0),
              _buildTabItem("Color", 1),
              _buildTabItem("Scene", 2),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. VÒNG TRÒN CHỈNH MÀU (CIRCULAR SLIDER)
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vẽ vòng cung gradient (Dùng CustomPaint)
              CustomPaint(
                size: const Size(300, 300),
                painter: ArcGradientPainter(),
              ),
              
              // Hình cái bóng đèn ở giữa
              Icon(Icons.lightbulb, size: 80, color: Colors.grey[200]),
              
              // Cái nút tròn để kéo (Knob) - Giả lập vị trí
              Positioned(
                left: 40, 
                top: 100, // Căn chỉnh toạ độ tương đối theo hình
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD57F), // Màu vàng nhạt
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10)
                    ]
                  ),
                ),
              )
            ],
          ),
        ),

        // 3. THANH TRƯỢT ĐỘ SÁNG (BRIGHTNESS SLIDER)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.black54),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    activeTrackColor: const Color(0xFF4B6EF6),
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 0), // Bỏ hiệu ứng loang khi bấm
                  ),
                  child: Slider(
                    value: _brightness,
                    min: 0,
                    max: 100,
                    onChanged: (val) {
                      setState(() => _brightness = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "${_brightness.toInt()}%",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  // Widget Tab nhỏ
  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4B6EF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// Class vẽ cái vòng cung màu sắc (Gradient Arc)
class ArcGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 35
      ..strokeCap = StrokeCap.round;

    // Tạo Gradient quét từ Vàng sang Xanh
    final rect = Rect.fromCircle(center: center, radius: radius);
    paint.shader = const SweepGradient(
      startAngle: pi,
      endAngle: 3 * pi,
      tileMode: TileMode.repeated,
      colors: [
        Color(0xFFFFD57F), // Vàng ấm
        Colors.white,
        Color(0xFF8DA4F7), // Xanh lạnh
      ],
      stops: [0.0, 0.5, 1.0], // Điểm dừng màu
    ).createShader(rect);

    // Vẽ cung tròn (hở phía dưới một chút)
    // Start từ góc 135 độ (2.35 rad) đến góc 405 độ
    canvas.drawArc(rect, 2.6, 4.2, false, paint);
    
    // Vẽ đường viền mỏng bên trong cho đẹp
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.shade300;
    canvas.drawCircle(center, radius - 25, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}