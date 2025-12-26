import 'package:flutter/material.dart';
import 'tabs/general_tab.dart';
import 'tabs/smart_home_tab.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 2, // Số lượng tab
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Notification",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black), // Icon bánh răng
              onPressed: () {},
            ),
          ],
          // --- TAB BAR CUSTOM ---
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100], // Màu nền xám nhạt của cả thanh
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                // Trang trí cho Tab đang chọn (Màu xanh, bo góc)
                indicator: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                indicatorSize: TabBarIndicatorSize.tab, // Indicator phủ đầy tab
                dividerColor: Colors.transparent, // Bỏ đường gạch chân xấu xí
                labelColor: Colors.white, // Màu chữ khi chọn
                unselectedLabelColor: Colors.black87, // Màu chữ khi không chọn
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: "General"),
                  Tab(text: "Smart Home"),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            GeneralTab(),
            SmartHomeTab(),
          ],
        ),
      ),
    );
  }
}