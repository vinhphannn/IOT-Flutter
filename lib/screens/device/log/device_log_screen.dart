import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/device_log_model.dart';
import '../../../services/device_service.dart'; // Dùng service mới

class DeviceLogScreen extends StatefulWidget {
  final int deviceId;
  const DeviceLogScreen({super.key, required this.deviceId});

  @override
  State<DeviceLogScreen> createState() => _DeviceLogScreenState();
}

class _DeviceLogScreenState extends State<DeviceLogScreen> {
  final DeviceService _deviceService = DeviceService();
  final List<DeviceLog> _logs = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    
    // Lắng nghe sự kiện cuộn để tải thêm data (Infinite Scroll)
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        if (!_isLoading && _hasMore) {
          _fetchLogs();
        }
      }
    });
  }

  Future<void> _fetchLogs() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      // Tải 20 log mỗi lần
      List<DeviceLog> newLogs = await _deviceService.getDeviceLogs(
        widget.deviceId, 
        page: _currentPage, 
        size: 20
      );
      
      if (mounted) {
        setState(() {
          _logs.addAll(newLogs);
          _currentPage++;
          _isLoading = false;
          // Nếu Backend trả về ít hơn 20 cái nghĩa là đã hết sạch log
          if (newLogs.length < 20) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("❌ Lỗi tải log: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Màu nền xám nhẹ cho sang
      appBar: AppBar(
        title: const Text(
          "Activity History", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. Trường hợp đang tải lần đầu và chưa có data
    if (_logs.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Trường hợp không có log nào
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No activity recorded yet", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 3. Danh sách Log
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _logs.clear();
          _currentPage = 0;
          _hasMore = true;
        });
        await _fetchLogs();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _logs.length + (_hasMore ? 1 : 0),
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          if (index == _logs.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final log = _logs[index];
          final isON = log.action.toUpperCase() == "ON";

          return _buildLogItem(log, isON);
        },
      ),
    );
  }

  Widget _buildLogItem(DeviceLog log, bool isON) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon trạng thái
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isON ? Colors.blue : Colors.grey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isON ? Icons.power_rounded : Icons.power_off_rounded,
              color: isON ? Colors.blue : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Nội dung chính
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Device turned ${isON ? 'ON' : 'OFF'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  "Room: ${log.roomName}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          // Thời gian bên phải
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(log.timestamp),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMM dd').format(log.timestamp),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}