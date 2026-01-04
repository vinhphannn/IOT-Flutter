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
  bool _isLoadingRole = true;
  String? _myRole; 
  late String _currentDisplayRole; // Role đang hiển thị trên màn hình

  @override
  void initState() {
    super.initState();
    _currentDisplayRole = widget.member.displayRole; // Khởi tạo bằng role ban đầu
    _loadMyRole();
  }

  Future<void> _loadMyRole() async {
    final role = await _houseService.fetchMyRoleInHouse(widget.houseId);
    if (mounted) {
      setState(() {
        _myRole = role;
        _isLoadingRole = false;
      });
    }
  }

  // --- KIỂM TRA QUYỀN CHUNG ---
  bool _canEditOrRemove() {
    if (_isLoadingRole || _myRole == null) return false;
    
    final myRole = _myRole!.toUpperCase();
    final targetRole = widget.member.displayRole.toUpperCase();

    // Owner có toàn quyền (trừ chính mình ở trang này)
    if (myRole == 'OWNER') return true;
    
    // Admin chỉ được sửa Member
    if (myRole == 'ADMIN' && targetRole == 'MEMBER') return true;
    
    return false;
  }

  // --- POPUP THAY ĐỔI ROLE ---
  void _showChangeRoleDialog() {
    if (!_canEditOrRemove()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn không có quyền thay đổi vai trò người này!")),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Change Role", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildRoleOption("Admin", "Manage devices, rooms & members"),
            const Divider(),
            _buildRoleOption("Member", "Use devices & scenes only"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(String roleName, String description) {
    bool isSelected = _currentDisplayRole.toUpperCase() == roleName.toUpperCase();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(roleName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description, style: const TextStyle(color: Colors.grey)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () async {
        Navigator.pop(context); // Đóng popup trước
        if (isSelected) return; // Nếu chọn lại role cũ thì thôi

        // Gọi API cập nhật
        bool success = await _houseService.updateMemberRole(
          widget.houseId, 
          widget.member.userId, 
          roleName.toUpperCase()
        );

        if (mounted) {
          if (success) {
            setState(() => _currentDisplayRole = roleName); // Cập nhật UI ngay
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Role updated successfully!")));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update role.")));
          }
        }
      },
    );
  }

  void _onRemoveMember() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Member"),
        content: Text("Remove ${widget.member.fullName} from this house?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isRemoving = true);
      bool success = await _houseService.removeMember(widget.houseId, widget.member.userId);
      if (mounted) {
        setState(() => _isRemoving = false);
        if (success) {
          Navigator.pop(context, true); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to remove member.")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPermission = _canEditOrRemove();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Home Member", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoadingRole 
          ? const Center(child: CircularProgressIndicator()) 
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
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
                  
                  // --- DÒNG ROLE CÓ THỂ BẤM ĐƯỢC ---
                  InkWell(
                    onTap: hasPermission ? _showChangeRoleDialog : null, // Chỉ cho bấm nếu có quyền
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Role", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          Row(
                            children: [
                              // Hiển thị Role đang có (Admin/Member)
                              Text(_currentDisplayRole, 
                                style: TextStyle(
                                  color: hasPermission ? Colors.blue : Colors.grey, // Xanh nếu sửa được
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              const SizedBox(width: 8),
                              if (hasPermission) // Chỉ hiện mũi tên nếu sửa được
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),

            // NÚT REMOVE MEMBER
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: hasPermission ? (_isRemoving ? null : _onRemoveMember) : () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn không có quyền gỡ thành viên này!")));
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: hasPermission ? Colors.red : Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: hasPermission ? Colors.white : Colors.grey.shade50,
                ),
                child: _isRemoving 
                  ? const CircularProgressIndicator(color: Colors.red)
                  : Text("Remove Member", style: TextStyle(color: hasPermission ? Colors.red : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}