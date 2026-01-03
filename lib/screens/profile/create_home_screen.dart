import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Bản đồ
import 'package:latlong2/latlong.dart';      // Tọa độ
import 'package:http/http.dart' as http;
import '../../services/house_service.dart';

class CreateHomeScreen extends StatefulWidget {
  const CreateHomeScreen({super.key});

  @override
  State<CreateHomeScreen> createState() => _CreateHomeScreenState();
}

class _CreateHomeScreenState extends State<CreateHomeScreen> {
  final TextEditingController _nameController = TextEditingController(text: "My Rental House");
  final TextEditingController _addressController = TextEditingController(text: "Set Location...");
  final HouseService _houseService = HouseService();
  
  final List<Map<String, dynamic>> _suggestedRooms = [
    {"name": "Living Room", "selected": false},
    {"name": "Bedroom", "selected": false},
    {"name": "Bathroom", "selected": false},
    {"name": "Kitchen", "selected": false},
    {"name": "Study Room", "selected": false},
    {"name": "Dining Room", "selected": false},
  ];

  bool _isSaving = false;

  // --- HÀM MỞ POPUP BẢN ĐỒ ---
  void _showMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapPickerWidget(
        onLocationSelected: (address) {
          setState(() => _addressController.text = address);
        },
      ),
    );
  }

  void _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter home name")));
      return;
    }

    List<String> selectedRoomNames = _suggestedRooms
        .where((r) => r["selected"] == true)
        .map((r) => r["name"] as String)
        .toList();

    setState(() => _isSaving = true);

    // Gọi API setup (Dùng chung API /setup của vợ đã gửi)
    bool success = await _houseService.createHouseWithRooms(
      name: name,
      roomNames: selectedRoomNames,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Create a Home", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Home Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 👇 1. DÒNG LOCATION (BẤM VÀO HIỆN MAP)
                  _buildLocationTile(),
                  const SizedBox(height: 32),
                  _buildRoomListSection(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B6EF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile() {
    return GestureDetector(
      onTap: _showMapPicker, // Bấm vào là mở Map Picker
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(_addressController.text, 
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomListSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Add Room(s)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(Icons.add_circle, color: Color(0xFF4B6EF6), size: 30),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestedRooms.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final room = _suggestedRooms[index];
              return ListTile(
                title: Text(room["name"]),
                trailing: Icon(
                  room["selected"] ? Icons.check_circle : Icons.radio_button_off,
                  color: room["selected"] ? const Color(0xFF4B6EF6) : Colors.grey[300],
                ),
                onTap: () => setState(() => room["selected"] = !room["selected"]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- WIDGET BẢN ĐỒ CHỌN VỊ TRÍ ---
class _MapPickerWidget extends StatefulWidget {
  final Function(String) onLocationSelected;
  const _MapPickerWidget({required this.onLocationSelected});

  @override
  State<_MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<_MapPickerWidget> {
  LatLng _currentCenter = const LatLng(10.7769, 106.7009); // Mặc định HCM
  String _address = "Locating...";
  bool _isGettingAddress = false;

  Future<void> _getAddress(LatLng point) async {
    setState(() => _isGettingAddress = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18');
      final response = await http.get(url, headers: {'User-Agent': 'IOT_Smart_App'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _address = data['display_name'] ?? "Unknown location");
      }
    } catch (e) {
      debugPrint("Map Error: $e");
    } finally {
      setState(() => _isGettingAddress = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getAddress(_currentCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Pick Home Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: 16,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _currentCenter = event.camera.center;
                        _getAddress(_currentCenter);
                      }
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  ],
                ),
                // Tâm bản đồ (Ghim)
                Center(child: Padding(padding: const EdgeInsets.only(bottom: 40), child: Icon(Icons.location_on, size: 50, color: Theme.of(context).primaryColor))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_address, style: const TextStyle(fontWeight: FontWeight.w600))),
                    if (_isGettingAddress) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    onPressed: () { widget.onLocationSelected(_address); Navigator.pop(context); },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B6EF6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: const Text("Confirm Location", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}