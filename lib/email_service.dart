import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _serviceId = 'service_mkiv3w5';
  static const String _templateId = 'template_nfod5b5';
  static const String _publicKey = '28BJrj0iawIrDnBPv';

  static Future<bool> sendOrderConfirmation({
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String phone,
    required String address,
    required String city,
    required String totalAmount,
    required String currency,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

      final orderItemsList = items.map((i) {
        final price = i['basePrice'] ?? 0;
        String rawNumeric;
        if (currency == 'USD') {
          rawNumeric = (price * 0.0036).toStringAsFixed(2);
        } else if (currency == 'EUR') {
          rawNumeric = (price * 0.0033).toStringAsFixed(2);
        } else {
          rawNumeric = '$price';
        }
        return {
          'name': i['title'] ?? '',
          'units': i['quantity'] ?? 1,
          'price': rawNumeric,
          'image': 'https://perfuma-fragrances.vercel.app/${i['image'] ?? 'images/floral_hero.jpg'}',
        };
      }).toList();

      // Clean numeric total without duplicate symbol if template adds $
      String cleanTotal = totalAmount.replaceAll(RegExp(r'[^\d.,]'), '').trim();

      final body = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'email': customerEmail,
          'order_id': orderId,
          'orders': orderItemsList,
          'logo': 'https://perfuma-fragrances.vercel.app/og-image.jpg',
          'cost': {
            'shipping': '0.00 (FREE)',
            'tax': '0.00',
            'total': cleanTotal.isNotEmpty ? cleanTotal : totalAmount,
          },
          'customer_name': customerName,
          'phone': phone,
          'address': '$address, $city',
        },
      };

      // 1. Send Customer Confirmation
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // 2. Send Admin Alert Email
      final adminBody = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'email': 'munemsoomro786@gmail.com',
          'order_id': '$orderId [ADMIN ALERT: New Order from $customerName]',
          'orders': orderItemsList,
          'logo': 'https://perfuma-fragrances.vercel.app/og-image.jpg',
          'cost': {
            'shipping': '0.00 (FREE)',
            'tax': '0.00',
            'total': cleanTotal.isNotEmpty ? cleanTotal : totalAmount,
          },
          'customer_name': 'ADMIN - Order for $customerName ($phone)',
          'phone': phone,
          'address': '$address, $city',
        },
      };

      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(adminBody),
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
