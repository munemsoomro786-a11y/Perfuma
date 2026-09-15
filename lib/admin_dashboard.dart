import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'main.dart';
import 'products.dart';

const String kAdminEmail = 'munemsoomro786@gmail.com';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == kAdminEmail;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => GoRouter.of(context).go('/'),
          ),
          title: const Text('Admin Panel', style: TextStyle(color: Colors.black, fontFamily: 'Georgia')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_outlined, size: 80, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text('Access Denied', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
                const SizedBox(height: 12),
                const Text(
                  'This panel is restricted exclusively to the store owner.\nPlease login with the authorized administrator email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => GoRouter.of(context).go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('RETURN TO STORE'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => GoRouter.of(context).go('/'),
          tooltip: 'Back to Website',
        ),
        title: Row(
          children: [
            const Text(
              'PERFUMA',
              style: TextStyle(color: Colors.white, fontFamily: 'Georgia', fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFc9a063),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFc9a063),
          indicatorWeight: 3,
          labelColor: const Color(0xFFc9a063),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'ORDERS'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'PRODUCTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AdminOrdersTab(),
          _AdminProductsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: ORDERS MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────────
class _AdminOrdersTab extends StatelessWidget {
  const _AdminOrdersTab();

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String userId, String newStatus) async {
    try {
      final db = FirebaseFirestore.instance;
      // Update global orders
      await db.collection('orders').doc(orderId).update({'status': newStatus});
      // Update customer subcollection
      if (userId.isNotEmpty) {
        await db.collection('users').doc(userId).collection('orders').doc(orderId).update({'status': newStatus});
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order #$orderId marked as $newStatus'),
          backgroundColor: const Color(0xFFc9a063),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFc9a063)));
        }

        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 70, color: Colors.black26),
                SizedBox(height: 16),
                Text('No orders received yet', style: TextStyle(fontSize: 18, color: Colors.black45)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data() as Map<String, dynamic>;
            final orderId = data['id'] ?? orders[index].id;
            final shortId = (orderId as String).substring(0, orderId.length >= 8 ? 8 : orderId.length).toUpperCase();
            final customerName = data['name'] ?? 'Unknown Customer';
            final customerPhone = data['phone'] ?? '';
            final customerEmail = data['userEmail'] ?? '';
            final address = data['address'] ?? '';
            final city = data['city'] ?? '';
            final totalPKR = data['totalPKR'] ?? 0;
            final currentStatus = data['status'] ?? 'confirmed';
            final userId = data['userId'] ?? '';
            final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

            final date = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Georgia')),
                            Text('${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.black45, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ['confirmed', 'processing', 'shipped', 'delivered', 'cancelled'].contains(currentStatus)
                                  ? currentStatus
                                  : 'confirmed',
                              items: const [
                                DropdownMenuItem(value: 'confirmed', child: Text('✓ Confirmed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'processing', child: Text('⚙ Processing', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'shipped', child: Text('🚚 Shipped', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'delivered', child: Text('🎉 Delivered', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'cancelled', child: Text('✖ Cancelled', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                              ],
                              onChanged: (newVal) {
                                if (newVal != null && newVal != currentStatus) {
                                  _updateOrderStatus(context, orderId, userId, newVal);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Customer & Shipping Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CUSTOMER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('$customerPhone • $customerEmail', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DELIVERY ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text('$address, $city', style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text('Rs. $totalPKR', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFc9a063))),
                            const Text('Cash on Delivery', style: TextStyle(fontSize: 11, color: Colors.black45)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Items breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(4)),
                      child: Column(
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text('${item['quantity']}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFc9a063))),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text('Rs. ${(item['basePrice'] ?? 0) * (item['quantity'] ?? 1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: PRODUCTS MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────────
class _AdminProductsTab extends StatefulWidget {
  const _AdminProductsTab();

  @override
  State<_AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<_AdminProductsTab> {
  void _openAddProductDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController(text: 'images/hero.jpg');
    final categoryController = TextEditingController(text: 'Signature Collection');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Add New Perfume', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Perfume Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (PKR)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image Path or URL', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || priceController.text.trim().isEmpty) return;
              final newId = titleController.text.trim().toLowerCase().replaceAll(' ', '-');
              final newProduct = {
                'id': newId,
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
                'basePrice': int.tryParse(priceController.text.trim()) ?? 3500,
                'image': imageController.text.trim(),
                'category': categoryController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              };

              await FirebaseFirestore.instance.collection('products').doc(newId).set(newProduct);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('New Perfume added to Firestore database!'),
                  backgroundColor: Color(0xFFc9a063),
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text('ADD PRODUCT'),
          ),
        ],
      ),
    );
  }

  void _editProductDialog(Product p, {String? currentTitle, String? currentDesc, int? currentPrice, String? currentImage, String? currentCategory}) {
    final titleController = TextEditingController(text: currentTitle ?? p.title);
    final descController = TextEditingController(text: currentDesc ?? p.description);
    final priceController = TextEditingController(text: (currentPrice ?? p.basePrice).toString());
    final imageController = TextEditingController(text: currentImage ?? p.image);
    final categoryController = TextEditingController(text: currentCategory ?? p.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text('Edit Perfume: ${p.title}', style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Perfume Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Fragrance Notes / Description', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price in PKR', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image Asset or Web URL', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category (Best Sellers, New Arrivals, etc.)', border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newPrice = int.tryParse(priceController.text.trim()) ?? p.basePrice;
              await FirebaseFirestore.instance.collection('products').doc(p.id).set({
                'id': p.id,
                'title': titleController.text.trim(),
                'description': descController.text.trim(),
                'basePrice': newPrice,
                'image': imageController.text.trim(),
                'category': categoryController.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Perfume updated successfully in live database!'),
                  backgroundColor: Color(0xFFc9a063),
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text('SAVE CHANGES'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Catalog Inventory', style: TextStyle(fontSize: 20, fontFamily: 'Georgia', fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _openAddProductDialog,
                icon: const Icon(Icons.add),
                label: const Text('ADD NEW PERFUME'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a1a1a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              final firestoreDocs = snapshot.data?.docs ?? [];
              final Map<String, Map<String, dynamic>> dynamicProducts = {};
              for (final doc in firestoreDocs) {
                dynamicProducts[doc.id] = doc.data() as Map<String, dynamic>;
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: allProducts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = allProducts[index];
                  final dynamicData = dynamicProducts[p.id];
                  final title = dynamicData?['title'] as String? ?? p.title;
                  final desc = dynamicData?['description'] as String? ?? p.description;
                  final price = (dynamicData?['basePrice'] as num?)?.toInt() ?? p.basePrice;
                  final image = dynamicData?['image'] as String? ?? p.image;
                  final category = dynamicData?['category'] as String? ?? p.category;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(image, width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey.shade200)),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rs. $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFc9a063))),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Color(0xFFc9a063)),
                          tooltip: 'Edit Perfume Details',
                          onPressed: () => _editProductDialog(
                            p,
                            currentTitle: title,
                            currentDesc: desc,
                            currentPrice: price,
                            currentImage: image,
                            currentCategory: category,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
