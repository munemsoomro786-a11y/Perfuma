import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileNavDrawerWidget extends StatelessWidget {
  final String currentRoute;

  const MobileNavDrawerWidget({
    super.key,
    required this.currentRoute,
  });

  bool _isActive(String route) {
    if (route == '/') return currentRoute == '/';
    return currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Luxury Header
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF9F6),
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERFUMA',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 26,
                        letterSpacing: 4,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PARIS FRAGRANCES',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 26, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu Tiles
          _DrawerTile(
            icon: Icons.home_outlined,
            title: 'HOME',
            route: '/',
            isActive: _isActive('/'),
          ),
          _DrawerTile(
            icon: Icons.shopping_bag_outlined,
            title: 'SHOP COLLECTION',
            route: '/shop',
            isActive: _isActive('/shop'),
          ),
          _DrawerTile(
            icon: Icons.auto_stories_outlined,
            title: 'OUR STORY',
            route: '/story',
            isActive: _isActive('/story'),
          ),
          _DrawerTile(
            icon: Icons.star_outline_rounded,
            title: 'REVIEWS & PRAISE',
            route: '/reviews',
            isActive: _isActive('/reviews'),
          ),
          _DrawerTile(
            icon: Icons.contact_support_outlined,
            title: 'CONTACT & FAQ',
            route: '/contact',
            isActive: _isActive('/contact'),
          ),

          const Spacer(),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFc9a063),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                context.go('/shop');
              },
              child: const Text('EXPLORE CATALOGUE', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isActive;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFc9a063).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? const Color(0xFFc9a063) : Colors.black87),
        title: Text(
          title,
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFFc9a063) : Colors.black87,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
      ),
    );
  }
}
