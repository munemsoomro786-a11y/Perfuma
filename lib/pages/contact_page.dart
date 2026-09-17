import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/whatsapp_icon.dart';
import '../main.dart';

class ContactPageScreen extends StatefulWidget {
  const ContactPageScreen({super.key});

  @override
  State<ContactPageScreen> createState() => _ContactPageScreenState();
}

class _ContactPageScreenState extends State<ContactPageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSuccess = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Do you ship to Rahimyar Khan & across Pakistan?',
      'answer': 'Yes! We deliver across Rahimyar Khan, Punjab, and all major cities in Pakistan with Cash on Delivery (COD) and fast courier delivery.'
    },
    {
      'question': 'How can I place an order via WhatsApp?',
      'answer': 'You can tap on our WhatsApp contact card (+92 311 3418134) to chat directly with our team and place your order.'
    },
    {
      'question': 'What is your return policy?',
      'answer': 'We offer a 30-day hassle-free return policy if the bottle remains sealed and in its original luxury packaging.'
    },
    {
      'question': 'Are Perfuma fragrances 100% authentic and long-lasting?',
      'answer': 'Yes! All our fragrances feature high-concentration eau de parfum oils lasting 12+ hours.'
    },
    {
      'question': 'How can I track my order?',
      'answer': 'Once dispatched, you will receive an automated tracking link on your phone/email.'
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=Rahimyar+Khan,+Punjab,+Pakistan');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/923113418134');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp. Please save +923113418134.')),
        );
      }
    }
  }

  Future<void> _openGmail() async {
    final Uri url = Uri.parse('mailto:munemsoomro786@gmail.com?subject=Inquiry%20from%20Perfuma%20Website');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client. Please write to munemsoomro786@gmail.com.')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final msg = _messageController.text.trim();

    if (name.isEmpty || email.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all contact fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('https://formsubmit.co/ajax/munemsoomro786@gmail.com'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'message': msg,
          '_subject': 'New Contact Form Submission from Perfuma Website',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
      } else {
        throw Exception('Failed to send');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again later.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavbarWidget(scaffoldKey: _scaffoldKey, currentRoute: '/contact'),
      drawer: const MobileNavDrawerWidget(currentRoute: '/contact'),
      endDrawer: const CartDrawer(),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                color: const Color(0xFFfaf9f6),
                child: Column(
                  children: [
                    const Text(
                      'CONTACT US & FAQ',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 40,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reach out directly via WhatsApp, Email, or the form below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),

              // Contact Form & Info Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                color: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWide = constraints.maxWidth > 750;
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildContactInfo()),
                                  const SizedBox(width: 60),
                                  Expanded(child: _buildFormCard()),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildContactInfo(),
                                  const SizedBox(height: 40),
                                  _buildFormCard(),
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ),

              // FAQ Accordion
              Container(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                color: const Color(0xFFfaf9f6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        const Text(
                          'FREQUENTLY ASKED QUESTIONS',
                          style: TextStyle(fontFamily: 'Georgia', fontSize: 32),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _faqs.length,
                          itemBuilder: (context, index) {
                            final faq = _faqs[index];
                            return _FaqTileWidget(
                              question: faq['question']!,
                              answer: faq['answer']!,
                              initiallyExpanded: index == 0,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Get in Touch',
          style: TextStyle(fontFamily: 'Georgia', fontSize: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'We would love to hear from you! Select a contact channel below to connect with our team.',
          style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 16),
        ),
        const SizedBox(height: 35),

        // Location Card (Clickable for Google Maps!)
        InkWell(
          onTap: _openGoogleMaps,
          borderRadius: BorderRadius.circular(6),
          child: const _ContactCardItem(
            customIcon: Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
            title: 'LOCATION',
            detail: 'Rahimyar Khan, Punjab, Pakistan',
            subtitle: 'Tap to view on Google Maps',
            isClickable: true,
          ),
        ),
        const SizedBox(height: 20),

        // Email Card
        InkWell(
          onTap: _openGmail,
          borderRadius: BorderRadius.circular(6),
          child: const _ContactCardItem(
            customIcon: Icon(Icons.email_outlined, color: Colors.white, size: 20),
            title: 'EMAIL ADDRESS',
            detail: 'munemsoomro786@gmail.com',
            subtitle: 'Tap to send an email',
            isClickable: true,
          ),
        ),
        const SizedBox(height: 20),

        // WhatsApp Card
        InkWell(
          onTap: _openWhatsApp,
          borderRadius: BorderRadius.circular(6),
          child: const _ContactCardItem(
            customIcon: WhatsAppIcon(size: 20, color: Colors.white),
            title: 'WHATSAPP & PHONE',
            detail: '+92 311 3418134',
            subtitle: 'Tap to chat directly on WhatsApp',
            isClickable: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _isSuccess
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                const Text('Message Sent!', style: TextStyle(fontFamily: 'Georgia', fontSize: 28)),
                const SizedBox(height: 10),
                const Text('Thank you for reaching out. We will get back to you shortly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () => setState(() => _isSuccess = false),
                  child: const Text('SEND ANOTHER MESSAGE'),
                )
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SEND US A MESSAGE', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Your Message', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFc9a063),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    ),
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SUBMIT MESSAGE', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ContactCardItem extends StatelessWidget {
  final Widget customIcon;
  final String title;
  final String detail;
  final String subtitle;
  final bool isClickable;

  const _ContactCardItem({
    required this.customIcon,
    required this.title,
    required this.detail,
    required this.subtitle,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    const effectiveAccent = Color(0xFFc9a063);
    final effectiveBg = isClickable ? effectiveAccent : const Color(0xFFFAF9F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isClickable ? const Color(0xFFFAF9F6) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isClickable ? effectiveAccent.withValues(alpha: 0.4) : Colors.grey[200]!,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: effectiveBg,
              shape: BoxShape.circle,
            ),
            child: customIcon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isClickable ? effectiveAccent : Colors.grey[600],
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (isClickable)
            const Icon(Icons.open_in_new_rounded, size: 16, color: effectiveAccent),
        ],
      ),
    );
  }
}

class _FaqTileWidget extends StatefulWidget {
  final String question;
  final String answer;
  final bool initiallyExpanded;

  const _FaqTileWidget({
    required this.question,
    required this.answer,
    this.initiallyExpanded = false,
  });

  @override
  State<_FaqTileWidget> createState() => _FaqTileWidgetState();
}

class _FaqTileWidgetState extends State<_FaqTileWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Georgia',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFFc9a063),
                      size: 22,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          Divider(color: Colors.grey[200], height: 1),
                          const SizedBox(height: 14),
                          Text(
                            widget.answer,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.6,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
