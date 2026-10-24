import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/sensor_providers.dart';
import 'dashboard_screen.dart';

class UserSession {
  final int id;
  final String email;
  final String fullName;
  final String deviceId;

  const UserSession({
    required this.id,
    required this.email,
    required this.fullName,
    required this.deviceId,
  });
}

final currentUserSessionProvider = StateProvider<UserSession?>((ref) {
  // Starts logged out so the user sees the Auth/Login screen first
  return null;
});

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deviceIdController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // UI smoothness

    final email = _emailController.text.trim();
    final name = _isSignUp ? _nameController.text.trim() : (email.contains('aarav') ? 'Aarav Patel' : 'Guest Account');
    final devId = _deviceIdController.text.trim().isNotEmpty
        ? _deviceIdController.text.trim()
        : (email.contains('aarav') ? 'wearable_aarav_02' : 'wearable_guest_01');

    ref.read(currentUserSessionProvider.notifier).state = UserSession(
      id: email.contains('aarav') ? 2 : 1,
      email: email,
      fullName: name,
      deviceId: devId,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _quickLogin(String email, String name, String devId, int id) {
    ref.read(currentUserSessionProvider.notifier).state = UserSession(
      id: id,
      email: email,
      fullName: name,
      deviceId: devId,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B132B), Color(0xFF0F172A), Color(0xFF061826)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDF9), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          );

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fieldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Soothing Ambient Biometric Background
          Positioned.fill(
            child: Container(decoration: BoxDecoration(gradient: bgGradient)),
          ),

          // Ambient Decorative Glow Orbs for visual depth & contrast
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTeal.withOpacity(isDark ? 0.18 : 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -30,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(isDark ? 0.14 : 0.08),
              ),
            ),
          ),

          // 2. Foreground Content in High-Contrast Elevated Cards
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Branding Header
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryTeal, Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryTeal.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.shield_rounded, size: 36, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'EmotiGuard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'IoT Emotional Distress Detection & Support System',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Main Form Card with high contrast & crisp borders
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: cardBorder, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Segmented Switcher (Sign In vs Create Account)
                              Container(
                                decoration: BoxDecoration(
                                  color: fieldBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cardBorder),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _isSignUp = false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          decoration: BoxDecoration(
                                            color: !_isSignUp
                                                ? (isDark ? const Color(0xFF334155) : Colors.white)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: !_isSignUp
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.08),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            'Sign In',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                                              color: !_isSignUp
                                                  ? AppColors.primaryTeal
                                                  : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _isSignUp = true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          decoration: BoxDecoration(
                                            color: _isSignUp
                                                ? (isDark ? const Color(0xFF334155) : Colors.white)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: _isSignUp
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.08),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            'New Account',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w500,
                                              color: _isSignUp
                                                  ? AppColors.primaryTeal
                                                  : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Form Fields
                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'e.g. Guest User',
                                    filled: true,
                                    fillColor: fieldBg,
                                    prefixIcon: const Icon(Icons.person_outline_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                  ),
                                  validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
                                ),
                                const SizedBox(height: 14),
                              ],

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'e.g. user@emotiguard.com',
                                  filled: true,
                                  fillColor: fieldBg,
                                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: fieldBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: fieldBorder),
                                  ),
                                ),
                                validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: '••••••••',
                                  filled: true,
                                  fillColor: fieldBg,
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: fieldBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: fieldBorder),
                                  ),
                                ),
                                validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                              ),
                              const SizedBox(height: 14),

                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _deviceIdController,
                                  decoration: InputDecoration(
                                    labelText: 'ESP32 Device ID (Optional)',
                                    hintText: 'e.g. wearable_user_01',
                                    filled: true,
                                    fillColor: fieldBg,
                                    prefixIcon: const Icon(Icons.bluetooth_rounded),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: fieldBorder),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(_isSignUp ? Icons.person_add_rounded : Icons.login_rounded, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isSignUp ? 'Create My Account' : 'Sign In to My Isolated Data',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Demo Quick-Switch Section Card with High Visibility
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cardBorder, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTeal.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.people_outline_rounded, size: 18, color: AppColors.primaryTeal),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Instant Demo Profiles',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                          ),
                                        ),
                                        Text(
                                          '1-Click switch to inspect separate user baselines',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Guest Account Card
                              InkWell(
                                onTap: () => _quickLogin('guest@emotiguard.com', 'Guest Account', 'wearable_guest_01', 1),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF166534) : const Color(0xFF86EFAC),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Guest Account',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                            ),
                                            Text(
                                              'wearable_guest_01 • Calm Baseline (HR ~71 bpm)',
                                              style: TextStyle(fontSize: 11, color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.green),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Aarav Patel Card
                              InkWell(
                                onTap: () => _quickLogin('aarav@emotiguard.com', 'Aarav Patel', 'wearable_aarav_02', 2),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Aarav Patel',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                            ),
                                            Text(
                                              'wearable_aarav_02 • Elevated Distress (HR ~96 bpm)',
                                              style: TextStyle(fontSize: 11, color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.red),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Security & Privacy Footnote
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 14, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'AES-256 Encrypted at Rest • Zero Data Leakage',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
