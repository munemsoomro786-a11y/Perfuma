import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
content = content.replace("import 'package:http/http.dart' as http;", "import 'package:http/http.dart' as http;\nimport 'package:go_router/go_router.dart';\nimport 'products.dart';")

# 2. Update HoverProductCard class to accept Product
content = re.sub(
    r'class HoverProductCard extends StatefulWidget \{.*?\n.*?final String image;\n.*?final String title;\n.*?final String description;\n.*?final int basePrice;\n\n.*?const HoverProductCard\(\{.*?\}\);',
    'class HoverProductCard extends StatefulWidget {\n  final Product product;\n  const HoverProductCard({super.key, required this.product});',
    content,
    flags=re.DOTALL
)

# 3. Replace HoverProductCard constructor calls in _getProductsForCategory
content = re.sub(
    r'HoverProductCard\(image: (.*?), title: (.*?), description: (.*?), basePrice: (.*?)\)',
    r'/* replaced */',
    content
)

# Actually, we can rewrite _getProductsForCategory completely
get_products_replacement = """  List<Widget> _getProductsForCategory() {
    List<Product> products = [];
    final categoryNames = ['All Perfumes', 'Best Sellers', 'New Arrivals', 'Gift Sets'];
    final selectedCategory = categoryNames[_selectedCategoryIndex];
    
    if (selectedCategory == 'All Perfumes') {
      products = allProducts.where((p) => p.category == 'All Perfumes').toList();
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
  }"""

content = re.sub(r'  List<Widget> _getProductsForCategory\(\) \{.*?(?=  Widget _buildFooter\(\))', get_products_replacement + '\n\n', content, flags=re.DOTALL)

# 4. Update HoverProductCard internals
# _HoverProductCardState needs to use widget.product instead of widget.title etc.
content = content.replace('widget.image', 'widget.product.image')
content = content.replace('widget.title', 'widget.product.title')
content = content.replace('widget.description', 'widget.product.description')
content = content.replace('widget.basePrice', 'widget.product.basePrice')

# 5. Change onTap to context.go
content = re.sub(r'onTap: _showDetails,', r'onTap: () => context.go(\'/product/${widget.product.id}\'),', content)

# 6. Remove _showDetails and _buildDetailsContent
content = re.sub(r'  void _showDetails\(\) \{.*?(?=  @override\n  Widget build\(BuildContext context\))', '', content, flags=re.DOTALL)

# 7. Update MyApp
my_app_replacement = """final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        final product = allProducts.firstWhere((p) => p.id == id, orElse: () => allProducts.first);
        return ProductDetailsScreen(product: product);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Perfuma Fragrances',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFc9a063),
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        fontFamily: 'Helvetica',
      ),
      routerConfig: _router,
    );
  }
}"""

content = re.sub(r'class MyApp extends StatelessWidget \{.*?(?=class HomePage extends StatefulWidget)', my_app_replacement + '\n\n', content, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
