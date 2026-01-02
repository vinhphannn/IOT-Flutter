import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/social_button.dart'; 
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/house_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isChecked = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // --- GOOGLE LOGIN ---
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

  // --- SIGN UP THƯỜNG ---
  void _handleSignUp() async {
    if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please agree to Terms & Conditions first!"), backgroundColor: Colors.red));
      return;
    }
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter Email and Password."), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    AuthService authService = AuthService();
    bool registerSuccess = await authService.register(_emailController.text, _passController.text);

    if (registerSuccess) {
      Map<String, dynamic>? loginResult = await authService.login(_emailController.text, _passController.text);

      if (loginResult != null && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signUpSetup, (route) => false);
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.signIn);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Failed! Email might be taken."), backgroundColor: Colors.red));
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Join Smartify Today", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Icon(Icons.person, color: primaryColor, size: 28),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Join Smartify, Your Gateway to Smart Living.", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
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
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: _isChecked,
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (value) => setState(() => _isChecked = value!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: "I agree to Smartify ",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          children: [
                            TextSpan(text: "Terms & Conditions.", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Sign in",
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushReplacementNamed(context, AppRoutes.signIn),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(child: Text("or", style: TextStyle(color: Colors.grey[400]))),
                const SizedBox(height: 30),

                SocialButton(
                  label: "Continue with Google",
                  iconPath: "assets/icons/google.png",
                  fallbackIcon: Icons.g_mobiledata,
                  onPressed: _handleGoogleSignIn,
                ),
                const SizedBox(height: 15),
                SocialButton(
                  label: "Continue with Apple",
                  iconPath: "assets/icons/apple.png",
                  fallbackIcon: Icons.apple,
                  onPressed: () {},
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleSignUp, 
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: const Text("Sign up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                child: Center(
                  child: const CircularProgressIndicator(),
                ),
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