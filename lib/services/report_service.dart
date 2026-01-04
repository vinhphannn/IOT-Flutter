import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_client.dart';
import '../models/device_model.dart';

class ReportService {
  
  // 1. Lấy dữ liệu biểu đồ tổng hợp (Cộng dồn tất cả thiết bị)
  Future<List<Map<String, dynamic>>> getHouseEnergyChart(List<Device> devices, String type) async {
    Map<String, double> aggregatedData = {};

    // Gọi API song song cho nhanh
    await Future.wait(devices.map((device) async {
      try {
        final response = await ApiClient.get('/devices/${device.id}/energy/chart?type=$type');
        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          
          for (var item in data) {
            // BE trả về: { "date": "2023-10-25", "total": 1.5 }
            String dateKey = item['date'].toString(); 
            double val = double.tryParse(item['total'].toString()) ?? 0.0;
            
            // Cộng dồn vào ngày tương ứng
            aggregatedData[dateKey] = (aggregatedData[dateKey] ?? 0) + val;
          }
        }
      } catch (e) {
        debugPrint("Lỗi lấy chart device ${device.id}: $e");
      }
    }));

    // Chuyển Map -> List và sắp xếp theo ngày
    List<Map<String, dynamic>> result = aggregatedData.entries.map((e) {
      return {"date": DateTime.parse(e.key), "total": e.value};
    }).toList();

    result.sort((a, b) => a['date'].compareTo(b['date']));
    return result;
  }

  // 2. Lấy tổng quan (Hôm nay & Tháng này)
  Future<Map<String, double>> getOverview(List<Device> devices) async {
    double todayTotal = 0.0;
    double monthTotal = 0.0;

    // 2a. Lấy Today từ API
    await Future.wait(devices.map((device) async {
      try {
        final response = await ApiClient.get('/devices/${device.id}/energy/today');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          todayTotal += double.tryParse(data['totalKwh'].toString()) ?? 0.0;
        }
      } catch (e) {
        debugPrint("Lỗi lấy today energy: $e");
      }
    }));

    // 2b. Lấy Month bằng cách gọi chart type=month và cộng dồn
    // (Vì BE chưa có API lấy tổng tháng, ta tận dụng API chart)
    try {
      final monthChart = await getHouseEnergyChart(devices, 'month');
      for (var day in monthChart) {
        monthTotal += day['total'] as double;
      }
    } catch (e) {
      debugPrint("Lỗi tính tổng tháng: $e");
    }

    return {
      "today": todayTotal,
      "month": monthTotal,
    };
  }
}