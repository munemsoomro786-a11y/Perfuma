import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFFc9a063), size: 22),
                  const SizedBox(width: 10),
                  const Text('My Orders', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(),

            // Orders List
            Flexible(
              child: user == null
                  ? const Center(child: Text('Please login to view orders'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('orders')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFFc9a063)));
                        }

                        final orders = snapshot.data?.docs ?? [];

                        if (orders.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long, size: 60, color: Colors.black12),
                                SizedBox(height: 16),
                                Text('No orders yet', style: TextStyle(color: Colors.black38, fontSize: 16)),
                                SizedBox(height: 8),
                                Text('Your order history will appear here', style: TextStyle(color: Colors.black26, fontSize: 13)),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final data = orders[index].data() as Map<String, dynamic>;
                            final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                            final orderId = (data['id'] as String? ?? '').substring(0, 8).toUpperCase();
                            final totalPKR = data['totalPKR'] ?? 0;
                            final status = data['status'] ?? 'confirmed';
                            final date = data['createdAt'] != null
                                ? (data['createdAt'] as Timestamp).toDate()
                                : DateTime.now();

                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                title: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(
                                          '${date.day}/${date.month}/${date.year}',
                                          style: const TextStyle(color: Colors.black45, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(formatPrice(totalPKR, 'PKR'),
                                            style: const TextStyle(color: Color(0xFFc9a063), fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: status == 'confirmed' ? Colors.green.shade50 : Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: status == 'confirmed' ? Colors.green.shade200 : Colors.orange.shade200),
                                          ),
                                          child: Text(
                                            status == 'confirmed' ? '✓ Confirmed' : status,
                                            style: TextStyle(
                                              color: status == 'confirmed' ? Colors.green.shade700 : Colors.orange.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                children: [
                                  const Divider(height: 16),
                                  // Delivery info
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.black38),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${data['name']} • ${data['phone']}\n${data['address']}, ${data['city']}',
                                          style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Items
                                  ...items.map((item) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.asset(
                                                item['image'] ?? '',
                                                width: 45,
                                                height: 45,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 45,
                                                  height: 45,
                                                  color: Colors.grey.shade100,
                                                  child: const Icon(Icons.image, color: Colors.black26),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(item['title'] ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                            ),
                                            Text('x${item['quantity']}', style: const TextStyle(color: Colors.black45)),
                                            const SizedBox(width: 8),
                                            Text(
                                              formatPrice((item['basePrice'] ?? 0) * (item['quantity'] ?? 1), 'PKR'),
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFc9a063), fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Payment: Cash on Delivery', style: TextStyle(color: Colors.black45, fontSize: 12)),
                                      Text('Total: ${formatPrice(totalPKR, 'PKR')}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
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
        ),
      ),
    );
  }
}
