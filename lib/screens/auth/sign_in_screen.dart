import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/social_button.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/house_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // --- GOOGLE LOGIN (ĐÃ BỔ SUNG) ---
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

  // --- SIGN IN THƯỜNG ---
  void _handleSignIn() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Email and Password."), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    AuthService authService = AuthService();
    Map<String, dynamic>? loginResult = await authService.login(_emailController.text, _passController.text);

    if (loginResult != null) {
      try {
        HouseService houseService = HouseService();
        final houses = await houseService.fetchMyHouses();
        final prefs = await SharedPreferences.getInstance();

        if (houses.isNotEmpty) {
          await prefs.setBool('is_setup_completed', true);
          await prefs.setInt('currentHouseId', houses[0].id);
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome back! 👋"), backgroundColor: Colors.green));
          }
        } else {
          await prefs.setBool('is_setup_completed', false);
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signUpSetup, (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Let's set up your home! 🏠"), backgroundColor: Colors.blue));
          }
        }
      } catch (e) {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signUpSetup, (route) => false);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed! Incorrect email or password."), backgroundColor: Colors.red));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
                else Navigator.pushReplacementNamed(context, AppRoutes.loginOptions);
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text("Welcome Back!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Your Smart Home, Your Rules.", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 30),

                _buildLabel("Email"),
                const SizedBox(height: 8),
                _buildTextField(controller: _emailController, hint: "Email", icon: Icons.email_outlined),

                const SizedBox(height: 20),

                _buildLabel("Password"),
                const SizedBox(height: 8),
                _buildTextField(controller: _passController, hint: "Password", icon: Icons.lock_outline, isPassword: true),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(value: _rememberMe, activeColor: primaryColor, onChanged: (val) => setState(() => _rememberMe = val!)),
                        const Text("Remember me", style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                      child: Text("Forgot Password?", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                Center(child: Text("or", style: TextStyle(color: Colors.grey[400]))),
                const SizedBox(height: 30),

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

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleSignIn,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: const Text("Sign in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withOpacity(0.75),
                child: Center(child: CircularProgressIndicator(color: primaryColor)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14));

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
        ),
      ),
    );
  }
}