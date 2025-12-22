import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback? onPressed;
  final IconData fallbackIcon;
  final Color? iconColor;

  const SocialButton({
    super.key,
    required this.label,
    required this.iconPath,
    this.onPressed,
    this.fallbackIcon = Icons.help_outline,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: onPressed ?? () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero, // Quan trọng: Xóa padding mặc định để căn chỉnh chuẩn
        ),
        child: Stack(
          children: [
            // 1. Icon dạt trái (Neo sát bên trái)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20), // Cách lề trái 20px
                child: Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    fallbackIcon,
                    color: iconColor ?? Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // 2. Chữ nằm chính giữa nút
            Align(
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}