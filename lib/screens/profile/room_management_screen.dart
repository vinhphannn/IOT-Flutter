import 'package:flutter/material.dart';
import '../../services/room_service.dart';
import '../../models/room_model.dart'; // Import Model Room

class RoomManagementScreen extends StatefulWidget {
  final int houseId;
  const RoomManagementScreen({super.key, required this.houseId});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final RoomService _roomService = RoomService();
  
  List<Room> _rooms = []; // Dùng List<Room> chứa cả ID và Name
  bool _isLoading = true;
  bool _isEditing = false; // Trạng thái nhấn nút 4 ô vuông

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      // Gọi hàm mới trả về List<Room>
      final rooms = await _roomService.fetchRoomsByHouse(widget.houseId);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- POPUP XÁC NHẬN XÓA ---
  void _showDeleteConfirmDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Delete Room", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                "Are you sure you want to delete the Room \"${room.name}\"?", // Hiển thị tên phòng
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "All devices paired with this room will be unpaired.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF1F5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Đóng popup confirm
                          
                          // Gọi API xóa theo ID
                          bool success = await _roomService.deleteRoom(room.id);
                          
                          if (success) {
                            _showSuccessDialog(room.name);
                            _fetchRooms(); // Load lại danh sách sau khi xóa
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to delete room")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F5CF0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
      ),
    );
  }

  // --- POPUP THÔNG BÁO THÀNH CÔNG ---
  void _showSuccessDialog(String roomName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFF5F5CF0), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                "The Room \"$roomName\" has been successfully deleted!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- POPUP THÊM PHÒNG ---
  void _showAddRoomDialog() {
    final TextEditingController roomController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              const Text("Add New Room", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: roomController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Enter room name (e.g. Kitchen)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = roomController.text.trim();
                    if (name.isNotEmpty) {
                      bool success = await _roomService.addRoom(widget.houseId, name);
                      if (success && mounted) {
                        Navigator.pop(context);
                        _fetchRooms();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Room added!")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text("Add Room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditing ? "Manage Rooms" : "Room Management", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_isEditing) {
              setState(() => _isEditing = false); // Thoát chế độ sửa
            } else {
              Navigator.pop(context); // Quay lại trang trước
            }
          },
        ),
        actions: [
          IconButton(
            // Đổi icon khi nhấn vào
            icon: Icon(_isEditing ? Icons.check : Icons.grid_view, color: Colors.black),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          // Chế độ Edit: Hiện icon kéo thả bên trái
                          leading: _isEditing ? const Icon(Icons.drag_indicator, color: Colors.black54) : null,
                          
                          title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          
                          // Chế độ Edit: Hiện icon thùng rác bên phải
                          trailing: _isEditing
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _showDeleteConfirmDialog(room),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          
                          onTap: _isEditing ? null : () {
                            // Logic xem chi tiết phòng (nếu cần)
                          },
                        ),
                      );
                    },
                  ),
          ),
          
          // Chỉ hiện nút Add Room khi KHÔNG ở chế độ Edit
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: _showAddRoomDialog,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    backgroundColor: Colors.white,
                  ),
                  child: Text("Add Room", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}