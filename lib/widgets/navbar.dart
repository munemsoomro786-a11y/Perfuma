import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../auth.dart';
import '../orders.dart';
import '../admin_dashboard.dart';

class NavbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final String currentRoute;

  const NavbarWidget({
    super.key,
    this.scaffoldKey,
    required this.currentRoute,
  });

  @override
  Size get preferredSize => const Size.fromHeight(85);

  bool _isActive(String route) {
    if (route == '/') {
      return currentRoute == '/';
    }
    return currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1150;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.black, size: 28),
                onPressed: () {
                  scaffoldKey?.currentState?.openDrawer();
                },
              )
            : null,
        title: const PerfumaLogo(),
        actions: [
          // Desktop Navigation Links (Safe horizontal scroll container)
          if (!isMobile)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NavbarLink(title: 'HOME', route: '/', isActive: _isActive('/')),
                  _NavbarLink(title: 'SHOP', route: '/shop', isActive: _isActive('/shop')),
                  _NavbarLink(title: 'OUR STORY', route: '/story', isActive: _isActive('/story')),
                  _NavbarLink(title: 'REVIEWS', route: '/reviews', isActive: _isActive('/reviews')),
                  _NavbarLink(title: 'CONTACT & FAQ', route: '/contact', isActive: _isActive('/contact')),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFc9a063),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      elevation: 0,
                    ),
                    onPressed: () => context.go('/shop'),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 15),
                    label: const Text('EXPLORE SHOP', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),

          // Currency Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: currencyNotifier,
              builder: (context, currency, _) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currency,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black),
                    items: ['PKR', 'USD', 'EUR'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        currencyNotifier.value = newValue;
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // ❤️ Wishlist Icon
          ValueListenableBuilder<Set<String>>(
            valueListenable: wishlistNotifier,
            builder: (context, wishlist, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'My Wishlist',
                    icon: Icon(
                      wishlist.isNotEmpty ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: wishlist.isNotEmpty ? const Color(0xFFc9a063) : Colors.black87,
                      size: 24,
                    ),
                    onPressed: () {
                      if (FirebaseAuth.instance.currentUser == null) {
                        showDialog(context: context, builder: (c) => const AuthDialog());
                      } else {
                        showDialog(context: context, builder: (c) => const WishlistDialogWidget());
                      }
                    },
                  ),
                  if (wishlist.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFFc9a063), shape: BoxShape.circle),
                        child: Text('${wishlist.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              );
            },
          ),

          // User Account Button
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                return PopupMenuButton<String>(
                  tooltip: user.email ?? 'Account',
                  icon: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFc9a063),
                    child: Icon(Icons.person_outline, color: Colors.white, size: 18),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Signed in as', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(user.email ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    if (user.email == kAdminEmail)
                      const PopupMenuItem(
                        value: 'admin',
                        child: Row(children: [
                          Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFFc9a063)),
                          SizedBox(width: 10),
                          Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFc9a063))),
                        ]),
                      ),
                    const PopupMenuItem(
                      value: 'orders',
                      child: Row(children: [
                        Icon(Icons.receipt_long, size: 18),
                        SizedBox(width: 10),
                        Text('My Orders'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 10),
                        Text('Logout'),
                      ]),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await FirebaseAuth.instance.signOut();
                    } else if (value == 'orders') {
                      showDialog(context: context, builder: (c) => const OrderHistoryScreen());
                    } else if (value == 'admin') {
                      context.go('/admin');
                    }
                  },
                );
              }
              return OutlinedButton.icon(
                onPressed: () => showDialog(context: context, builder: (c) => const AuthDialog()),
                icon: const Icon(Icons.person_outline, size: 16, color: Colors.black),
                label: const Text('LOGIN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              );
            },
          ),

          // Shopping Bag Badge
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: cartNotifier,
            builder: (context, cart, child) {
              int totalItems = cart.fold(0, (sum, item) => sum + item.quantity);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Shopping Bag',
                    icon: Icon(
                      _isActive('/cart') ? Icons.shopping_bag : Icons.shopping_bag_outlined,
                      color: _isActive('/cart') ? const Color(0xFFc9a063) : Colors.black87,
                      size: 26,
                    ),
                    onPressed: () {
                      if (scaffoldKey?.currentState?.hasEndDrawer ?? false) {
                        scaffoldKey?.currentState?.openEndDrawer();
                      } else {
                        context.go('/cart');
                      }
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
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _NavbarLink extends StatefulWidget {
  final String title;
  final String route;
  final bool isActive;

  const _NavbarLink({
    required this.title,
    required this.route,
    required this.isActive,
  });

  @override
  State<_NavbarLink> createState() => _NavbarLinkState();
}

class _NavbarLinkState extends State<_NavbarLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.isActive || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => context.go(widget.route),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Helvetica',
                  letterSpacing: 2,
                  fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
                  color: highlighted ? const Color(0xFFc9a063) : Colors.black87,
                  fontSize: 13,
                ),
                child: Text(widget.title),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 2,
                width: highlighted ? 24 : 0,
                color: const Color(0xFFc9a063),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PerfumaLogo extends StatelessWidget {
  final double fontSize;

  const PerfumaLogo({
    super.key,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        border: Border.all(
          color: const Color(0xFFc9a063),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'PERFUMA',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontFamilyFallback: const ['Playfair Display', 'Cinzel', 'Baskerville', 'serif'],
          fontSize: fontSize,
          letterSpacing: 6.0,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111111),
        ),
      ),
    );
  }
}
