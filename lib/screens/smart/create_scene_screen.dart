import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Import Provider
import '../../providers/house_provider.dart'; // 2. Import HouseProvider
import '../../services/smart_service.dart';
import '../../models/device_model.dart';
import 'weather_condition_screen.dart';
import 'schedule_time_screen.dart';
import 'control_single_device_screen.dart';

class CreateSceneScreen extends StatefulWidget {
  const CreateSceneScreen({super.key});

  @override
  State<CreateSceneScreen> createState() => _CreateSceneScreenState();
}

class _CreateSceneScreenState extends State<CreateSceneScreen> {
  final SmartService _smartService = SmartService();
  bool _isSaving = false;

  List<Map<String, dynamic>> _conditions = [];
  List<Map<String, dynamic>> _actions = [];

  // --- 1. THÊM ĐIỀU KIỆN (IF) ---
  void _addCondition(Widget screen) async {
    Navigator.pop(context); // Đóng popup chọn loại
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() => _conditions.add(result));
    }
  }

  // --- 2. THÊM HÀNH ĐỘNG (THEN) ---
  void _addTask_ControlDevice() async {
    Navigator.pop(context); // Đóng popup danh sách task

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ControlSingleDeviceScreen()),
    );

    if (result != null && result is Map) {
      Device device = result['device'];
      Map actionData = result['actionData'];

      setState(() {
        _actions.add({
          "type": "CONTROL_DEVICE",
          "targetDeviceId": device.id,
          "actionData": actionData,
          
          // Data hiển thị UI
          "displayTitle": "Control: ${device.name}",
          "displaySubtitle": "Action: ${actionData.values.first}", 
          "icon": Icons.power_settings_new,
          "color": Colors.blueAccent,
        });
      });
    }
  }

  // --- 3. HIỆN POPUP NHẬP TÊN & LƯU ---
  void _showNameInputDialog() {
    if (_actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one Task (Then)")));
      return;
    }

    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Scene Name", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Enter scene name (e.g. Turn on AC)",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context); // Đóng dialog
                    _processSaveData(nameController.text.trim()); // Tiến hành lưu
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B6EF6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- 4. XỬ LÝ DỮ LIỆU & GỌI API ---
  void _processSaveData(String sceneName) async {
    // 👇 1. LẤY HOUSE ID TỪ PROVIDER (THAY VÌ HARDCODE 1)
    final houseProvider = context.read<HouseProvider>();
    final currentHouseId = houseProvider.currentHouse?.id;
    // 👇 THÊM 2 DÒNG NÀY ĐỂ SOI LỖI
    print("🏠 Nhà đang chọn trong Provider là: $currentHouseId");
    print("🚀 Đang gửi yêu cầu tạo Scene với houseId: $currentHouseId");

    if (currentHouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No house selected!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    // A. Xác định loại Scene
    String sceneType = _conditions.isEmpty ? "TAP_TO_RUN" : "AUTOMATION";

    // B. Map dữ liệu Conditions (IF)
    List<Map<String, dynamic>> apiConditions = _conditions.map((c) {
      Map<String, dynamic> cond = {
        "type": c["type"],
        "operator": c["operator"] ?? "==", 
        "value": c["value"]
      };
      if (c.containsKey("daysOfWeek")) cond["daysOfWeek"] = c["daysOfWeek"];
      if (c.containsKey("triggerDeviceId")) cond["triggerDeviceId"] = c["triggerDeviceId"];
      return cond;
    }).toList();

    // C. Map dữ liệu Actions (THEN)
    List<Map<String, dynamic>> apiActions = _actions.map((a) => {
      "type": "CONTROL_DEVICE",
      "targetDeviceId": a["targetDeviceId"],
      "delaySeconds": 0,
      "actionData": a["actionData"]
    }).toList();

    String iconUrl = sceneType == "TAP_TO_RUN" ? "assets/icons/touch.png" : "assets/icons/clock.png";
    String colorCode = sceneType == "TAP_TO_RUN" ? "#5D3FD3" : "#FFCC00";

    // E. Gọi Service
    bool success = await _smartService.createScene(
      name: sceneName,
      houseId: currentHouseId, // 👈 2. SỬ DỤNG ID VỪA LẤY
      type: sceneType,
      iconUrl: iconUrl,
      colorCode: colorCode,
      conditions: apiConditions,
      actions: apiActions,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context); // Về trang chủ
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scene created successfully!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create scene"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Create Scene", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // IF SECTION
                  _buildSectionHeader("If", "When any condition is met", _showAddConditionModal),
                  const SizedBox(height: 12),
                  ..._conditions.map((cond) => _buildCard(cond, isCondition: true)).toList(),

                  const SizedBox(height: 24),

                  // THEN SECTION
                  _buildSectionHeader("Then", null, _showAddTaskModal),
                  const SizedBox(height: 12),
                  ..._actions.map((act) => _buildCard(act, isCondition: false)).toList(),

                  if (_actions.isEmpty)
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: OutlinedButton(
                        onPressed: _showAddTaskModal, 
                        style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: const Text("Add Task", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _showNameInputDialog,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- CÁC WIDGET UI (GIỮ NGUYÊN) ---
  void _showAddConditionModal() {
     showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
            const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16), const Text("Add Condition", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16), const Divider(height: 1),
            Expanded(child: ListView(padding: EdgeInsets.zero, children: [
                  _buildPopupItem(icon: Icons.touch_app, color: Colors.blue, title: "Tap-to-Run", onTap: () {}),
                  const Divider(height: 1, indent: 60),
                  _buildPopupItem(icon: Icons.access_time_filled, color: Colors.green, title: "Schedule Time", onTap: () => _addCondition(const ScheduleTimeScreen())),
                  const Divider(height: 1, indent: 60),
                  _buildPopupItem(icon: Icons.wb_sunny_outlined, color: Colors.orange, title: "When Weather Changes", onTap: () => _addCondition(const WeatherConditionScreen())),
            ]))
        ]),
      ),
    );
  }

  void _showAddTaskModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(children: [
            const SizedBox(height: 12), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16), const Text("Add Task", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16), const Divider(height: 1),
            Expanded(child: ListView(padding: EdgeInsets.zero, children: [
                  _buildPopupItem(icon: Icons.work_outline, color: Colors.blue, title: "Control Single Device", onTap: _addTask_ControlDevice),
                  const Divider(height: 1, indent: 60),
                  _buildPopupItem(icon: Icons.check_circle_outline, color: Colors.green, title: "Select Smart Scene", onTap: () {}),
                  const Divider(height: 1, indent: 60),
                  _buildPopupItem(icon: Icons.access_time, color: Colors.grey, title: "Delay the Action", onTap: () {}),
            ]))
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? subtitle, VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13))]
          ]),
          InkWell(onTap: onAdd, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF4B6EF6), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 20)))
        ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> data, {required bool isCondition}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
          Icon(data['icon'], color: data['color'], size: 28), const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['displayTitle'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (data['displaySubtitle'] != null) ...[const SizedBox(height: 4), Text(data['displaySubtitle'], style: TextStyle(color: Colors.grey[500], fontSize: 13))]
              ])),
          IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 20), onPressed: () { setState(() { if (isCondition) _conditions.remove(data); else _actions.remove(data); }); })
        ]),
    );
  }

  Widget _buildPopupItem({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), child: Row(children: [
          Icon(icon, color: color, size: 24), const SizedBox(width: 16), Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))), const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
        ])));
  }
}