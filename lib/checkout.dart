import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'main.dart';
import 'auth.dart';
import 'firestore_service.dart';
import 'email_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<User?> _ensureAuthForCheckout() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) return user;

    // 1. Try Anonymous Auth
    try {
      final anonUser = await FirebaseAuth.instance.signInAnonymously();
      if (anonUser.user != null) return anonUser.user;
    } catch (_) {}

    // 2. Try Silent Guest Account Login
    try {
      final guestUser = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'guest.checkout@perfuma.com',
        password: 'GuestCheckout123!',
      );
      if (guestUser.user != null) return guestUser.user;
    } catch (_) {
      try {
        final newGuest = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: 'guest.checkout@perfuma.com',
          password: 'GuestCheckout123!',
        );
        if (newGuest.user != null) return newGuest.user;
      } catch (_) {}
    }
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCart = cartNotifier.value.where((i) => i.isSelected).toList();
    if (selectedCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items selected for checkout.'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Ensure valid Firebase Auth session so Firestore Security Rules allow writing to orders collection
      User? user = await _ensureAuthForCheckout();
      final userId = user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final customerEmail = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : (user?.email ?? '');

      final db = FirebaseFirestore.instance;
      final orderId = db.collection('orders').doc().id;
      final totalPKR = selectedCart.fold(0, (total, item) => total + item.basePrice * item.quantity);

      final orderData = {
        'id': orderId,
        'userId': userId,
        'userEmail': customerEmail,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'items': selectedCart.map((i) => {
          'title': i.title,
          'basePrice': i.basePrice,
          'image': i.image,
          'quantity': i.quantity,
        }).toList(),
        'totalPKR': totalPKR,
        'paymentMethod': 'Cash on Delivery',
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 2. Save to global orders collection in Firestore (for Admin Panel)
      await db.collection('orders').doc(orderId).set(orderData);

      // If registered user, also save in user subcollection
      if (user != null && !user.isAnonymous && user.email != 'guest.checkout@perfuma.com') {
        await db.collection('users').doc(user.uid).collection('orders').doc(orderId).set(orderData);
      }

      // Always send EmailJS order notification (Admin Alert + Customer Email if provided)
      final currentCurrency = currencyNotifier.value;
      final emailTarget = customerEmail.isNotEmpty ? customerEmail : 'munemsoomro786@gmail.com';
      EmailService.sendOrderConfirmation(
        orderId: orderId.substring(0, 8).toUpperCase(),
        customerName: _nameController.text.trim(),
        customerEmail: emailTarget,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        totalAmount: formatPrice(totalPKR, currentCurrency),
        currency: currentCurrency,
        items: List<Map<String, dynamic>>.from(orderData['items'] as List),
      );

      if (!mounted) return;

      // 1. Show success dialog FIRST
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => _OrderSuccessDialog(orderId: orderId.substring(0, 8).toUpperCase()),
      );

      // 2. Remove ONLY purchased items from cart
      final remaining = cartNotifier.value.where((i) => !i.isSelected).toList();
      cartNotifier.value = remaining;
      if (user != null && !user.isAnonymous) {
        await FirestoreService.saveCart(remaining.map((i) => {
          'title': i.title,
          'basePrice': i.basePrice,
          'image': i.image,
          'quantity': i.quantity,
          'isSelected': i.isSelected,
        }).toList());
      }

      // 3. Navigate back to Home Page
      if (mounted) GoRouter.of(context).go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Image.asset('images/perfuma_logo.jpg', height: 40),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.black12, height: 1)),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: currencyNotifier,
        builder: (context, currency, _) {
          return ValueListenableBuilder<List<CartItem>>(
            valueListenable: cartNotifier,
            builder: (context, cart, _) {
              final selectedCart = cart.where((i) => i.isSelected).toList();
              if (selectedCart.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.black26),
                      const SizedBox(height: 16),
                      const Text('No items selected for checkout', style: TextStyle(fontSize: 18, color: Colors.black54)),
                      const SizedBox(height: 8),
                      const Text('Please select items from your cart to proceed.', style: TextStyle(fontSize: 14, color: Colors.black38)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => GoRouter.of(context).go('/'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                        child: const Text('VIEW CART / SHOP'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: 40),
                child: isMobile
                    ? Column(children: [_buildForm(), const SizedBox(height: 32), _buildOrderSummary(selectedCart, currency)])
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildForm()),
                          const SizedBox(width: 40),
                          Expanded(flex: 2, child: _buildOrderSummary(selectedCart, currency)),
                        ],
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Information', style: TextStyle(fontFamily: 'Georgia', fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Enter your details for Cash on Delivery', style: TextStyle(color: Colors.black45, fontSize: 14)),
          const SizedBox(height: 28),

          _buildField(_nameController, 'Full Name', Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null),
          const SizedBox(height: 16),

          _buildField(_phoneController, 'Phone Number', Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null),
          const SizedBox(height: 16),

          _buildField(_emailController, 'Email Address (Optional)', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),

          _buildField(_cityController, 'City', Icons.location_city_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your city' : null),
          const SizedBox(height: 16),

          _buildField(_addressController, 'Full Address', Icons.home_outlined,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your address' : null),
          const SizedBox(height: 28),

          // Payment method
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFc9a063), width: 2),
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFFc9a063).withValues(alpha: 0.05),
            ),
            child: const Row(
              children: [
                Icon(Icons.money, color: Color(0xFFc9a063), size: 28),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Pay when your order arrives', style: TextStyle(color: Colors.black45, fontSize: 13)),
                  ],
                ),
                Spacer(),
                Icon(Icons.check_circle, color: Color(0xFFc9a063)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a1a1a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('PLACE ORDER', style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.black38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFc9a063), width: 2)),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _buildOrderSummary(List<CartItem> cart, String currency) {
    final totalPKR = cart.fold(0, (total, item) => total + item.basePrice * item.quantity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Summary', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold)),
              Text('(${cart.length} ${cart.length == 1 ? "item" : "items"})', style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          ...cart.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(item.image, width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey.shade200)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Qty: ${item.quantity}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(formatPrice(item.basePrice * item.quantity, currency),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFc9a063))),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shipping', style: TextStyle(color: Colors.black54)),
              const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(formatPrice(totalPKR, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFc9a063))),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSuccessDialog extends StatelessWidget {
  final String orderId;
  const _OrderSuccessDialog({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFc9a063), shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Order Placed!', style: TextStyle(fontFamily: 'Georgia', fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Order #$orderId', style: const TextStyle(color: Colors.black45, fontSize: 14, letterSpacing: 1)),
            const SizedBox(height: 16),
            const Text(
              'Thank you for your order! Our team will contact you shortly to confirm your delivery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.6),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a1a1a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: const Text('CONTINUE SHOPPING', style: TextStyle(letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
