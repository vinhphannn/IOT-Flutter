import 'package:flutter/material.dart';
import '../../models/house_model.dart';
import '../../services/house_service.dart';
import 'home_detail_screen.dart';

class HomeManagementScreen extends StatefulWidget {
  const HomeManagementScreen({super.key});

  @override
  State<HomeManagementScreen> createState() => _HomeManagementScreenState();
}

class _HomeManagementScreenState extends State<HomeManagementScreen> {
  List<House> _houses = [];
  bool _isLoading = true;
  final HouseService _houseService = HouseService();

  @override
  void initState() {
    super.initState();
    _fetchHouses();
  }

  // Gọi API lấy danh sách nhà
  Future<void> _fetchHouses() async {
    try {
      final houses = await _houseService.fetchMyHouses();
      if (mounted) {
        setState(() {
          _houses = houses;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching houses: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white, // Màu nền trắng xám nhẹ
      appBar: AppBar(
        title: const Text(
          "Home Management",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // 1. DANH SÁCH NHÀ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _houses.length,
                    itemBuilder: (context, index) {
                      final house = _houses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          // box shadow nhẹ cho giống thiết kế
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Text(
                            house.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),

                          // Trong HomeManagementScreen.dart
                          onTap: () async {
                            // Chuyển sang màn hình chi tiết & đợi kết quả (để reload nếu xóa nhà)
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeDetailScreen(
                                  house: house,
                                ), // Truyền object house sang
                              ),
                            );

                            // Nếu quay lại mà có signal true (đã xóa nhà) -> Load lại danh sách
                            if (result == true) {
                              _fetchHouses();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),

          // 2. HAI NÚT Ở DƯỚI
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Nút Create a Home (Màu xanh)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigator.pushNamed(context, '/create-home'); // TODO: Tạo trang Create Home
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "Create a Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nút Join a Home (Viền xanh, nền trắng)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigator.pushNamed(context, '/join-home'); // TODO: Tạo trang Join Home
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      "Join a Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Khoảng cách đáy an toàn
              ],
            ),
          ),
        ],
      ),
    );
  }
}
