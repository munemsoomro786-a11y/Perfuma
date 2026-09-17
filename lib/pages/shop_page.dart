import 'package:flutter/material.dart';
import '../main.dart';
import '../products.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';

class ShopPageScreen extends StatefulWidget {
  const ShopPageScreen({super.key});

  @override
  State<ShopPageScreen> createState() => _ShopPageScreenState();
}

class _ShopPageScreenState extends State<ShopPageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  @override
  void dispose() {
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
          padding: EdgeInsets.all(60.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 60, color: Colors.black26),
                SizedBox(height: 16),
                Text(
                  'No fragrances match your search.',
                  style: TextStyle(fontSize: 18, color: Colors.black54, fontFamily: 'Georgia'),
                ),
              ],
            ),
          ),
        )
      ];
    }

    return products.map((product) => HoverProductCard(product: product)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All Perfumes', 'Best Sellers', 'New Arrivals', 'Gift Sets'];

    return Scaffold(
      key: _scaffoldKey,
      appBar: NavbarWidget(scaffoldKey: _scaffoldKey, currentRoute: '/shop'),
      drawer: const MobileNavDrawerWidget(currentRoute: '/shop'),
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
                      'THE PERFUME COLLECTION',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 42,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Explore our full range of handcrafted luxury eau de parfums.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),

              // Search & Filter Controls
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
                color: Colors.white,
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      width: 500,
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search fragrances by name or scent profile...',
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
                          fillColor: const Color(0xFFF9F9F9),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
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

                    // Category Tabs
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: List.generate(categories.length, (index) {
                        return _ShopCategoryTabChip(
                          title: categories[index],
                          isSelected: _selectedCategoryIndex == index,
                          onTap: () => setState(() => _selectedCategoryIndex = index),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Product Grid
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
                color: const Color(0xFFfaf9f6),
                child: LayoutBuilder(
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
              ),

              // Footer
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopCategoryTabChip extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShopCategoryTabChip({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ShopCategoryTabChip> createState() => _ShopCategoryTabChipState();
}

class _ShopCategoryTabChipState extends State<_ShopCategoryTabChip> {
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
