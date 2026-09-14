import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  // Find start of CartDrawer
  int start = content.indexOf('class CartDrawer extends StatelessWidget {');
  // Find next class
  int end = content.indexOf('class _NavButton', start);
  
  if (start != -1 && end != -1) {
    String before = content.substring(0, start);
    String after = content.substring(end);
    
    String drawerCode = r'''class CartDrawer extends StatelessWidget {
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
              int total = 0;
              for (var item in cart) {
                total += item.basePrice * item.quantity;
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
                                          Text(formatPrice(item.basePrice, currency), style: const TextStyle(color: Color(0xFFc9a063), fontSize: 16)),
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
                              Text(formatPrice(total, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
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
          );
        }
      ),
    );
  }
}
''';

    content = before + drawerCode + after;
  }
  
  content = content.replaceAll(
    '              ValueListenableBuilder<String>(\n                valueListenable: currencyNotifier,\n                builder: (context, currency, _) => Text(\n                  formatPrice(widget.basePrice, currency),\n                  style: const TextStyle(\n                    color: Color(0xFFc9a063),\n                    fontSize: 24,\n                    fontWeight: FontWeight.bold,\n                  ),\n                ),\n              )\n              const SizedBox(height: 30),', 
    '              ValueListenableBuilder<String>(\n                valueListenable: currencyNotifier,\n                builder: (context, currency, _) => Text(\n                  formatPrice(widget.basePrice, currency),\n                  style: const TextStyle(\n                    color: Color(0xFFc9a063),\n                    fontSize: 24,\n                    fontWeight: FontWeight.bold,\n                  ),\n                ),\n              ),\n              const SizedBox(height: 30),'
  );
  
  content = content.replaceAll('widget.price,', 'widget.basePrice,');
  content = content.replaceAll('widget.price', 'widget.basePrice');
  
  File('lib/main.dart').writeAsStringSync(content);
}
