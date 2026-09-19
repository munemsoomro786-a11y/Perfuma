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
        centerTitle: isMobile,
        leading: isMobile
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.black, size: 28),
                onPressed: () {
                  scaffoldKey?.currentState?.openDrawer();
                },
              )
            : null,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: PerfumaLogo(isMobile: isMobile),
        ),
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

          // Currency Switcher (Sleek hoverable selector)
          _CurrencySelector(isMobile: isMobile),
          SizedBox(width: isMobile ? 2 : 8),

          // ❤️ Wishlist Icon
          ValueListenableBuilder<Set<String>>(
            valueListenable: wishlistNotifier,
            builder: (context, wishlist, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    padding: isMobile ? const EdgeInsets.all(6) : const EdgeInsets.all(8),
                    constraints: isMobile ? const BoxConstraints() : null,
                    tooltip: 'My Wishlist',
                    icon: Icon(
                      wishlist.isNotEmpty ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: wishlist.isNotEmpty ? const Color(0xFFc9a063) : Colors.black87,
                      size: isMobile ? 22 : 24,
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
                      right: isMobile ? 2 : 6,
                      top: isMobile ? 2 : 6,
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
          SizedBox(width: isMobile ? 2 : 8),

          // User Account Button
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                return PopupMenuButton<String>(
                  tooltip: user.email ?? 'Account',
                  icon: CircleAvatar(
                    radius: isMobile ? 14 : 16,
                    backgroundColor: const Color(0xFFc9a063),
                    child: Icon(Icons.person_outline, color: Colors.white, size: isMobile ? 16 : 18),
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
              return OutlinedButton(
                onPressed: () => showDialog(context: context, builder: (c) => const AuthDialog()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 14, vertical: isMobile ? 4 : 8),
                  minimumSize: Size.zero,
                ),
                child: Text('LOGIN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: isMobile ? 10 : 11)),
              );
            },
          ),
          SizedBox(width: isMobile ? 2 : 8),

          // Shopping Bag Badge
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: cartNotifier,
            builder: (context, cart, child) {
              int totalItems = cart.fold(0, (sum, item) => sum + item.quantity);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    padding: isMobile ? const EdgeInsets.all(6) : const EdgeInsets.all(8),
                    constraints: isMobile ? const BoxConstraints() : null,
                    tooltip: 'Shopping Bag',
                    icon: Icon(
                      _isActive('/cart') ? Icons.shopping_bag : Icons.shopping_bag_outlined,
                      color: _isActive('/cart') ? const Color(0xFFc9a063) : Colors.black87,
                      size: isMobile ? 22 : 26,
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
                      right: isMobile ? 2 : 4,
                      top: isMobile ? 2 : 4,
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
          SizedBox(width: isMobile ? 6 : 14),
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

class _CurrencySelector extends StatefulWidget {
  final bool isMobile;
  const _CurrencySelector({required this.isMobile});

  @override
  State<_CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<_CurrencySelector> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFc9a063);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: ValueListenableBuilder<String>(
        valueListenable: currencyNotifier,
        builder: (context, currency, _) {
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currency,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: widget.isMobile ? 16 : 18,
                color: _isHovered ? goldColor : Colors.black87,
              ),
              dropdownColor: Colors.white,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 4 : 8,
                vertical: widget.isMobile ? 2 : 4,
              ),
              items: ['PKR', 'USD', 'EUR'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: widget.isMobile ? 11 : 12,
                      letterSpacing: 0.5,
                      color: _isHovered ? goldColor : Colors.black87,
                    ),
                    child: Text(value),
                  ),
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
    );
  }
}

class PerfumaLogo extends StatefulWidget {
  final double fontSize;
  final bool isMobile;

  const PerfumaLogo({
    super.key,
    this.fontSize = 22,
    this.isMobile = false,
  });

  @override
  State<PerfumaLogo> createState() => _PerfumaLogoState();
}

class _PerfumaLogoState extends State<PerfumaLogo> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFc9a063);
    final bool highlighted = _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 2 : 8,
            vertical: widget.isMobile ? 2 : 4,
          ),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontFamilyFallback: const ['Cinzel', 'Playfair Display', 'Baskerville', 'serif'],
                  fontSize: widget.isMobile ? 18 : widget.fontSize,
                  letterSpacing: widget.isMobile ? 3.5 : 6.0,
                  fontWeight: FontWeight.bold,
                  color: highlighted ? goldColor : const Color(0xFF111111),
                ),
                child: const Text(
                  'PERFUMA',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 1,
                    width: highlighted ? (widget.isMobile ? 14 : 22) : (widget.isMobile ? 8 : 14),
                    color: goldColor,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'PARIS',
                      style: TextStyle(
                        fontFamily: 'Helvetica',
                        fontSize: widget.isMobile ? 7 : 8.5,
                        letterSpacing: widget.isMobile ? 2.2 : 3.0,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 1,
                    width: highlighted ? (widget.isMobile ? 14 : 22) : (widget.isMobile ? 8 : 14),
                    color: goldColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
