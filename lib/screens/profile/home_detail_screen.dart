import 'package:flutter/material.dart';
import '../../models/house_model.dart';
import '../../models/house_member_model.dart';
import '../../services/house_service.dart';
import '../../services/room_service.dart';
import 'room_management_screen.dart'; // Nhớ import file mới

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

  @override
  void initState() {
    super.initState();
    _currentHouseName = widget.house.name;
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      final houseId = widget.house.id;
      final members = await _houseService.fetchHouseMembers(houseId);
      final roomNames = await _roomService.fetchRoomsByHouse(houseId);
      final devices = await _houseService.fetchDevicesByHouseId(houseId);

      if (mounted) {
        setState(() {
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

  // --- 1. POPUP ĐỔI TÊN NHÀ ---
  void _showRenameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _currentHouseName,
    );
    _showBottomDialog(
      context: context,
      title: "Rename Home",
      controller: nameController,
      onSave: () async {
        final newName = nameController.text.trim();
        if (newName.isNotEmpty) {
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

  // --- 2. POPUP THÊM PHÒNG (MỚI) ---
  void _showAddRoomDialog() {
    final TextEditingController roomController = TextEditingController();
    _showBottomDialog(
      context: context,
      title: "Add New Room",
      controller: roomController,
      hintText: "Enter room name (e.g. Kitchen)",
      onSave: () async {
        final roomName = roomController.text.trim();
        if (roomName.isNotEmpty) {
          // Gọi API thêm phòng
          bool success = await _roomService.addRoom(widget.house.id, roomName);
          if (success) {
            if (context.mounted) {
              Navigator.pop(context); // Đóng popup
              _fetchAllData(); // Load lại dữ liệu để cập nhật số lượng phòng
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Room added successfully!")),
              );
            }
          }
        }
      },
    );
  }

  // --- HÀM CHUNG HIỂN THỊ DIALOG (Để tái sử dụng cho gọn code) ---
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
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: hintText,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF1F5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onDeleteHouse() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Home"),
            content: const Text("Are you sure? This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      bool success = await _houseService.deleteHouse(widget.house.id);
      if (success && mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "My Home",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- SECTION 1 ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildRowItem(
                          "Home Name",
                          _currentHouseName,
                          onTap: _showRenameDialog,
                        ),
                        _buildDivider(),

                        // 👇 Sửa chỗ này: Bấm vào Room Management thì hiện Popup thêm phòng
                        _buildRowItem(
                          "Room Management",
                          "$_roomCount Room(s)",
                          onTap: () async {
                            // Chuyển trang và đợi kết quả trả về (để update số lượng phòng)
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoomManagementScreen(
                                  houseId: widget.house.id,
                                ),
                              ),
                            );
                            // Quay lại thì load lại data để cập nhật số đếm
                            _fetchAllData();
                          },
                        ),
                        _buildDivider(),
                        _buildRowItem(
                          "Device Management",
                          "$_deviceCount Device(s)",
                        ),
                        _buildDivider(),
                        _buildRowItem("Location", "701 7th Ave..."),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 2 ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Home Members (${_members.length})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _members.length,
                          separatorBuilder: (ctx, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: (member.avatarUrl != null)
                                      ? NetworkImage(member.avatarUrl!)
                                      : null,
                                  backgroundColor: Colors.grey[200],
                                  child: (member.avatarUrl == null)
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        member.email,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  member.displayRole,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- NÚT DELETE ---
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _onDeleteHouse,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        "Delete Home",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFEEEEEE));
  }
}
