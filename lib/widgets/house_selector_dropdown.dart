import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/house_provider.dart';
import '../models/house_model.dart';

class HouseSelectorDropdown extends StatelessWidget {
  final Color textColor;
  
  const HouseSelectorDropdown({super.key, this.textColor = Colors.black});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe HouseProvider
    return Consumer<HouseProvider>(
      builder: (context, houseProvider, child) {
        if (houseProvider.isLoading) {
          return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (houseProvider.houses.isEmpty) {
          return Text("My Home", style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold));
        }

        return PopupMenuButton<House>(
          onSelected: (house) {
            // Gọi hàm selectHouse trong Provider -> Tự động update toàn app
            houseProvider.selectHouse(house);
          },
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          itemBuilder: (context) => houseProvider.houses.map((h) => PopupMenuItem<House>(
            value: h,
            child: Row(
              children: [
                Icon(Icons.home, color: h.id == houseProvider.currentHouse?.id ? Colors.blue : Colors.grey, size: 20),
                const SizedBox(width: 10),
                Text(h.name, style: TextStyle(fontWeight: h.id == houseProvider.currentHouse?.id ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          )).toList(),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  houseProvider.currentHouse?.name ?? "My Home",
                  style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: textColor, size: 28),
            ],
          ),
        );
      },
    );
  }
}