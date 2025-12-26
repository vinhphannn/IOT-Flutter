import 'package:flutter/material.dart';

class GeneralTab extends StatelessWidget {
  const GeneralTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Section: Today
        const Text("Today", style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 16),
        
        _buildNotificationItem(
          context,
          icon: Icons.verified_user_outlined,
          title: "Account Security Alert 🔒",
          description: "We've noticed some unusual activity on your account. Please review your recent logins.",
          time: "09:41 AM",
          isUnread: true,
        ),
        const SizedBox(height: 16),
        
        _buildNotificationItem(
          context,
          icon: Icons.info_outline,
          title: "System Update Available 🔄",
          description: "A new system update is ready for installation. It includes performance improvements.",
          time: "08:46 AM",
          isUnread: true,
        ),

        const SizedBox(height: 24),

        // Section: Yesterday
        const Text("Yesterday", style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 16),

        _buildNotificationItem(
          context,
          icon: Icons.lock_outline,
          title: "Password Reset Successful ✅",
          description: "Your password has been successfully reset. If you didn't request this change, please contact support.",
          time: "20:30 PM",
          isUnread: false, // Đã đọc
        ),
        const SizedBox(height: 16),

        _buildNotificationItem(
          context,
          icon: Icons.star_outline,
          title: "Exciting New Feature 🆕",
          description: "We've just launched a new feature that will enhance your user experience. Check it out now!",
          time: "16:29 PM",
          isUnread: false,
        ),
      ],
    );
  }

  // Widget Item thông báo (Tách ra để tái sử dụng)
  Widget _buildNotificationItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Icon tròn bên trái
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
            color: Colors.white,
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(width: 16),

        // 2. Nội dung ở giữa
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Chấm xanh nếu chưa đọc
                  if (isUnread)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4B6EF6), // Xanh chủ đạo
                        shape: BoxShape.circle,
                      ),
                    ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}