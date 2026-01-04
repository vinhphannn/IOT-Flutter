import 'package:flutter/material.dart';

class TapToRunTab extends StatelessWidget {
  final int houseId; // Nhận ID nhà để sau này gọi API

  const TapToRunTab({super.key, required this.houseId});

  // Dữ liệu giả mô phỏng thiết kế
  final List<Map<String, dynamic>> _tapItems = const [
    {
      "title": "Bedtime Prep",
      "tasks": "2 tasks",
      "icon": Icons.bedtime,
      "color": Color(0xFF0091EA), // Xanh dương đậm
    },
    {
      "title": "Evening Chill",
      "tasks": "4 tasks",
      "icon": Icons.wb_twilight,
      "color": Color(0xFF8BC34A), // Xanh lá mạ
    },
    {
      "title": "Boost Productivity",
      "tasks": "1 task",
      "icon": Icons.trending_up,
      "color": Color(0xFF9C27B0), // Tím
    },
    {
      "title": "Get Energized",
      "tasks": "3 tasks",
      "icon": Icons.local_fire_department,
      "color": Color(0xFFF44336), // Đỏ
    },
    {
      "title": "Home Office",
      "tasks": "2 tasks",
      "icon": Icons.home,
      "color": Color(0xFF00BCD4), // Xanh Cyan
    },
    {
      "title": "Reading Corner",
      "tasks": "4 tasks",
      "icon": Icons.menu_book,
      "color": Color(0xFF795548), // Nâu
    },
    {
      "title": "Outdoor Party",
      "tasks": "3 tasks",
      "icon": Icons.celebration,
      "color": Color(0xFF607D8B), // Xám xanh
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView( // Dùng ListView bao ngoài để cuộn được cả trang
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // GridView hiển thị các ô màu
        GridView.builder(
          shrinkWrap: true, // Quan trọng: Để Grid nằm gọn trong ListView
          physics: const NeverScrollableScrollPhysics(), // Tắt cuộn riêng của Grid
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cột
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1, // Tỉ lệ chiều rộng/cao (gần vuông)
          ),
          itemCount: _tapItems.length,
          itemBuilder: (context, index) {
            final item = _tapItems[index];
            return _buildTapCard(item);
          },
        ),
        const SizedBox(height: 80), // Khoảng trống đáy cho nút FAB
      ],
    );
  }

  Widget _buildTapCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: item['color'],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (item['color'] as Color).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Xử lý khi nhấn (Chạy kịch bản)
            print("Running ${item['title']}...");
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hàng trên: Icon tròn + Mũi tên
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'], color: item['color'], size: 20),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
                
                // Hàng dưới: Tên + Số tác vụ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['tasks'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}