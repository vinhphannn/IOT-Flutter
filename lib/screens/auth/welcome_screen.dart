import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/social_button.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/house_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    AuthService authService = AuthService();
    bool success = await authService.signInWithGoogle();

    if (success && mounted) {
      try {
        HouseService houseService = HouseService();
        final houses = await houseService.fetchMyHouses();
        final prefs = await SharedPreferences.getInstance();

        if (houses.isNotEmpty) {
          await prefs.setBool('is_setup_completed', true);
          await prefs.setInt('currentHouseId', houses[0].id);
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        } else {
          await prefs.setBool('is_setup_completed', false);
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signUpSetup, (route) => false);
        }
      } catch (e) {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signUpSetup, (route) => false);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Sign-In Failed."), backgroundColor: Colors.red));
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final primaryColor = Theme.of(context).primaryColor;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      SizedBox(height: size.height * 0.05),
                      Image.asset(
                        'assets/images/logo_mau.png',
                        height: 80, 
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.wifi_tethering, size: 80, color: primaryColor),
                      ),
                      const SizedBox(height: 30),
                      const Text("Let's Get Started!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 10),
                      Text("Let's dive in into your account", style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                    ],
                  ),

                  Column(
                    children: [
                      // GOOGLE LOGIN
                      SocialButton(
                        label: "Continue with Google",
                        iconPath: "assets/icons/google.png",
                        fallbackIcon: Icons.g_mobiledata,
                        onPressed: _handleGoogleSignIn, // <--- ĐÃ GẮN HÀM
                      ),
                      const SizedBox(height: 15),
                      
                      SocialButton(
                        label: "Continue with Apple",
                        iconPath: "assets/icons/apple.png",
                        fallbackIcon: Icons.apple,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 15),

                      SocialButton(
                        label: "Continue with Facebook",
                        iconPath: "assets/icons/facebook.png",
                        fallbackIcon: Icons.facebook,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 15),

                      SocialButton(
                        label: "Continue with Twitter",
                        iconPath: "assets/icons/twitter.png",
                        fallbackIcon: Icons.flutter_dash,
                        onPressed: () {},
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.signUp),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          child: const Text("Sign up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      
                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.signIn),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor.withOpacity(0.1), foregroundColor: primaryColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                          child: const Text("Sign in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Privacy Policy", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("·", style: TextStyle(color: Colors.grey[400], fontSize: 12))),
                          Text("Terms of Service", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}