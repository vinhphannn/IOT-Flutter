import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../providers/house_provider.dart'; // <--- Import Provider
import '../../widgets/house_selector_dropdown.dart'; // <--- Import Widget dùng chung
import 'home_management_screen.dart'; 
import 'join_home_scan_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserService _userService = UserService();

  String _fullName = "Loading...";
  String _email = "Loading...";
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _initData();
    // Đảm bảo danh sách nhà được tải khi vào Account (nếu chưa có)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final houseProvider = context.read<HouseProvider>();
      if (houseProvider.houses.isEmpty) {
        houseProvider.fetchHouses();
      }
    });
  }

  Future<void> _initData() async {
    await _loadFromPrefs(); // Load nhanh từ máy
    final updatedData = await _userService.fetchUserProfile(); // Load mới từ API
    
    if (updatedData != null && mounted) {
      setState(() {
        _fullName = updatedData['fullName'] ?? "Unknown User";
        _email = updatedData['email'] ?? "No Email";
        _avatarUrl = updatedData['avatarUrl'];
      });
    }
  }

  Future<void> _loadFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fullName = prefs.getString('fullName') ?? "Unknown User";
        _email = prefs.getString('email') ?? "No Email";
        _avatarUrl = prefs.getString('avatarUrl');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String firstLetter = "?";
    if (_email.isNotEmpty && _email != "Loading..." && _email != "No Email") {
      firstLetter = _email[0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // 👇 HEADER SỬ DỤNG WIDGET DÙNG CHUNG
        title: const HouseSelectorDropdown(),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JoinHomeScanScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PROFILE CARD
              Row(
                children: [
                  // --- AVATAR THÔNG MINH ---
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: (_avatarUrl != null && _avatarUrl!.isNotEmpty) 
                          ? Colors.transparent 
                          : Colors.blue.shade100, 
                      shape: BoxShape.circle,
                      image: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(_avatarUrl!), 
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                        ? Center(child: Text(firstLetter, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade700)))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // --- THÔNG TIN TEXT ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (_fullName.isEmpty || _fullName == "null") ? "Unknown User" : _fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
              
              _buildMenuItem(Icons.home_work_outlined, "Home Management", onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeManagementScreen()));
              }),
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
              
              // 3. LOGOUT
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
                    if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signIn, (route) => false);
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
      ),
    );
  }

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