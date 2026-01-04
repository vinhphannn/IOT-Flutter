import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScheduleTimeScreen extends StatefulWidget {
  const ScheduleTimeScreen({super.key});

  @override
  State<ScheduleTimeScreen> createState() => _ScheduleTimeScreenState();
}

class _ScheduleTimeScreenState extends State<ScheduleTimeScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 45);
  
  // Danh sách các ngày được chọn (Mặc định rỗng -> coi như chạy 1 lần hoặc cần xử lý logic riêng)
  // Nhưng theo yêu cầu vợ: Mặc định là Every Day -> Chọn hết 7 ngày
  List<String> _selectedDays = [
    "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"
  ];

  // Danh sách mẫu để hiển thị UI
  final List<Map<String, String>> _daysOfWeek = [
    {"label": "Monday", "value": "MONDAY"},
    {"label": "Tuesday", "value": "TUESDAY"},
    {"label": "Wednesday", "value": "WEDNESDAY"},
    {"label": "Thursday", "value": "THURSDAY"},
    {"label": "Friday", "value": "FRIDAY"},
    {"label": "Saturday", "value": "SATURDAY"},
    {"label": "Sunday", "value": "SUNDAY"},
  ];

  // Hàm hiển thị text ngắn gọn (VD: Mon, Tue...)
  String _getRepeatText() {
    if (_selectedDays.length == 7) return "Every Day";
    if (_selectedDays.isEmpty) return "Once"; // Hoặc "Never"
    
    // Sắp xếp lại thứ tự cho đúng (phòng khi user chọn lộn xộn)
    // Map value sang index để sort
    List<String> sortedDays = List.from(_selectedDays);
    sortedDays.sort((a, b) {
      int indexA = _daysOfWeek.indexWhere((d) => d["value"] == a);
      int indexB = _daysOfWeek.indexWhere((d) => d["value"] == b);
      return indexA.compareTo(indexB);
    });

    return sortedDays.map((day) {
      return _daysOfWeek.firstWhere((d) => d["value"] == day)["label"]!.substring(0, 3);
    }).join(", ");
  }

  // --- POPUP CHỌN NGÀY ---
  void _showDayPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder( // Cần StatefulBuilder để cập nhật UI trong Popup
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 500, // Chiều cao popup
              child: Column(
                children: [
                  const Text("Repeat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _daysOfWeek.length,
                      itemBuilder: (context, index) {
                        final day = _daysOfWeek[index];
                        final isSelected = _selectedDays.contains(day["value"]);
                        return CheckboxListTile(
                          title: Text(day["label"]!),
                          value: isSelected,
                          activeColor: const Color(0xFF4B6EF6),
                          onChanged: (bool? value) {
                            setModalState(() { // Cập nhật UI popup
                              if (value == true) {
                                _selectedDays.add(day["value"]!);
                              } else {
                                _selectedDays.remove(day["value"]!);
                              }
                            });
                            setState(() {}); // Cập nhật UI màn hình chính luôn
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B6EF6)),
                      child: const Text("Done", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Schedule Time", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- DÒNG REPEAT (BẤM ĐƯỢC) ---
                    InkWell(
                      onTap: _showDayPicker, // Bấm vào để mở popup chọn ngày
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.repeat, color: Colors.black54, size: 20),
                                SizedBox(width: 8),
                                Text("Repeat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Expanded( // Để text dài không bị lỗi overflow
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _getRepeatText(), 
                                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                                      overflow: TextOverflow.ellipsis, // Cắt bớt nếu quá dài
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 30),

                    // --- BỘ CHỌN GIỜ (SPINNER) ---
                    SizedBox(
                      height: 200,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute),
                        use24hFormat: true, 
                        onDateTimeChanged: (DateTime newTime) {
                          setState(() {
                            _selectedTime = TimeOfDay.fromDateTime(newTime);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- NÚT CONTINUE ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  final String formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

                  // Chuẩn bị dữ liệu daysOfWeek theo yêu cầu BE
                  List<String> finalDays = [];
                  if (_selectedDays.length == 7) {
                    finalDays = ["EVERYDAY"]; // Trường hợp 1: Chọn hết 7 ngày
                  } else {
                    finalDays = _selectedDays; // Trường hợp 2: Gửi danh sách lẻ
                  }

                  // Trả dữ liệu về
                  Navigator.pop(context, {
                    "type": "SCHEDULE",
                    "operator": "==",
                    "value": formattedTime,
                    "daysOfWeek": finalDays, // <--- Thêm trường này cho BE
                    
                    // Dữ liệu hiển thị UI
                    "displayTitle": "Schedule Time: $formattedTime",
                    "displaySubtitle": _getRepeatText(),
                    "icon": Icons.access_time_filled,
                    "color": Colors.green,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B6EF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Continue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}