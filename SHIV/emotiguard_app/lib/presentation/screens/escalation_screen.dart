import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/trusted_contact.dart';

class EscalationScreen extends StatefulWidget {
  const EscalationScreen({super.key});

  @override
  State<EscalationScreen> createState() => _EscalationScreenState();
}

class _EscalationScreenState extends State<EscalationScreen> {
  // Demo trusted contact if none set
  final List<TrustedContact> _contacts = [
    const TrustedContact(
      id: '1',
      name: 'Aditi Sharma',
      phoneNumber: '+919876543210',
      relationship: 'Close Friend',
    ),
    const TrustedContact(
      id: '2',
      name: 'Rohan Verma',
      phoneNumber: '+919812345678',
      relationship: 'Brother',
    ),
  ];

  Future<void> _launchWhatsApp(TrustedContact contact) async {
    final confirmed = await _showConsentDialog(contact.name, 'WhatsApp message');
    if (!confirmed) return;

    final msg = Uri.encodeComponent(
      'Hi ${contact.name}, my EmotiGuard wearable detected elevated distress. I wanted to reach out — could we talk for a few minutes?',
    );
    final url = Uri.parse('whatsapp://send?phone=${contact.phoneNumber}&text=$msg');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showError('WhatsApp is not installed on this device.');
    }
  }

  Future<void> _launchSms(TrustedContact contact) async {
    final confirmed = await _showConsentDialog(contact.name, 'SMS text message');
    if (!confirmed) return;

    final msg = Uri.encodeComponent(
      'Hi ${contact.name}, my EmotiGuard wearable detected elevated distress. I am reaching out — could we talk when you are free?',
    );
    final url = Uri.parse('sms:${contact.phoneNumber}?body=$msg');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showError('SMS messaging is not available on this device.');
    }
  }

  Future<void> _callHelpline(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<bool> _showConsentDialog(String contactName, String channel) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Reaching Out'),
            content: Text(
              'EmotiGuard never sends automatic messages without your explicit choice.\n\nWould you like to open your $channel to $contactName now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.statusHigh),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Reaching Out'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compassionate Header Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: AppColors.primaryTeal, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'You do not have to carry everything alone. Connecting with someone you trust can help reset your nervous system.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Trusted Contacts Section
              Text(
                'Your Trusted Circle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final c = _contacts[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryTeal.withOpacity(0.15),
                          child: Text(
                            c.name.substring(0, 1),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(
                                '${c.relationship} • ${c.phoneNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 22),
                          tooltip: 'WhatsApp',
                          onPressed: () => _launchWhatsApp(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.sms_outlined, color: AppColors.skyBlue, size: 22),
                          tooltip: 'SMS',
                          onPressed: () => _launchSms(c),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Verified Crisis Helplines
              Text(
                '24/7 Free & Confidential Helplines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 10),

              _buildHelplineCard(
                title: 'Tele-MANAS (India)',
                desc: 'Government of India 24/7 Tele Mental Health Care',
                phone: '14416',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildHelplineCard(
                title: 'KIRAN Helpline (India)',
                desc: '24/7 Mental Health Rehabilitation Toll-Free',
                phone: '1800-599-0019',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildHelplineCard(
                title: 'Vandrevala Foundation',
                desc: 'Free 24/7 Psychological Counseling',
                phone: '+919999666555',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildHelplineCard(
                title: '988 Lifeline (USA & Canada)',
                desc: 'Suicide & Crisis Lifeline - Call or Text 24/7',
                phone: '988',
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelplineCard({
    required String title,
    required String desc,
    required String phone,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.statusMild.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.statusMild, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _callHelpline(phone),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(phone, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
