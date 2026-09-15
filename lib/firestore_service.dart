import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ─── CART ────────────────────────────────────────────────────────────────

  static Future<void> saveCart(List<Map<String, dynamic>> cartItems) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = _db.collection('users').doc(user.uid).collection('cart');

    // Clear old cart first
    final existing = await cartRef.get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    // Write new cart
    for (final item in cartItems) {
      await cartRef.doc(item['title']).set(item);
    }
  }

  static Future<List<Map<String, dynamic>>> loadCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  static Future<void> clearCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final cartRef = _db.collection('users').doc(user.uid).collection('cart');
    final snap = await cartRef.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ─── WISHLIST ─────────────────────────────────────────────────────────────

  static Future<void> toggleWishlist(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(product['id']);

    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set(product);
    }
  }

  static Future<Set<String>> loadWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .get();

    return snap.docs.map((d) => d.id).toSet();
  }

  static Stream<Set<String>> wishlistStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({});

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }
}
