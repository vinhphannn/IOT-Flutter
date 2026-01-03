import 'package:flutter/material.dart';
import '../../models/house_member_model.dart';
import '../../services/house_service.dart';

class MemberDetailScreen extends StatefulWidget {
  final int houseId;
  final HouseMember member;

  const MemberDetailScreen({super.key, required this.houseId, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final HouseService _houseService = HouseService();
  
  bool _isRemoving = false;
  bool _isLoadingRole = true; // Đang tải quyền hạn
  String? _myRole; // Role của người đang dùng App

  @override
  void initState() {
    super.initState();
    _loadMyRole();
  }

  // --- 1. GỌI API LẤY QUYỀN CỦA TÔI ---
  Future<void> _loadMyRole() async {
    final role = await _houseService.fetchMyRoleInHouse(widget.houseId);
    if (mounted) {
      setState(() {
        _myRole = role;
        _isLoadingRole = false;
      });
    }
  }

  // --- 2. KIỂM TRA QUYỀN XÓA ---
  bool _canRemoveMember() {
    if (_isLoadingRole || _myRole == null) return false;

    // Quyền của tôi (Người đang dùng App)
    final myRole = _myRole!.toUpperCase();
    // Quyền của người được xem (Người định bị xóa)
    final targetRole = widget.member.displayRole.toUpperCase();

    // Logic phân quyền:
    // - OWNER được xóa tất cả (trừ chính mình, nhưng logic xóa chính mình thường ở trang khác)
    // - ADMIN được xóa MEMBER
    // - MEMBER không được xóa ai cả
    if (myRole == 'OWNER') return true;
    if (myRole == 'ADMIN' && targetRole == 'MEMBER') return true;
    
    return false;
  }

  void _onRemoveMember() async {
    // Xác nhận lại lần nữa
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Are you sure you want to remove ${widget.member.fullName} from this house?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isRemoving = true);
      bool success = await _houseService.removeMember(widget.houseId, widget.member.userId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member removed successfully")));
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to remove member. Only Admin/Owner can do this.")));
        }
        setState(() => _isRemoving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra quyền ngay lúc build UI
    final bool hasPermission = _canRemoveMember();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Home Member", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: _isLoadingRole 
          ? const Center(child: CircularProgressIndicator()) // Đang kiểm tra quyền thì hiện xoay xoay
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Thông tin cá nhân (Giữ nguyên UI đẹp của vợ)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (widget.member.avatarUrl != null) ? NetworkImage(widget.member.avatarUrl!) : null,
                    backgroundColor: Colors.grey[200],
                    child: (widget.member.avatarUrl == null) ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(widget.member.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.member.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Role", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Text(widget.member.displayRole, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- NÚT REMOVE MEMBER CÓ VALIDATION THEO API ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                // Nếu có quyền thì cho bấm, không thì hiện thông báo
                onPressed: hasPermission 
                  ? (_isRemoving ? null : _onRemoveMember) 
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Bạn không có quyền gỡ thành viên này!"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                style: OutlinedButton.styleFrom(
                  // Nút mờ đi nếu không có quyền
                  side: BorderSide(color: hasPermission ? Colors.red : Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: hasPermission ? Colors.white : Colors.grey.shade50,
                ),
                child: _isRemoving 
                  ? const CircularProgressIndicator(color: Colors.red)
                  : Text(
                      "Remove Member", 
                      style: TextStyle(
                        color: hasPermission ? Colors.red : Colors.grey, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      )
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }
}