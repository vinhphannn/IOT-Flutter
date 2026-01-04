import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../models/device_model.dart';
import 'select_function_screen.dart'; // Import trang chọn chức năng

class ControlSingleDeviceScreen extends StatefulWidget {
  const ControlSingleDeviceScreen({super.key});

  @override
  State<ControlSingleDeviceScreen> createState() => _ControlSingleDeviceScreenState();
}

class _ControlSingleDeviceScreenState extends State<ControlSingleDeviceScreen> {
  int _selectedRoomIndex = 0;
  String _selectedCategory = "All"; // Mặc định hiện tất cả loại

  // 1. CẤU HÌNH DANH MỤC
  final List<Map<String, dynamic>> _categories = [
    {'title': 'All', 'types': [], 'icon': Icons.grid_view, 'color': Colors.grey},
    {'title': 'Lighting', 'types': ['RELAY', 'LIGHT'], 'icon': Icons.lightbulb_outline, 'color': Colors.amber},
    {'title': 'Cameras', 'types': ['CAMERA'], 'icon': Icons.videocam_outlined, 'color': Colors.purple},
    {'title': 'Electrical', 'types': ['SOCKET', 'PLUG'], 'icon': Icons.power, 'color': Colors.orange},
    {'title': 'Comfort', 'types': ['AC', 'FAN', 'HEATER'], 'icon': Icons.thermostat, 'color': Colors.blue},
    {'title': 'Security', 'types': ['LOCK', 'DOORBELL'], 'icon': Icons.security, 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    // Sửa lỗi Unused variable: Sử dụng primaryColor thay cho mã màu cứng
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Control Device", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          final allDevices = deviceProvider.devices;
          
          // --- LOGIC LẤY DANH SÁCH PHÒNG ---
          Set<String> roomSet = allDevices.map((d) => d.roomName).toSet();
          // Sửa lỗi Unnecessary toList: Bỏ .toList() trong spread operator
          List<String> rooms = ["All Rooms", ...roomSet];

          // --- LOGIC LỌC THIẾT BỊ ---
          List<Device> filteredDevices = allDevices.where((device) {
            // 1. Lọc theo Phòng
            bool matchRoom = _selectedRoomIndex == 0 || device.roomName == rooms[_selectedRoomIndex];
            
            // 2. Lọc theo Loại (Category)
            bool matchCategory = true;
            if (_selectedCategory != "All") {
              final categoryConfig = _categories.firstWhere((c) => c['title'] == _selectedCategory);
              List<String> types = categoryConfig['types'];
              matchCategory = types.contains(device.type.toUpperCase());
            }

            return matchRoom && matchCategory;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CATEGORY FILTERS
              SizedBox(
                height: 110,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  // Sửa lỗi Unnecessary underscores: Dùng (context, index) thay vì (_, __)
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['title'];
                    
                    int count = 0;
                    if (cat['title'] == 'All') {
                      count = allDevices.length;
                    } else {
                      List<String> types = cat['types'];
                      count = allDevices.where((d) => types.contains(d.type.toUpperCase())).length;
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['title']),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // Sửa lỗi Deprecated member: Dùng .withValues(alpha: 0.2) nếu Flutter mới, 
                          // nhưng để an toàn chồng giữ withOpacity và ignore warning hoặc dùng cách này:
                          color: isSelected ? (cat['color'] as Color).withOpacity(0.2) : const Color(0xFFF8F9FD),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: cat['color'], width: 1.5) : null,
                        ),
                        // 👇 Dùng Column với MainAxisSize.min và Flexible để tránh lỗi
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Icon(cat['icon'], color: cat['color'], size: 28),
                            const SizedBox(height: 8),
                            
                            // Tên Category (Tự co nhỏ nếu dài quá)
                            Flexible(
                              child: Text(
                                cat['title'], 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis
                              ),
                            ),
                            
                            // Số lượng (Tự co nhỏ)
                            Flexible(
                              child: Text(
                                "$count devices", 
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. ROOM FILTERS
              SizedBox(
                height: 50,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: rooms.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedRoomIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRoomIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          // Sử dụng primaryColor ở đây
                          color: isSelected ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          rooms[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // 3. DEVICE LIST
              Expanded(
                child: filteredDevices.isEmpty 
                  ? Center(child: Text("No devices found", style: TextStyle(color: Colors.grey[500])))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredDevices.length,
                      separatorBuilder: (context, index) => const Divider(height: 24, indent: 60),
                      itemBuilder: (context, index) {
                        final device = filteredDevices[index];
                        return InkWell(
                          onTap: () async {
                            // SỬA: Mở trang SelectFunctionScreen trước
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectFunctionScreen(device: device),
                              ),
                            );

                            // Nếu người dùng chọn OK (có kết quả) -> Trả về trang Create Scene
                            if (result != null && context.mounted) {
                              Navigator.pop(context, {
                                "device": device,
                                "actionData": result, // Map { "cmd": "ON" }
                              });
                            }
                          },
                          child: Row(
                            children: [
                              // SỬA LỖI QUAN TRỌNG: Bỏ imageUrl vì Model không có field này
                              // Chỉ hiển thị Icon
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(getDeviceIcon(device.type), color: Colors.grey),
                              ),
                              const SizedBox(width: 16),
                              
                              // Tên thiết bị + Phòng (Dùng Expanded)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      device.roomName,
                                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                  ],
                                ),
                              ),
                              
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper chọn icon
  IconData getDeviceIcon(String type) {
    switch (type.toUpperCase()) {
      case 'LIGHT': case 'RELAY': return Icons.lightbulb;
      case 'AC': return Icons.ac_unit;
      case 'FAN': return Icons.wind_power;
      case 'TV': return Icons.tv;
      case 'LOCK': return Icons.lock;
      case 'CAMERA': return Icons.videocam;
      case 'SOCKET': case 'PLUG': return Icons.power;
      default: return Icons.devices_other;
    }
  }
}