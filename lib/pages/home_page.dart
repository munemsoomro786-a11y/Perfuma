import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../main.dart';
import '../products.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
    super.dispose();
  }

  List<Widget> _getProductsForCategory() {
    List<Product> products = [];
    final categoryNames = ['All Perfumes', 'Best Sellers', 'New Arrivals', 'Gift Sets'];
    final selectedCategory = categoryNames[_selectedCategoryIndex];

    if (selectedCategory == 'All Perfumes') {
      products = allProducts.toList();
    } else {
      products = allProducts.where((p) => p.category == selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      products = products.where((p) =>
        p.title.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query)
      ).toList();
    }

    if (products.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(
            child: Text(
              'No fragrances found.',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
        )
      ];
    }

    return products.map((product) => HoverProductCard(product: product)).toList();
  }

  Widget _buildCategoryTabs() {
    final categories = ['All Perfumes', 'Best Sellers', 'New Arrivals', 'Gift Sets'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Search Input
          Container(
            width: 450,
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search fragrances by name or note...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFc9a063)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Category Pills
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(categories.length, (index) {
              return _CategoryTabChip(
                title: categories[index],
                isSelected: _selectedCategoryIndex == index,
                onTap: () => setState(() => _selectedCategoryIndex = index),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavbarWidget(scaffoldKey: _scaffoldKey, currentRoute: '/'),
      drawer: const MobileNavDrawerWidget(currentRoute: '/'),
      endDrawer: const CartDrawer(),
      body: SelectionArea(
        child: SingleChildScrollView(
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
                      color: Colors.black.withValues(alpha: 0.35),
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
                                'Discover signature scents crafted in Paris for the modern soul.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 40),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFc9a063),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                  elevation: 2,
                                ),
                                onPressed: () => context.go('/shop'),
                                child: const Text(
                                  'EXPLORE COLLECTION',
                                  style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
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

              // 2. Brand Story Highlight
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
                          'A Legacy of French Craftsmanship',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 40,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Founded in Paris, Perfuma Fragrances brings together the world\'s finest ingredients to create perfumes that are both timeless and contemporary. Each bottle is a masterpiece of design, holding within it a symphony of meticulously blended notes. We believe a perfume is more than a scent - it is an essence you wear.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.8,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 30),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          ),
                          onPressed: () => context.go('/story'),
                          child: const Text('READ OUR FULL STORY', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Featured Perfumes Collection (Full Grid with Search & Categories)
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
                    const SizedBox(height: 50),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: () => context.go('/shop'),
                      child: const Text('VIEW ALL IN SHOP', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // 4. Testimonials Highlight
              Container(
                padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
                color: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        const Icon(Icons.format_quote, color: Color(0xFFc9a063), size: 60),
                        const SizedBox(height: 20),
                        const Text(
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
                        const SizedBox(height: 24),
                        const Text(
                          '- VOGUE MAGAZINE',
                          style: TextStyle(
                            letterSpacing: 2,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextButton(
                          onPressed: () => context.go('/reviews'),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('READ ALL CUSTOMER REVIEWS', style: TextStyle(color: Color(0xFFc9a063), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: Color(0xFFc9a063), size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Contact & FAQ Banner
              Container(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                color: const Color(0xFFfaf9f6),
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        'HAVE QUESTIONS?',
                        style: TextStyle(color: Color(0xFFc9a063), letterSpacing: 3, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'We are here to assist you.',
                        style: TextStyle(fontFamily: 'Georgia', fontSize: 32),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                        ),
                        onPressed: () => context.go('/contact'),
                        child: const Text('CONTACT US & FAQ', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Shared Footer
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTabChip extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTabChip({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryTabChip> createState() => _CategoryTabChipState();
}

class _CategoryTabChipState extends State<_CategoryTabChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeBg = widget.isSelected
        ? Colors.black
        : (_isHovered ? const Color(0xFFc9a063).withValues(alpha: 0.12) : Colors.transparent);
    final activeBorder = widget.isSelected
        ? Colors.black
        : (_isHovered ? const Color(0xFFc9a063) : Colors.grey[400]!);
    final activeText = widget.isSelected
        ? Colors.white
        : (_isHovered ? const Color(0xFFc9a063) : Colors.black87);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: activeBg,
            border: Border.all(color: activeBorder, width: widget.isSelected || _isHovered ? 1.5 : 1.0),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              color: activeText,
              fontWeight: widget.isSelected || _isHovered ? FontWeight.bold : FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
