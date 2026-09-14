import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AuraApp());
}

// -----------------------------------------------------------------------------
// CART STATE MANAGEMENT
// -----------------------------------------------------------------------------
class CartItem {
  final String title;
  final int basePrice;
  final String image;
  int quantity;

  CartItem({required this.title, required this.basePrice, required this.image, this.quantity = 1});
}

final ValueNotifier<List<CartItem>> cartNotifier = ValueNotifier([]);
final ValueNotifier<String> currencyNotifier = ValueNotifier('PKR');

String formatPrice(int basePricePKR, String currency) {
  if (currency == 'USD') {
    return '\${(basePricePKR * 0.0036).toStringAsFixed(2)}';
  } else if (currency == 'EUR') {
    return '�${(basePricePKR * 0.0033).toStringAsFixed(2)}';
  }
  return 'Rs. ${basePricePKR.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}

void addToCart(String title, int basePrice, String image) {
  final cart = List<CartItem>.from(cartNotifier.value);
  int index = cart.indexWhere((item) => item.title == title);
  if (index >= 0) {
    cart[index].quantity++;
  } else {
    cart.add(CartItem(title: title, basePrice: basePrice, image: image));
  }
  cartNotifier.value = cart;
}

// -----------------------------------------------------------------------------
// MAIN APP
// -----------------------------------------------------------------------------
class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perfuma Fragrances',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFc9a063), // Elegant gold
        scaffoldBackgroundColor: const Color(0xFFfaf9f6), // Off-white
        fontFamily: 'Helvetica Neue',
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _newsletterController = TextEditingController();
  Timer? _timer;
  int _currentPage = 0;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  final List<String> _heroImages = [
    'images/hero.jpg',
    'images/floral_hero.jpg',
    'images/amber_hero.jpg',
    'images/citrus_hero.jpg',
    'images/minimal_hero.jpg',
    'images/ocean_hero.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(double offset) {
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
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
            child: const Text('CLOSE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: Colors.white,
        title: const Text('FAQ', style: TextStyle(fontFamily: 'Georgia', letterSpacing: 1)),
        content: const SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Do you ship internationally?', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Yes, we ship our luxury fragrances worldwide.'),
                SizedBox(height: 20),
                Text('What is your return policy?', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('We accept returns within 30 days of purchase if the bottle is sealed and unused.'),
                SizedBox(height: 20),
                Text('Are your perfumes vegan?', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Yes, all our fragrances are 100% vegan and cruelty-free.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('CLOSE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showContactForm(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        bool isSuccess = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(40),
                child: isSuccess 
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
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CLOSE'),
                        )
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CONTACT US', style: TextStyle(fontFamily: 'Georgia', fontSize: 24, letterSpacing: 2)),
                        const SizedBox(height: 10),
                        const Text('Send us a message and it will be delivered directly to our inbox.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 30),
                        TextField(
                          controller: nameController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: messageController,
                          enabled: !isSubmitting,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isSubmitting ? null : () async {
                              final name = nameController.text.trim();
                              final email = emailController.text.trim();
                              final msg = messageController.text.trim();
                              
                              if (name.isEmpty || email.isEmpty || msg.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all fields')));
                                return;
                              }

                              setState(() => isSubmitting = true);
                              
                              try {
                                final response = await http.post(
                                  Uri.parse('https://formsubmit.co/ajax/itxmunem7262@gmail.com'),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Accept': 'application/json',
                                  },
                                  body: jsonEncode({
                                    'name': name,
                                    'email': email,
                                    'message': msg,
                                    '_subject': 'New Contact from Perfuma Website',
                                  }),
                                );
                                
                                if (response.statusCode == 200) {
                                  setState(() {
                                    isSubmitting = false;
                                    isSuccess = true;
                                  });
                                } else {
                                  throw Exception('Failed to send');
                                }
                              } catch (e) {
                                setState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message. Please try again later.')));
                              }
                            },
                            child: isSubmitting 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('SEND MESSAGE', style: TextStyle(letterSpacing: 2)),
                          ),
                        ),
                      ],
                    ),
              ),
            );
          }
        );
      },
    );
  }

  List<Widget> _buildFooterColumns(bool isMobile, BuildContext context, double screenHeight) {
    return [
      // Brand Column
      Container(
        width: isMobile ? double.infinity : 250,
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
            Text(
              'The essence of elegance, bottled.\nCrafted in Paris for the modern soul.',
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
              style: TextStyle(color: Colors.grey[400], height: 1.6),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: const [
                _SocialIcon(icon: Icons.camera_alt),
                SizedBox(width: 16),
                _SocialIcon(icon: Icons.facebook),
                SizedBox(width: 16),
                _SocialIcon(icon: Icons.ondemand_video),
              ],
            )
          ],
        ),
      ),
      
      // Shop Links
      Container(
        width: isMobile ? double.infinity : 150,
        margin: EdgeInsets.only(bottom: isMobile ? 40 : 0),
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            const Text('SHOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 20),
            _FooterLink(
              text: 'All Perfumes', 
              onTap: () {
                setState(() => _selectedCategoryIndex = 0);
                _scrollToSection(screenHeight + 400);
              }
            ),
            _FooterLink(
              text: 'Best Sellers', 
              onTap: () {
                setState(() => _selectedCategoryIndex = 1);
                _scrollToSection(screenHeight + 400);
              }
            ),
            _FooterLink(
              text: 'New Arrivals', 
              onTap: () {
                setState(() => _selectedCategoryIndex = 2);
                _scrollToSection(screenHeight + 400);
              }
            ),
            _FooterLink(
              text: 'Gift Sets', 
              onTap: () {
                setState(() => _selectedCategoryIndex = 3);
                _scrollToSection(screenHeight + 400);
              }
            ),
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
            _FooterLink(text: 'About Us', onTap: () => _scrollToSection(screenHeight)),
            _FooterLink(text: 'Contact', onTap: () => _showContactForm(context)),
            _FooterLink(text: 'Careers', onTap: () => _showTextDialog(context, 'Careers', 'We are currently not hiring.')),
            _FooterLink(text: 'FAQ', onTap: () => _showFAQDialog(context)),
          ],
        ),
      ),

      // Newsletter
      SizedBox(
        width: isMobile ? double.infinity : 300,
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            const Text('NEWSLETTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 20),
            Text(
              'Subscribe to receive updates, access to exclusive deals, and more.',
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
                      fillColor: Colors.white.withOpacity(0.05),
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
                    onPressed: () async {
                      final email = _newsletterController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in your email to subscribe.'))
                        );
                        return;
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a proper email with @ (e.g. yourname@gmail.com).'))
                        );
                        return;
                      }
                      
                      try {
                        await http.post(
                          Uri.parse('https://formsubmit.co/ajax/itxmunem7262@gmail.com'),
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscribed successfully!')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to subscribe. Please try again later.')));
                        }
                      }
                    },
                    child: const Text('SUBSCRIBE'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    ];
  }

  Widget _buildCategoryTabs() {
    final categories = ['All Perfumes', 'Best Sellers', 'New Arrivals', 'Gift Sets'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: List.generate(categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.transparent,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _getProductsForCategory() {
    List<HoverProductCard> products = [];
    switch (_selectedCategoryIndex) {
      case 1: // Best Sellers
        products = const [
          HoverProductCard(image: 'images/rose.jpg', title: 'Velvet Rose', description: 'Damask Rose, Patchouli, Plum', basePrice: 4800),
          HoverProductCard(image: 'images/ocean.jpg', title: 'Ocean Breeze', description: 'Sea Salt, Driftwood, Sage', basePrice: 3300),
          HoverProductCard(image: 'images/amber.jpg', title: 'Forest & Spice', description: 'Amber, Cedarwood, Cinnamon', basePrice: 4200),
          HoverProductCard(image: 'images/vanilla.jpg', title: 'Vanille Royale', description: 'Madagascar Vanilla, Orchid', basePrice: 3900),
        ];
        break;
      case 2: // New Arrivals
        products = const [
          HoverProductCard(image: 'images/peach.jpg', title: 'Peach Blossom', description: 'White Peach, Magnolia, Vanilla', basePrice: 3400),
          HoverProductCard(image: 'images/sandalwood.jpg', title: 'Sandalwood Noir', description: 'Dark Sandalwood, Vetiver', basePrice: 4600),
          HoverProductCard(image: 'images/citrus.jpg', title: 'Citrus Fleur', description: 'Bergamot, Neroli, Lemon', basePrice: 3100),
          HoverProductCard(image: 'images/greentea.jpg', title: 'Matcha Zen', description: 'Green Tea, Bamboo, Bergamot', basePrice: 3200),
        ];
        break;
      case 3: // Gift Sets
        products = const [
          HoverProductCard(image: 'images/giftset_signature.jpg', title: 'The Signature Collection', description: 'Our Top 3 Perfumes Set', basePrice: 12500),
          HoverProductCard(image: 'images/giftset_travel.jpg', title: 'Travel Miniatures', description: '5 Mini Vials For On The Go', basePrice: 8500),
          HoverProductCard(image: 'images/giftset_holiday.jpg', title: 'Holiday Exclusive', description: 'Perfume & Scented Candle', basePrice: 9900),
        ];
        break;
      default: // All Perfumes
        products = const [
          HoverProductCard(image: 'images/floral.jpg', title: 'Perfuma Florale', description: 'Rose, Jasmine, White Musk', basePrice: 3500),
          HoverProductCard(image: 'images/amber.jpg', title: 'Forest & Spice', description: 'Amber, Cedarwood, Cinnamon', basePrice: 4200),
          HoverProductCard(image: 'images/citrus.jpg', title: 'Citrus Fleur', description: 'Bergamot, Neroli, Lemon', basePrice: 3100),
          HoverProductCard(image: 'images/minimal.jpg', title: 'Aether Minimal', description: 'Clean Cotton, White Tea', basePrice: 3800),
          HoverProductCard(image: 'images/ocean.jpg', title: 'Ocean Breeze', description: 'Sea Salt, Driftwood, Sage', basePrice: 3300),
          HoverProductCard(image: 'images/vanilla.jpg', title: 'Vanille Royale', description: 'Madagascar Vanilla, Orchid', basePrice: 3900),
          HoverProductCard(image: 'images/leather.jpg', title: 'Oud & Leather', description: 'Dark Oud, Rich Leather, Smoke', basePrice: 4900),
          HoverProductCard(image: 'images/greentea.jpg', title: 'Matcha Zen', description: 'Green Tea, Bamboo, Bergamot', basePrice: 3200),
          HoverProductCard(image: 'images/lavender.jpg', title: 'Lavender Night', description: 'French Lavender, Vanilla, Musk', basePrice: 3600),
          HoverProductCard(image: 'images/rose.jpg', title: 'Velvet Rose', description: 'Damask Rose, Patchouli, Plum', basePrice: 4800),
          HoverProductCard(image: 'images/sandalwood.jpg', title: 'Sandalwood Noir', description: 'Dark Sandalwood, Vetiver, Pepper', basePrice: 4600),
          HoverProductCard(image: 'images/peach.jpg', title: 'Peach Blossom', description: 'White Peach, Magnolia, Vanilla', basePrice: 3400),
        ];
        break;
    }
    
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      products = products.where((p) => p.title.toLowerCase().contains(query) || p.description.toLowerCase().contains(query)).toList();
    }
    
    if (products.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(
            child: Text('No fragrances found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ),
        )
      ];
    }
    
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? MobileNavDrawer(scrollToSection: _scrollToSection, screenHeight: screenHeight) : null,
      endDrawer: const CartDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            elevation: 2,
            toolbarHeight: 80,
            title: const Text(
              'Perfuma',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 28,
                letterSpacing: 4,
                color: Colors.black,
              ),
            ),
            actions: [
              // Nav Links (Hidden on small screens)
              if (!isMobile)
                Row(
                  children: [
                    _NavButton(title: 'Home', onTap: () => _scrollToSection(0)),
                    _NavButton(title: 'Story', onTap: () => _scrollToSection(screenHeight)),
                    _NavButton(title: 'Collections', onTap: () => _scrollToSection(screenHeight + 400)),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                      onPressed: () => _scrollToSection(screenHeight + 400),
                      child: const Text('SHOP NOW', style: TextStyle(letterSpacing: 1)),
                    ),
                  ],
                ),
              const SizedBox(width: 20),
              // Cart Icon with Badge
              ValueListenableBuilder<List<CartItem>>(
                valueListenable: cartNotifier,
                builder: (context, cart, child) {
                  int totalItems = cart.fold(0, (sum, item) => sum + item.quantity);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black, size: 28),
                        onPressed: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                      ),
                      if (totalItems > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFc9a063),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$totalItems',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
              const SizedBox(width: 20),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 1. Hero Section Carousel
                SizedBox(
                  height: 600,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final imageIndex = index % _heroImages.length;
                          return Image.asset(
                            _heroImages[imageIndex],
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        },
                      ),
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'The Essence of Elegance',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 56,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                    shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Discover signature scents crafted for the modern soul.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white, width: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                  ),
                                  onPressed: () => _scrollToSection(screenHeight + 400),
                                  child: const Text(
                                    'EXPLORE COLLECTION',
                                    style: TextStyle(letterSpacing: 2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2. Brand Story
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
                  color: Colors.white,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        children: [
                          const Text(
                            'OUR STORY',
                            style: TextStyle(
                              color: Color(0xFFc9a063),
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'A Legacy of Craftsmanship',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 40,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Founded in Paris, Perfuma Fragrances brings together the world\'s finest ingredients to create perfumes that are both timeless and contemporary. Each bottle is a masterpiece of design, holding within it a symphony of meticulously blended notes. We believe a perfume is more than a scent—it is an Perfuma you wear.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Featured Collections
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                  color: const Color(0xFFfaf9f6),
                  child: Column(
                    children: [
                      const Text(
                        'FEATURED FRAGRANCES',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildCategoryTabs(),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 40,
                            mainAxisSpacing: 40,
                            children: _getProductsForCategory(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 4. Testimonials
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
                  color: Colors.white,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: const Column(
                        children: [
                          Icon(Icons.format_quote, color: Color(0xFFc9a063), size: 60),
                          SizedBox(height: 20),
                          Text(
                            '"Perfuma Florale is nothing short of a masterpiece. It captures the essence of a blooming garden at dawn. Truly mesmerizing and elegant."',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontStyle: FontStyle.italic,
                              fontSize: 28,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 30),
                          Text(
                            '- VOGUE MAGAZINE',
                            style: TextStyle(
                              letterSpacing: 2,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. Attractive Footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 60),
                  color: const Color(0xFF111111),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 800;
                          return isMobile
                              ? Column(
                                  children: _buildFooterColumns(isMobile, context, screenHeight),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildFooterColumns(isMobile, context, screenHeight),
                                );
                        },
                      ),
                      const SizedBox(height: 60),
                      Divider(color: Colors.grey[800]),
                      const SizedBox(height: 20),
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
                                onTap: () => _showTextDialog(context, 'Privacy Policy', 'Your privacy is important to us...'),
                                child: Text('Privacy Policy', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ),
                              const SizedBox(width: 24),
                              InkWell(
                                onTap: () => _showTextDialog(context, 'Terms of Service', 'By using our website you agree...'),
                                child: Text('Terms of Service', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MOBILE NAVIGATION DRAWER
// -----------------------------------------------------------------------------
class MobileNavDrawer extends StatelessWidget {
  final Function(double) scrollToSection;
  final double screenHeight;

  const MobileNavDrawer({super.key, required this.scrollToSection, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            color: const Color(0xFFfaf9f6),
            child: const Center(
              child: Text(
                'Perfuma',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 28,
                  letterSpacing: 4,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('HOME', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              scrollToSection(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('OUR STORY', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              scrollToSection(screenHeight);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_florist_outlined),
            title: const Text('COLLECTIONS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              scrollToSection(screenHeight + 400);
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              onPressed: () {
                Navigator.pop(context);
                scrollToSection(screenHeight + 400);
              },
              child: const Text('SHOP NOW', style: TextStyle(letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}


class ShimmerImage extends StatelessWidget {
  final String imagePath;
  const ShimmerImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return frame == null
            ? Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.white,
                child: Container(color: Colors.white, width: double.infinity, height: double.infinity),
              )
            : child;
      },
    );
  }
}

// -----------------------------------------------------------------------------
// CART DRAWER
// -----------------------------------------------------------------------------
class CartDrawer extends StatelessWidget {
  const CartDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width > 500 ? 450 : MediaQuery.of(context).size.width,
      backgroundColor: Colors.white,
      child: ValueListenableBuilder<List<CartItem>>(
        valueListenable: cartNotifier,
        builder: (context, cart, child) {
          double total = 0;
          for (var item in cart) {
            String numericPrice = item.price.replaceAll(RegExp(r'[^0-9]'), '');
            if (numericPrice.isNotEmpty) {
              total += int.parse(numericPrice) * item.quantity;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
                color: const Color(0xFFfaf9f6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('YOUR CART', style: TextStyle(fontFamily: 'Georgia', fontSize: 24, letterSpacing: 2)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 28), 
                      onPressed: () => Navigator.pop(context)
                    ),
                  ],
                ),
              ),
              Expanded(
                child: cart.isEmpty
                    ? const Center(
                        child: Text('Your cart is empty.', style: TextStyle(color: Colors.grey, fontSize: 16))
                      )
                    : ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          return Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  padding: const EdgeInsets.all(8),
                                  color: const Color(0xFFfaf9f6),
                                  child: ShimmerImage(imagePath: item.image),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Georgia')),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              final list = List<CartItem>.from(cartNotifier.value);
                                              list.removeAt(index);
                                              cartNotifier.value = list;
                                            },
                                            child: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(item.price, style: const TextStyle(color: Color(0xFFc9a063), fontSize: 16)),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, size: 16),
                                                  onPressed: () {
                                                    final list = List<CartItem>.from(cartNotifier.value);
                                                    if (list[index].quantity > 1) {
                                                      list[index].quantity--;
                                                    } else {
                                                      list.removeAt(index);
                                                    }
                                                    cartNotifier.value = list;
                                                  },
                                                ),
                                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                IconButton(
                                                  icon: const Icon(Icons.add, size: 16),
                                                  onPressed: () {
                                                    final list = List<CartItem>.from(cartNotifier.value);
                                                    list[index].quantity++;
                                                    cartNotifier.value = list;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                          Text('Rs. ${total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Proceeding to secure checkout...'),
                                backgroundColor: Color(0xFFc9a063),
                              )
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('SECURE CHECKOUT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMPONENTS
// -----------------------------------------------------------------------------
class _NavButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _NavButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _FooterLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(color: Colors.grey[400], fontSize: 15),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  
  const _SocialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class HoverProductCard extends StatefulWidget {
  final String image;
  final String title;
  final String description;
  final int basePrice;

  const HoverProductCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.basePrice,
  });

  @override
  State<HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<HoverProductCard> {
  bool _isHovered = false;

  void _showDetails() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          backgroundColor: Colors.white,
          child: Container(
            width: 800,
            height: isMobile ? null : 500,
            child: isMobile 
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildDetailsContent(isMobile),
                  ),
                )
              : Row(
                  children: _buildDetailsContent(isMobile),
                ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDetailsContent(bool isMobile) {
    final imageWidget = Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: ShimmerImage(imagePath: widget.image),
    );

    final detailsWidget = Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontFamily: 'Georgia', fontSize: 32),
              ),
              const SizedBox(height: 10),
              Text(
                widget.price,
                style: const TextStyle(
                  color: Color(0xFFc9a063),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                widget.description,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Detailed Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Text(
                'Experience the luxurious blend of ${widget.title}. Crafted with the finest ingredients, this fragrance offers a long-lasting and unforgettable scent profile perfect for any occasion. Designed in Paris, loved globally.',
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  onPressed: () {
                    addToCart(widget.title, widget.basePrice, widget.image);
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.title} added to cart!'),
                        backgroundColor: const Color(0xFFc9a063),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('ADD TO CART', style: TextStyle(letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close, size: 28, color: Colors.black54),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );

    if (isMobile) {
      return [
        SizedBox(height: 300, child: imageWidget),
        SizedBox(height: 450, child: detailsWidget),
      ];
    } else {
      return [
        Expanded(child: imageWidget),
        Expanded(child: detailsWidget),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _showDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -10.0 : 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  child: Container(
                    color: Colors.white,
                    child: ShimmerImage(imagePath: widget.image),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.price,
                      style: const TextStyle(
                        color: Color(0xFFc9a063),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





