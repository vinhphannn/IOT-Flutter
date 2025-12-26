import 'package:flutter/material.dart';

class NavigationService {
  // Cái chìa khóa này giúp điều khiển màn hình từ bất cứ đâu
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}