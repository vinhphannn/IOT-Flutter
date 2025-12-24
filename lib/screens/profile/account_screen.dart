import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Text(
              "My Home",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PROFILE CARD
            Row(
              children: [
                // --- SỬA ĐOẠN NÀY NÈ VỢ ƠI ---
                // Thay vì dùng backgroundImage (ảnh), mình dùng child (icon)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // Màu nền xám
                    shape: BoxShape.circle, // Hình tròn
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.grey,
                  ), // Icon người
                ),

                // -----------------------------
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Andrew Ainsley",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "andrew.ainsley@yourdomain.com",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 2. SECTION GENERAL
            const Text(
              "General",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            _buildMenuItem(Icons.home_work_outlined, "Home Management"),
            _buildMenuItem(Icons.mic_none, "Voice Assistants"),
            _buildMenuItem(Icons.notifications_none, "Notifications"),
            _buildMenuItem(Icons.verified_user_outlined, "Account & Security"),
            _buildMenuItem(Icons.swap_vert, "Linked Accounts"),
            _buildMenuItem(Icons.remove_red_eye_outlined, "App Appearance"),
            _buildMenuItem(Icons.settings_outlined, "Additional Settings"),

            const SizedBox(height: 20),

            // 3. SECTION SUPPORT
            const Text(
              "Support",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            _buildMenuItem(Icons.insights, "Data & Analytics"),
            _buildMenuItem(Icons.help_outline, "Help & Support"),

            const SizedBox(height: 20),

            // 4. LOGOUT
            // ... (Phần trên giữ nguyên)

            // 4. LOGOUT
            InkWell(
              onTap: () async {
                // --- BẮT ĐẦU NÃO BỘ MỚI ---

                // 1. Hiện dialog xác nhận cho chuyên nghiệp
                bool confirm =
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false), // Hủy
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true), // Đồng ý
                            child: const Text(
                              "Yes, Logout",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ) ??
                    false; // Nếu bấm ra ngoài thì coi như false

                if (confirm) {
                  // 2. Gọi Service để xóa Token
                  // (Nhớ import AuthService ở đầu file)
                  AuthService authService = AuthService();
                  await authService.logout();

                  // 3. Đá về màn hình Login (SignIn)
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.signIn,
                      (route) => false, // Xóa hết lịch sử cũ
                    );
                  }
                }
                // ---------------------------
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 16),
                    Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget item nhỏ
  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () {},
    );
  }
}
