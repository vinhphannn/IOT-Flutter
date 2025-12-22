import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../routes.dart';

// --- 1. SỬA CLIPPER: Tạo đường cong lõm xuống (Smile Curve) ---
class SmileClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width / 2, 60, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class OnboardingInfo {
  final String title;
  final String description;
  final String image;

  OnboardingInfo({
    required this.title,
    required this.description,
    required this.image,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<OnboardingInfo> _contents = [
    OnboardingInfo(
      title: "Empower Your Home,\nSimplify Your Life",
      description: "Transform your living space into a smarter, more connected home with Smartify.",
      image: "assets/images/onboarding1.png",
    ),
    OnboardingInfo(
      title: "Effortless Control,\nAutomate & Secure",
      description: "Smartify empowers you to control your devices & automate your routines.",
      image: "assets/images/onboarding2.png",
    ),
    OnboardingInfo(
      title: "Efficiency that Saves,\nComfort that Lasts",
      description: "Take control of your home's energy usage, set preferences and enjoy a space.",
      image: "assets/images/onboarding3.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentIndex == _contents.length - 1;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // --- PHẦN 1: ẢNH TRƯỢT DỌC (NẰM DƯỚI) ---
          PageView.builder(
            controller: _controller,
            itemCount: _contents.length,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(
                  top: size.height * 0.12,
                  bottom: size.height * 0.40,
                ),
                child: Image.asset(
                  _contents[index].image,
                  width: size.width * 0.85,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),

          // --- PHẦN 2: KHUNG TRẮNG BO LÕM ---
          ClipPath(
            clipper: SmileClipper(),
            child: Container(
              height: size.height * 0.45,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(30, 60, 30, 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // A. CHỮ (AnimatedSwitcher)
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: Column(
                        key: ValueKey<int>(_currentIndex),
                        children: [
                          Text(
                            _contents[_currentIndex].title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _contents[_currentIndex].description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // B. DẤU CHẤM (DOTS) - NGANG
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _contents.length,
                    axisDirection: Axis.horizontal,
                    effect: ExpandingDotsEffect(
                      activeDotColor: primaryColor,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                      spacing: 8,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // C. HÀNG NÚT BẤM
                  isLastPage
                      // --- NÚT "LET'S GET STARTED" (Ở TRANG CUỐI) ---
                      ? SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              // Chuyển sang trang Welcome/Login Options
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.loginOptions,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Let's Get Started",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      // --- NÚT SKIP & CONTINUE (Ở CÁC TRANG KHÁC) ---
                      : Row(
                          children: [
                            // Nút Skip
                            Expanded(
                              child: SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Nhảy cóc đến trang cuối
                                    _controller.jumpToPage(_contents.length - 1);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor.withOpacity(0.1),
                                    foregroundColor: primaryColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    "Skip",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Nút Continue
                            Expanded(
                              child: SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // *** ĐÃ SỬA LẠI: Trượt sang trang kế tiếp ***
                                    _controller.nextPage(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeInOutCubic,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    "Continue",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}