import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_config.dart';
import 'package:go_router/go_router.dart';
import 'products.dart';
import 'auth.dart';
import 'firestore_service.dart';
import 'checkout.dart';
import 'admin_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/home_page.dart';
import 'pages/shop_page.dart';
import 'pages/story_page.dart';
import 'pages/reviews_page.dart';
import 'pages/contact_page.dart';
import 'pages/cart_page.dart';
import 'widgets/navbar.dart';
import 'widgets/footer.dart';
import 'widgets/mobile_drawer.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePageScreen(),
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopPageScreen(),
    ),
    GoRoute(
      path: '/story',
      builder: (context, state) => const StoryPageScreen(),
    ),
    GoRoute(
      path: '/reviews',
      builder: (context, state) => const ReviewsPageScreen(),
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactPageScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartPageScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        final product = allProducts.firstWhere((p) => p.id == id, orElse: () => allProducts.first);
        return ProductDetailsScreen(product: product);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: FirebaseConfig.options);
  _initFirebaseSync();
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
  bool isSelected;

  CartItem({
    required this.title,
    required this.basePrice,
    required this.image,
    this.quantity = 1,
    this.isSelected = true,
  });
}

final ValueNotifier<List<CartItem>> cartNotifier = ValueNotifier([]);
final ValueNotifier<String> currencyNotifier = ValueNotifier('PKR');
final ValueNotifier<Set<String>> wishlistNotifier = ValueNotifier({});

void _initFirebaseSync() {
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      final savedCart = await FirestoreService.loadCart();
      if (savedCart.isNotEmpty) {
        cartNotifier.value = savedCart
            .map((m) => CartItem(
                  title: m['title'] ?? '',
                  basePrice: m['basePrice'] ?? 0,
                  image: m['image'] ?? '',
                  quantity: m['quantity'] ?? 1,
                  isSelected: m['isSelected'] ?? true,
                ))
            .toList();
      }
      wishlistNotifier.value = await FirestoreService.loadWishlist();
    } else {
      wishlistNotifier.value = {};
    }
  });

  cartNotifier.addListener(() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await FirestoreService.saveCart(cartNotifier.value
          .map((i) => {
                'title': i.title,
                'basePrice': i.basePrice,
                'image': i.image,
                'quantity': i.quantity,
                'isSelected': i.isSelected,
              })
          .toList());
    }
  });
}

