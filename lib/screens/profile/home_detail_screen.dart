import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/house_model.dart';
import '../../models/house_member_model.dart';
import '../../services/house_service.dart';
import '../../services/room_service.dart';
import 'room_management_screen.dart';
import 'add_member_screen.dart';
import 'member_detail_screen.dart';

class HomeDetailScreen extends StatefulWidget {
  final House house;
  const HomeDetailScreen({super.key, required this.house});

  @override
  State<HomeDetailScreen> createState() => _HomeDetailScreenState();
}

class _HomeDetailScreenState extends State<HomeDetailScreen> {
  final HouseService _houseService = HouseService();
  final RoomService _roomService = RoomService();

  late String _currentHouseName;
  List<HouseMember> _members = [];
  int _roomCount = 0;
  int _deviceCount = 0;
  bool _isLoading = true;
  String? _myRole; // Role của người dùng hiện tại

  @override
  void initState() {
    super.initState();
    _currentHouseName = widget.house.name;
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      final houseId = widget.house.id;
      // Lấy role của tôi trước để phân quyền nút bấm
      final role = await _houseService.fetchMyRoleInHouse(houseId);
      final members = await _houseService.fetchHouseMembers(houseId);
      final roomNames = await _roomService.fetchRoomsByHouse(houseId);
      final devices = await _houseService.fetchDevicesByHouseId(houseId);

      if (mounted) {
        setState(() {
          _myRole = role;
          _members = members;
          _roomCount = roomNames.length;
          _deviceCount = devices.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HÀM SỬA TÊN NHÀ (ĐÃ FIX LỖI) ---
  void _showRenameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _currentHouseName,
    );
    _showBottomDialog(
      context: context,
      title: "Home Name",
      controller: nameController,
      onSave: () async {
        final newName = nameController.text.trim();
        if (newName.isNotEmpty) {
          // Gọi API cập nhật tên nhà
          bool success = await _houseService.updateHouseName(
            widget.house.id,
            newName,
          );
          if (success) {
            setState(() => _currentHouseName = newName);
            if (context.mounted) Navigator.pop(context);
          }
        }
      },
    );
  }

  // --- POPUP THÔNG BÁO THÀNH CÔNG ---
  void _showSuccessDeletePopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFF4B6EF6), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              "\"$_currentHouseName\" has been successfully deleted!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
    // Tự động đóng sau 2s và quay về màn hình trước
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Đóng popup
        Navigator.pop(context, true); // Thoát trang Detail
      }
    });
  }

  // --- POPUP XÁC NHẬN XÓA ---
  void _onDeleteHouse() async {
    if (_myRole?.toUpperCase() != 'OWNER') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only Owner can delete this home!")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Delete Home", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text("Are you sure you want to delete this home?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "After the home is deleted, all members will be removed, and all devices will be unpaired.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF1F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // Đóng xác nhận
                        bool success = await _houseService.deleteHouse(widget.house.id);
                        if (success) _showSuccessDeletePopup();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B6EF6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Yes, Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- HÀM CHUNG HIỂN THỊ DIALOG ĐỔI TÊN ---
  void _showBottomDialog({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
    String hintText = "",
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hintText,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEFF1F5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text("Cancel", style: TextStyle(color: Colors.black))))),
                  const SizedBox(width: 16),
                  Expanded(child: SizedBox(height: 50, child: ElevatedButton(onPressed: onSave, style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = _myRole?.toUpperCase() == 'OWNER';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("My Home", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildRowItem("Home Name", _currentHouseName, onTap: isOwner ? _showRenameDialog : null),
                        _buildDivider(),
                        _buildRowItem("Room Management", "$_roomCount Room(s)", onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => RoomManagementScreen(houseId: widget.house.id)));
                          _fetchAllData();
                        }),
                        _buildDivider(),
                        _buildRowItem("Device Management", "$_deviceCount Device(s)"),
                        _buildDivider(),
                        _buildRowItem("Location", "701 7th Ave..."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Home Members (${_members.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (isOwner || _myRole?.toUpperCase() == 'ADMIN')
                              Container(
                                width: 32, height: 32,
                                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.add, color: Colors.white, size: 20), onPressed: () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddMemberScreen(houseId: widget.house.id)));
                                  if (result == true) _fetchAllData();
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _members.length,
                          separatorBuilder: (ctx, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            return InkWell(
                              onTap: () async {
                                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => MemberDetailScreen(houseId: widget.house.id, member: member)));
                                if (result == true) _fetchAllData();
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 24, backgroundImage: (member.avatarUrl != null) ? NetworkImage(member.avatarUrl!) : null, backgroundColor: Colors.grey[200], child: (member.avatarUrl == null) ? const Icon(Icons.person, color: Colors.grey) : null),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(member.email, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
                                  Text(member.displayRole, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: isOwner ? _onDeleteHouse : () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You don't have permission to delete this home!")));
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isOwner ? Colors.red : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        backgroundColor: isOwner ? Colors.white : Colors.grey.shade50,
                      ),
                      child: Text("Delete Home", style: TextStyle(color: isOwner ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRowItem(String title, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            Row(children: [Text(value, style: const TextStyle(color: Colors.grey, fontSize: 14)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, color: Color(0xFFEEEEEE));
}