import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import 'home_management_screen.dart'; // Import trang mới

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Biến lưu thông tin user
  String _fullName = "Loading...";
  String _email = "Loading...";
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Hàm lấy thông tin từ bộ nhớ máy (đã lưu lúc Login)
  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName') ?? "Unknown User";
      _email = prefs.getString('email') ?? "No Email";
      _avatarUrl = prefs.getString('avatarUrl'); // Nếu null thì hiện icon mặc định
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Text("My Home", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
            SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PROFILE CARD (DỮ LIỆU THẬT)
            Row(
              children: [
                // Avatar
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    image: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 30),

            // 2. GENERAL SECTIONS
            const Text("General", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 10),
            
            // --- NÚT HOME MANAGEMENT ---
            _buildMenuItem(
              Icons.home_work_outlined, 
              "Home Management", 
              onTap: () {
                // Chuyển sang trang Quản lý nhà
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const HomeManagementScreen())
                );
              }
            ),
            
            _buildMenuItem(Icons.mic_none, "Voice Assistants"),
            _buildMenuItem(Icons.notifications_none, "Notifications"),
            _buildMenuItem(Icons.verified_user_outlined, "Account & Security"),
            _buildMenuItem(Icons.swap_vert, "Linked Accounts"),
            _buildMenuItem(Icons.remove_red_eye_outlined, "App Appearance"),
            _buildMenuItem(Icons.settings_outlined, "Additional Settings"),

            const SizedBox(height: 20),
            const Text("Support", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 10),
            _buildMenuItem(Icons.insights, "Data & Analytics"),
            _buildMenuItem(Icons.help_outline, "Help & Support"),

            const SizedBox(height: 20),
            
            // 3. LOGOUT (Giữ nguyên logic cũ của vợ)
            InkWell(
              onTap: () async {
                bool confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Logout", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ) ?? false;

                if (confirm) {
                  AuthService authService = AuthService();
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signIn, (route) => false);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 16),
                    Text("Logout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
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

  // Widget item nhỏ (Thêm onTap)
  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}