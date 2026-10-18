import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';
import 'package:bishe_car_wash/features/navigation/presentation/screens/app_navigation_shell.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateToMainScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AppNavigationShell(),
      ),
    );
  }

  // Helper method to trigger native URL Scheme actions
  Future<void> _launchExternalUrl(
      BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening link: $e')),
      );
    }
  }

  // Modal bottom sheet specifically for selecting and calling phone numbers
  void _showPhoneNumbersSheet(BuildContext context) {
    final List<Map<String, String>> phoneNumbers = [
      {
        'label': 'Primary Hotline',
        'number': '+251910046553',
      },
      {
        'label': 'Secondary Line 1',
        'number': '+251 9X XXX XXX1', // Replace when number is available
      },
      {
        'label': 'Secondary Line 2',
        'number': '+251 9X XXX XXX2', // Replace when number is available
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.phone_in_talk_rounded,
                      color: AppColors.primaryBlue, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Select Phone Line to Call',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: phoneNumbers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final phone = phoneNumbers[index];
                  final String rawNumber = phone['number']!.replaceAll(' ', '');

                  return Card(
                    elevation: 0,
                    color: AppColors.iceBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primaryBlue.withOpacity(0.15),
                        child: const Icon(Icons.call,
                            color: AppColors.primaryBlue, size: 20),
                      ),
                      title: Text(
                        phone['label']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        phone['number']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: AppColors.primaryBlue),
                      onTap: () {
                        Navigator.pop(context);
                        _launchExternalUrl(context, 'tel:$rawNumber');
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Modal sheet for social media & email links
  void _showSingleContactDetails(
    BuildContext context, {
    required String title,
    required String detail,
    required String actionUrl,
    required String actionLabel,
    required IconData icon,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                detail,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Launch App Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(icon, size: 20),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _launchExternalUrl(context, actionUrl);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Copy to Clipboard Action
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy to Clipboard'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: detail));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.successGreen,
                        content: Text('$title copied to clipboard!'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Header Tag
                const SizedBox(height: 8),
                const Text(
                  'BISHOFTU, OROMIA, ETHIOPIA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 24),

                // Center Logo / Illustration Block
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_car_wash,
                          size: 80,
                          color: AppColors.primaryBlue,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BISHE CAR WASH',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium Stationary & Mobile Car Wash Services in Bishoftu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 28),

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _navigateToMainScreen(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Compact Social Media & Contact Icon Bar
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Contact & Social Support',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 1. Single Consolidated Phone Call Icon
                            _IconButtonBadge(
                              icon: Icons.phone_in_talk_rounded,
                              badgeColor: AppColors.primaryBlue,
                              tooltip: 'Phone Call Desk',
                              onTap: () => _showPhoneNumbersSheet(context),
                            ),

                            // 2. Telegram
                            _IconButtonBadge(
                              icon: Icons.send_rounded,
                              badgeColor: const Color(0xFF0088CC),
                              tooltip: 'Telegram Channel',
                              onTap: () => _showSingleContactDetails(
                                context,
                                title: 'Telegram Channel',
                                detail: '@bishecarwash',
                                actionUrl: 'https://t.me/bishecarwash',
                                actionLabel: 'Open Telegram Channel',
                                icon: Icons.send_rounded,
                                color: const Color(0xFF0088CC),
                              ),
                            ),

                            // 3. WhatsApp
                            _IconButtonBadge(
                              icon: Icons.chat_bubble_rounded,
                              badgeColor: const Color(0xFF25D366),
                              tooltip: 'WhatsApp Chat',
                              onTap: () => _showSingleContactDetails(
                                context,
                                title: 'WhatsApp Support',
                                detail: '+251910046553',
                                actionUrl: 'https://wa.me/251910046553',
                                actionLabel: 'Open WhatsApp Chat',
                                icon: Icons.chat_bubble_rounded,
                                color: const Color(0xFF25D366),
                              ),
                            ),

                            // 4. Official Email
                            _IconButtonBadge(
                              icon: Icons.mark_email_read_rounded,
                              badgeColor: Colors.redAccent.shade400,
                              tooltip: 'Official Email',
                              onTap: () => _showSingleContactDetails(
                                context,
                                title: 'Official Email',
                                detail: 'info@bishecarwash.com',
                                actionUrl: 'mailto:info@bishecarwash.com',
                                actionLabel: 'Send Email Now',
                                icon: Icons.mark_email_read_rounded,
                                color: Colors.redAccent.shade400,
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
          ),
        ),
      ),
    );
  }
}

class _IconButtonBadge extends StatelessWidget {
  final IconData icon;
  final Color badgeColor;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButtonBadge({
    required this.icon,
    required this.badgeColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
