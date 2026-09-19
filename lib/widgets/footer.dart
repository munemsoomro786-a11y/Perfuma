import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'whatsapp_icon.dart';

class FooterWidget extends StatefulWidget {
  const FooterWidget({super.key});

  @override
  State<FooterWidget> createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget> {
  final TextEditingController _newsletterController = TextEditingController();
  bool _isSubscribing = false;

  @override
  void dispose() {
    _newsletterController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=Rahimyar+Khan,+Punjab,+Pakistan');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/923113418134');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openGmail() async {
    final Uri url = Uri.parse('mailto:munemsoomro786@gmail.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showTextDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontFamily: 'Georgia', letterSpacing: 1)),
        content: Text(content, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribeNewsletter() async {
    final email = _newsletterController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your email to subscribe.')),
      );
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a proper email with @ (e.g. yourname@gmail.com).')),
      );
      return;
    }

    setState(() => _isSubscribing = true);

    try {
      final response = await http.post(
        Uri.parse('https://formsubmit.co/ajax/munemsoomro786@gmail.com'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          '_subject': 'New Newsletter Subscriber!',
          'message': '$email has just subscribed to the Perfuma newsletter.',
        }),
      );

      _newsletterController.clear();
      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscribed successfully! Welcome to Perfuma Club.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to subscribe. Please try again later.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to subscribe. Please try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 800;
        final bool isSmallScreen = constraints.maxWidth < 650;

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 40 : 80,
            horizontal: isMobile ? 20 : 60,
          ),
          color: const Color(0xFF111111),
          child: Column(
            children: [
              isMobile
                  ? Column(
                      children: _buildFooterColumns(isMobile, context),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFooterColumns(isMobile, context),
                    ),
              SizedBox(height: isMobile ? 40 : 60),
              Divider(color: Colors.grey[800]),
              const SizedBox(height: 20),
              if (isSmallScreen)
                Column(
                  children: [
                    Text(
                      '© 2026 Perfuma Fragrances. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => _showTextDialog(context, 'Privacy Policy', 'Your privacy is important to us. All personal info and order data is kept strictly confidential.'),
                          child: Text('Privacy Policy', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('|', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                        ),
                        InkWell(
                          onTap: () => _showTextDialog(context, 'Terms of Service', 'By using our website you agree to our terms of purchasing luxury authentic fragrances.'),
                          child: Text('Terms of Service', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '© 2026 Perfuma Fragrances. All rights reserved.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _showTextDialog(context, 'Privacy Policy', 'Your privacy is important to us. All personal info and order data is kept strictly confidential.'),
                          child: Text('Privacy Policy', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ),
                        const SizedBox(width: 24),
                        InkWell(
                          onTap: () => _showTextDialog(context, 'Terms of Service', 'By using our website you agree to our terms of purchasing luxury authentic fragrances.'),
                          child: Text('Terms of Service', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ),
                      ],
                    )
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFooterColumns(bool isMobile, BuildContext context) {
    return [
      // Brand & Location Column (With Official Icons!)
      Container(
        width: isMobile ? double.infinity : 280,
        margin: EdgeInsets.only(bottom: isMobile ? 40 : 0),
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfuma',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 32,
                letterSpacing: 4,
                color: Color(0xFFc9a063), // Gold
              ),
            ),
            const SizedBox(height: 20),

            // 📍 Location Row (Clickable for Google Maps!)
            InkWell(
              onTap: _openGoogleMaps,
              child: Row(
                mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFFc9a063), size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Rahimyar Khan, Punjab, Pakistan',
                      style: const TextStyle(color: Color(0xFFc9a063), fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ✉️ Email Row (Clickable)
            InkWell(
              onTap: _openGmail,
              child: Row(
                mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.email_outlined, color: Color(0xFFc9a063), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'munemsoomro786@gmail.com',
                    style: TextStyle(color: Color(0xFFc9a063), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 💬 Official WhatsApp Row (Clickable with WhatsAppIcon!)
            InkWell(
              onTap: _openWhatsApp,
              child: Row(
                mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  WhatsAppIcon(size: 18, color: Color(0xFFc9a063)),
                  SizedBox(width: 8),
                  Text(
                    '+92 311 3418134',
                    style: TextStyle(color: Color(0xFFc9a063), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Social Icon Buttons
            Row(
              mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                _SocialIconWidget(
                  onTap: _openWhatsApp,
                  child: const WhatsAppIcon(size: 18, color: Color(0xFFc9a063)),
                ),
                const SizedBox(width: 12),
                _SocialIconWidget(
                  onTap: _openGmail,
                  child: const Icon(Icons.email_outlined, color: Color(0xFFc9a063), size: 18),
                ),
                const SizedBox(width: 12),
                _SocialIconWidget(
                  onTap: () {},
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFFc9a063), size: 18),
                ),
              ],
            )
          ],
        ),
      ),

      // Quick Shop Links
      Container(
        width: isMobile ? double.infinity : 150,
        margin: EdgeInsets.only(bottom: isMobile ? 40 : 0),
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            const Text('SHOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 20),
            _FooterLink(text: 'All Perfumes', onTap: () => context.go('/shop')),
            _FooterLink(text: 'Best Sellers', onTap: () => context.go('/shop')),
            _FooterLink(text: 'New Arrivals', onTap: () => context.go('/shop')),
            _FooterLink(text: 'Gift Sets', onTap: () => context.go('/shop')),
          ],
        ),
      ),

      // Company Links
      Container(
        width: isMobile ? double.infinity : 150,
        margin: EdgeInsets.only(bottom: isMobile ? 40 : 0),
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            const Text('COMPANY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 20),
            _FooterLink(text: 'About Us', onTap: () => context.go('/story')),
            _FooterLink(text: 'Reviews', onTap: () => context.go('/reviews')),
            _FooterLink(text: 'Contact', onTap: () => context.go('/contact')),
            _FooterLink(text: 'FAQ', onTap: () => context.go('/contact')),
            _FooterLink(text: 'Careers', onTap: () => _showTextDialog(context, 'Careers', 'We are currently not hiring.')),
          ],
        ),
      ),

      // Newsletter Column
      SizedBox(
        width: isMobile ? double.infinity : 300,
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            const Text('NEWSLETTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 20),
            Text(
              'Subscribe to receive updates, access to exclusive deals, and new launches.',
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
              style: TextStyle(color: Colors.grey[400], height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newsletterController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: const BorderSide(color: Color(0xFFc9a063)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFc9a063),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      elevation: 0,
                    ),
                    onPressed: _isSubscribing ? null : _subscribeNewsletter,
                    child: _isSubscribing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('SUBSCRIBE'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    ];
  }
}

class _FooterLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _FooterLink({required this.text, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: _isHovered ? const Color(0xFFc9a063) : Colors.grey[400],
              fontSize: 15,
              fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(widget.text),
          ),
        ),
      ),
    );
  }
}

class _SocialIconWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _SocialIconWidget({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: child,
      ),
    );
  }
}
