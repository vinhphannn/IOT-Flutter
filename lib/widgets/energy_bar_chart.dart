import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EnergyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const EnergyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("No data available"));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        // Tự động tính cột cao nhất để scale biểu đồ
        maxY: data.map((e) => e['total'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // 👇 SỬA Ở ĐÂY: Dùng tooltipBgColor thay vì getTooltipColor
            tooltipBgColor: Colors.blueAccent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(2)}\nkWh',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < data.length) {
                  DateTime date = data[index]['date'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date), // Format ngày/tháng
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: data.asMap().entries.map((e) {
          int index = e.key;
          double val = e.value['total'];
          // Tìm giá trị max để tô màu đậm
          double maxVal = data.map((item) => item['total'] as double).reduce((a, b) => a > b ? a : b);
          bool isMax = val == maxVal && val > 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: isMax ? const Color(0xFF4B6EF6) : const Color(0xFFA6B9FF),
                width: 16,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal * 1.2, // Cột mờ làm nền
                  color: Colors.transparent,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}