import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                },
                child: const Text('Skip Setup', style: TextStyle(color: AppColors.primaryTeal)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // Step 1: Explicit Consent & Privacy Promise
                  _buildPage(
                    icon: Icons.security_rounded,
                    title: 'Your Privacy Is Our Priority',
                    desc:
                        'EmotiGuard stores your physiological metrics encrypted directly on your phone. No health data is uploaded to any server unless you explicitly enable cloud sync in settings.',
                    isDark: isDark,
                  ),
                  // Step 2: Sensor Explanation
                  _buildPage(
                    icon: Icons.sensors_rounded,
                    title: 'How EmotiGuard Protects You',
                    desc:
                        'Your wearable reads heart rate & HRV (MAX30102), electrodermal skin conductance (Grove GSR), and movement (accelerometer) every 5 seconds to recognize when your nervous system needs support.',
                    isDark: isDark,
                  ),
                  // Step 3: Gentle Baseline Calibration
                  _buildPage(
                    icon: Icons.favorite_border_rounded,
                    title: 'Personalized to You',
                    desc:
                        'During your first 7 days, EmotiGuard learns your unique resting baseline. It flags gradual 48-hour emotional fatigue rather than making hasty judgements from brief physical exertion.',
                    isDark: isDark,
                  ),
                  // Step 4: Gentle Non-Forced Interventions
                  _buildPage(
                    icon: Icons.spa_outlined,
                    title: 'Gentle, Respectful Support',
                    desc:
                        'When elevated distress is detected, EmotiGuard suggests guided 4-7-8 breathing and mindful reflection. It will never force actions or message contacts without your explicit tap.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            // Page indicator and Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      4,
                      (i) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primaryTeal
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 54, color: AppColors.primaryTeal),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
