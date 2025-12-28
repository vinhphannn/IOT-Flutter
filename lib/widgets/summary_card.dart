import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. QUAN TRỌNG: Không dùng Expanded ở đây nữa
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material( // Thêm Material để có hiệu ứng gợn sóng khi bấm
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12), // Giảm padding chút cho đỡ chật
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(height: 12),
                
                // Tiêu đề (Lighting,...)
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1, // Chỉ cho hiện 1 dòng
                  overflow: TextOverflow.ellipsis, // Dài quá thì ...
                ),
                
                const SizedBox(height: 4),
                
                // Phụ đề (3 lights)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1, // Chỉ cho hiện 1 dòng
                  overflow: TextOverflow.ellipsis, // Dài quá thì ...
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}