String formatPrice(int basePricePKR, String currency) {
  if (currency == 'USD') {
    return '\$${(basePricePKR * 0.0036).toStringAsFixed(2)}';
  } else if (currency == 'EUR') {
    return '€${(basePricePKR * 0.0033).toStringAsFixed(2)}';
  }
  return 'Rs. ${basePricePKR.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}

void addToCart(String title, int basePrice, String image) {
  final cart = List<CartItem>.from(cartNotifier.value);
  int index = cart.indexWhere((item) => item.title == title);
  if (index >= 0) {
    cart[index].quantity++;
    cart[index].isSelected = true;
  } else {
    cart.add(CartItem(title: title, basePrice: basePrice, image: image, isSelected: true));
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
}

// -----------------------------------------------------------------------------
// SHIMMER IMAGE
// -----------------------------------------------------------------------------
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
      child: ValueListenableBuilder<String>(
        valueListenable: currencyNotifier,
        builder: (context, currency, child) {
          return ValueListenableBuilder<List<CartItem>>(
            valueListenable: cartNotifier,
            builder: (context, cart, child) {
              final selectedItems = cart.where((item) => item.isSelected).toList();
              int total = 0;
              for (var item in selectedItems) {
                total += item.basePrice * item.quantity;
              }
              final bool allSelected = cart.isNotEmpty && cart.every((i) => i.isSelected);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
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
                  if (cart.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: allSelected,
                            activeColor: const Color(0xFFc9a063),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: const BorderSide(color: Colors.black26, width: 1.5),
                            onChanged: (bool? val) {
                              final selectAll = val ?? false;
                              final updated = cart.map((i) {
                                i.isSelected = selectAll;
                                return i;
                              }).toList();
                              cartNotifier.value = updated;
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Select All (${selectedItems.length}/${cart.length} items)',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item.isSelected,
                                      activeColor: const Color(0xFFc9a063),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      side: const BorderSide(color: Colors.black26, width: 1.5),
                                      onChanged: (bool? val) {
                                        final list = List<CartItem>.from(cartNotifier.value);
                                        list[index].isSelected = val ?? false;
                                        cartNotifier.value = list;
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 75,
                                      height: 75,
                                      padding: const EdgeInsets.all(8),
                                      color: const Color(0xFFfaf9f6),
                                      child: ShimmerImage(imagePath: item.image),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Georgia')),
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
                                          const SizedBox(height: 6),
                                          Text(formatPrice(item.basePrice, currency), style: const TextStyle(color: Color(0xFFc9a063), fontSize: 15, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 10),
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
                                                      padding: const EdgeInsets.all(4),
                                                      constraints: const BoxConstraints(),
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
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add, size: 16),
                                                      padding: const EdgeInsets.all(4),
                                                      constraints: const BoxConstraints(),
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
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('${selectedItems.length} of ${cart.length} items selected', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                              Text(formatPrice(total, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedItems.isEmpty ? Colors.grey[400] : Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 22),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onPressed: selectedItems.isEmpty
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please select at least one perfume to checkout.'),
                                          backgroundColor: Colors.black87,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  : () {
                                      Navigator.pop(context);
                                      GoRouter.of(context).push('/checkout');
                                    },
                              child: Text(
                                selectedItems.isEmpty
                                    ? 'SELECT ITEMS TO CHECKOUT'
                                    : 'SECURE CHECKOUT (${selectedItems.length})',
                                style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        }
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HOVER PRODUCT CARD
// -----------------------------------------------------------------------------
class HoverProductCard extends StatefulWidget {
  final Product product;
  const HoverProductCard({super.key, required this.product});

  @override
  State<HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<HoverProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => GoRouter.of(context).push('/product/${widget.product.id}'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..translate(0.0, _isHovered ? -10.0 : 0.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  else
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      child: Container(color: Colors.white, child: ShimmerImage(imagePath: widget.product.image)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(widget.product.title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, color: Colors.black87)),
                        const SizedBox(height: 12),
                        Text(widget.product.description, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 15, letterSpacing: 1)),
                        const SizedBox(height: 20),
                        ValueListenableBuilder<String>(
                          valueListenable: currencyNotifier,
                          builder: (context, currency, _) => Text(formatPrice(widget.product.basePrice, currency), style: const TextStyle(color: Color(0xFFc9a063), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // ❤️ Wishlist Heart Button
        Positioned(
          top: 12,
          right: 12,
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: wishlistNotifier,
            builder: (context, wishlist, _) {
              final isWishlisted = wishlist.contains(widget.product.id);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      showDialog(context: context, builder: (c) => const AuthDialog());
                      return;
                    }
                    final updated = Set<String>.from(wishlistNotifier.value);
                    if (updated.contains(widget.product.id)) {
                      updated.remove(widget.product.id);
                    } else {
                      updated.add(widget.product.id);
                    }
                    wishlistNotifier.value = updated;
                    FirestoreService.toggleWishlist({
                      'id': widget.product.id,
                      'title': widget.product.title,
                      'basePrice': widget.product.basePrice,
                      'image': widget.product.image,
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isWishlisted ? const Color(0xFFc9a063) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
                    ),
                    child: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.white : Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// WISHLIST DIALOG WIDGET
// -----------------------------------------------------------------------------
class WishlistDialogWidget extends StatelessWidget {
  const WishlistDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFFc9a063), size: 22),
                  const SizedBox(width: 10),
                  const Text('My Wishlist', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: wishlistNotifier,
                builder: (context, wishlistIds, _) {
                  final items = allProducts.where((p) => wishlistIds.contains(p.id)).toList();
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border, size: 60, color: Colors.black12),
                          SizedBox(height: 16),
                          Text('No saved perfumes yet', style: TextStyle(color: Colors.black38, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Tap ❤️ on any perfume to save it', style: TextStyle(color: Colors.black26, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = items[index];
                      return ValueListenableBuilder<String>(
                        valueListenable: currencyNotifier,
                        builder: (context, currency, _) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(p.image, width: 60, height: 60, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey.shade100)),
                            ),
                            title: Text(p.title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 15, fontWeight: FontWeight.bold)),
                            subtitle: Text(formatPrice(p.basePrice, currency), style: const TextStyle(color: Color(0xFFc9a063), fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    addToCart(p.title, p.basePrice, p.image);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text('${p.title} added to cart!'),
                                      backgroundColor: const Color(0xFFc9a063),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                  ),
                                  child: const Text('Add', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.favorite, color: Color(0xFFc9a063), size: 22),
                                  onPressed: () async {
                                    final updated = Set<String>.from(wishlistNotifier.value);
                                    updated.remove(p.id);
                                    wishlistNotifier.value = updated;
                                    FirestoreService.toggleWishlist({'id': p.id, 'title': p.title, 'basePrice': p.basePrice, 'image': p.image});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PRODUCT DETAILS SCREEN
// -----------------------------------------------------------------------------
class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: NavbarWidget(scaffoldKey: _scaffoldKey, currentRoute: '/product'),
      drawer: const MobileNavDrawerWidget(currentRoute: '/product'),
      endDrawer: const CartDrawer(),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: isMobile 
                      ? Column(
                          children: _buildContent(context, isMobile),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildContent(context, isMobile),
                        ),
                  ),
                ),
              ),
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, bool isMobile) {
    return [
      Expanded(
        flex: isMobile ? 0 : 1,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 1.0,
              maxScale: 4.0,
              panEnabled: true,
              scaleEnabled: true,
              child: ShimmerImage(imagePath: widget.product.image),
            ),
          ),
        ),
      ),
      if (isMobile) const SizedBox(height: 30),
      Expanded(
        flex: isMobile ? 0 : 1,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.product.title,
                style: const TextStyle(fontFamily: 'Georgia', fontSize: 36),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: currencyNotifier, 
                builder: (context, currency, _) => Text(
                  formatPrice(widget.product.basePrice, currency), 
                  style: const TextStyle(color: Color(0xFFc9a063), fontSize: 28, fontWeight: FontWeight.bold)
                )
              ),
              const SizedBox(height: 30),
              Text(
                widget.product.description,
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              const Text(
                'Detailed Fragrance Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Text(
                'Experience the luxurious blend of ${widget.product.title}. Crafted with the finest ingredients, this fragrance offers a long-lasting and unforgettable scent profile perfect for any occasion. Designed in Paris, loved globally.',
                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6),
              ),
              const SizedBox(height: 40),
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
                    addToCart(widget.product.title, widget.product.basePrice, widget.product.image);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.product.title} added to cart!'),
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
      ),
    ];
  }
}
