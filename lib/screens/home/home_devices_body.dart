import 'package:flutter/material.dart';
import '../../models/device_model.dart';
import '../../widgets/device_card.dart';
import '../../widgets/summary_card.dart';
import '../../routes.dart';

class HomeDevicesBody extends StatelessWidget {
  final List<Device> allDevices;
  final List<Device> displayDevices;
  final List<String> rooms;
  final int selectedRoomIndex;
  final Function(int) onRoomChanged;
  final Function(String, String) onCategoryTap;

  const HomeDevicesBody({
    super.key,
    required this.allDevices,
    required this.displayDevices,
    required this.rooms,
    required this.selectedRoomIndex,
    required this.onRoomChanged,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // --- 1. CẤU HÌNH DANH SÁCH ---
    final List<Map<String, dynamic>> summaryCategories = [
      {'title': 'Lighting', 'types': ['RELAY', 'LIGHT'], 'icon': Icons.lightbulb_outline, 'color': Colors.amber},
      {'title': 'Sockets', 'types': ['SOCKET', 'PLUG'], 'icon': Icons.power, 'color': Colors.purple},
      {'title': 'Sensors', 'types': ['SENSOR'], 'icon': Icons.sensors, 'color': Colors.orange},
      {'title': 'Comfort', 'types': ['AC', 'FAN', 'HEATER', 'THERMOSTAT'], 'icon': Icons.thermostat, 'color': Colors.blue},
      {'title': 'Security', 'types': ['CAMERA', 'LOCK', 'DOORBELL'], 'icon': Icons.security, 'color': Colors.red},
      {'title': 'Media', 'types': ['TV', 'SPEAKER'], 'icon': Icons.tv, 'color': Colors.teal},
      {'title': 'Kitchen', 'types': ['FRIDGE', 'OVEN', 'KETTLE'], 'icon': Icons.kitchen, 'color': Colors.brown},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 2. SUMMARY CARDS ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: summaryCategories.map((category) {
              List<String> types = category['types'] as List<String>;
              int count = allDevices.where((d) => types.contains(d.type.toUpperCase())).length;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 110,
                  height: 110,
                  constraints: const BoxConstraints(minHeight: 100, minWidth: 100), 
                  child: SummaryCard(
                    icon: category['icon'],
                    title: category['title'],
                    subtitle: "$count", 
                    bgColor: (category['color'] as Color).withOpacity(0.1),
                    iconColor: (category['color'] as Color),
                    onTap: () {
                      onCategoryTap(types[0], category['title']);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // --- HEADER DANH SÁCH ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("All Devices", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.addDevice),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.add, color: primaryColor, size: 20),
                    const SizedBox(width: 4),
                    Text("Add", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- BỘ LỌC PHÒNG ---
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = selectedRoomIndex == index;
              int count = index == 0
                  ? allDevices.length
                  : allDevices.where((d) => d.roomName == rooms[index]).length;

              return GestureDetector(
                onTap: () => onRoomChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                  ),
                  child: Text(
                    "${rooms[index]} ($count)",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // --- GRID THIẾT BỊ ---
        displayDevices.isEmpty
            ? _buildEmptyState(primaryColor, context)
            : GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                
                // --- CHỒNG BỔ SUNG ĐOẠN THIẾU Ở ĐÂY NÈ ---
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,      // 2 Cột
                  crossAxisSpacing: 16,   // Khoảng cách ngang
                  mainAxisSpacing: 16,    // Khoảng cách dọc
                  childAspectRatio: 0.85, // Tỷ lệ khung hình
                ),
                // ------------------------------------------

                itemCount: displayDevices.length,
                itemBuilder: (context, index) {
                  final device = displayDevices[index];
                  final isOnline = device.isOnline; 

                  return Stack(
                    children: [
                      // 1. Thẻ thiết bị (Gỡ bỏ khóa AbsorbPointer ở đây, chỉ giữ Opacity)
                      Opacity(
                        opacity: isOnline ? 1.0 : 0.5,
                        child: DeviceCard(
                          device: device,
                          showRoomInfo: selectedRoomIndex == 0,
                        ),
                      ),

                      // 2. Icon Offline nằm đè lên trên (Nhưng cho phép bấm xuyên qua nhờ IgnorePointer)
                      if (!isOnline)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7), 
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                                ),
                                child: Icon(
                                  Icons.cloud_off_rounded,
                                  size: 32, 
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
        
        const SizedBox(height: 80),
      ],
    );
  }

  // Widget Empty State
  Widget _buildEmptyState(Color primaryColor, BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: 80, height: 100,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                ),
              ),
              Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: 90, height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]
                  ),
                  child: const Center(child: Icon(Icons.paste_rounded, size: 40, color: Colors.blueAccent)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("No Devices Found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("No devices in this room.", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            width: 180, height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addDevice),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Device", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.4),
              ),
            ),
          )
        ],
      ),
    );
  }
}