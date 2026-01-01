import 'package:flutter/material.dart';

class SmartTaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<IconData> icons;
  final bool initialValue;
  final Color iconColor;
  final VoidCallback onTap;
  final Function(bool) onToggle;

  const SmartTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icons,
    required this.initialValue,
    this.iconColor = Colors.green, // Mặc định màu xanh lá
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Đổ bóng nhẹ cho đẹp như thiết kế
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Title + Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),

            // 2. Subtitle
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // 3. Icons + Switch
            Row(
              children: [
                // List Icons
                ...icons.map((icon) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(icon, size: 20, color: iconColor),
                    )),
                // Mũi tên chỉ dẫn (nếu có nhiều icon)
                if (icons.length > 1)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  ),
                
                const Spacer(),

                // Toggle Switch
                Switch(
                  value: initialValue,
                  activeColor: Colors.white,
                  activeTrackColor: Theme.of(context).primaryColor,
                  onChanged: onToggle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}