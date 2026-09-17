import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../main.dart';

class CartPageScreen extends StatelessWidget {
  const CartPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: NavbarWidget(scaffoldKey: scaffoldKey, currentRoute: '/cart'),
      drawer: const MobileNavDrawerWidget(currentRoute: '/cart'),
      endDrawer: const CartDrawer(),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                color: const Color(0xFFfaf9f6),
                child: const Column(
                  children: [
                    Text(
                      'YOUR SHOPPING BAG',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 38,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Review your selected items before proceeding to secure checkout.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),

              // Cart Content
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
                color: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ValueListenableBuilder<String>(
                      valueListenable: currencyNotifier,
                      builder: (context, currency, _) {
                        return ValueListenableBuilder<List<CartItem>>(
                          valueListenable: cartNotifier,
                          builder: (context, cart, _) {
                            final selectedItems = cart.where((i) => i.isSelected).toList();
                            int total = 0;
                            for (var item in selectedItems) {
                              total += item.basePrice * item.quantity;
                            }
                            final bool allSelected = cart.isNotEmpty && cart.every((i) => i.isSelected);

                            if (cart.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 60),
                                child: Column(
                                  children: [
                                    const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.black26),
                                    const SizedBox(height: 20),
                                    const Text('Your shopping bag is currently empty', style: TextStyle(fontFamily: 'Georgia', fontSize: 24)),
                                    const SizedBox(height: 12),
                                    const Text('Discover our luxury scents and add your favorites.', style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 30),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFc9a063),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                      ),
                                      onPressed: () => context.go('/shop'),
                                      child: const Text('EXPLORE COLLECTION', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: [
                                // Select All Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFfaf9f6),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: allSelected,
                                        activeColor: const Color(0xFFc9a063),
                                        onChanged: (bool? val) {
                                          final selectAll = val ?? false;
                                          final updated = cart.map((i) {
                                            i.isSelected = selectAll;
                                            return i;
                                          }).toList();
                                          cartNotifier.value = updated;
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Select All (${selectedItems.length}/${cart.length} items)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Items List
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cart.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final item = cart[index];
                                    return Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: item.isSelected,
                                            activeColor: const Color(0xFFc9a063),
                                            onChanged: (bool? val) {
                                              final list = List<CartItem>.from(cartNotifier.value);
                                              list[index].isSelected = val ?? false;
                                              cartNotifier.value = list;
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            width: 90,
                                            height: 90,
                                            padding: const EdgeInsets.all(8),
                                            color: const Color(0xFFfaf9f6),
                                            child: ShimmerImage(imagePath: item.image),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 6),
                                                Text(formatPrice(item.basePrice, currency), style: const TextStyle(color: Color(0xFFc9a063), fontWeight: FontWeight.bold, fontSize: 16)),
                                              ],
                                            ),
                                          ),
                                          // Quantity buttons
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, size: 18),
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add, size: 18),
                                                  onPressed: () {
                                                    final list = List<CartItem>.from(cartNotifier.value);
                                                    list[index].quantity++;
                                                    cartNotifier.value = list;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                            onPressed: () {
                                              final list = List<CartItem>.from(cartNotifier.value);
                                              list.removeAt(index);
                                              cartNotifier.value = list;
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 40),

                                // Order Summary Card
                                Container(
                                  padding: const EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFfaf9f6),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('ORDER SUMMARY', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Subtotal (${selectedItems.length} items)', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                                          Text(formatPrice(total, currency), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Shipping', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                          Text('COMPLIMENTARY', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const Divider(height: 40),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 55,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: selectedItems.isEmpty ? Colors.grey : Colors.black,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                          ),
                                          onPressed: selectedItems.isEmpty
                                              ? null
                                              : () => context.go('/checkout'),
                                          child: Text(
                                            'PROCEED TO CHECKOUT (${selectedItems.length})',
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
                      },
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
}
