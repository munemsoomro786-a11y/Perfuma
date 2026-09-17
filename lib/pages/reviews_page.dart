import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../main.dart';

class ReviewsPageScreen extends StatefulWidget {
  const ReviewsPageScreen({super.key});

  @override
  State<ReviewsPageScreen> createState() => _ReviewsPageScreenState();
}

class _ReviewsPageScreenState extends State<ReviewsPageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _reviewsList = [
    {
      'name': 'Sophia Laurent',
      'location': 'Paris, France',
      'rating': 5,
      'product': 'Perfuma Florale',
      'date': 'September 12, 2026',
      'comment': 'The scent longevity is unbelievable! I received so many compliments at a gala dinner. The jasmine and white rose notes are soft yet mesmerizing.',
    },
    {
      'name': 'Alexander Vance',
      'location': 'London, UK',
      'rating': 5,
      'product': 'Perfuma Amber Noir',
      'date': 'August 28, 2026',
      'comment': 'A dark, sultry scent with subtle vanilla and warm cedarwood. It feels super luxurious and stays on clothes all day. Worth every penny!',
    },
    {
      'name': 'Elena Rostova',
      'location': 'New York, USA',
      'rating': 5,
      'product': 'Citrus Breeze Eau De Parfum',
      'date': 'August 15, 2026',
      'comment': 'Clean, refreshing, and sophisticated. Perfect daytime fragrance for hot summer days.',
    },
    {
      'name': 'Hamza Malik',
      'location': 'Lahore, Pakistan',
      'rating': 5,
      'product': 'Minimalist Musk',
      'date': 'July 30, 2026',
      'comment': 'Fast delivery in Pakistan and pristine packaging. The bottle design is super sleek and minimalist. Smell is 10/10.',
    },
    {
      'name': 'Isabella Rossi',
      'location': 'Milan, Italy',
      'rating': 5,
      'product': 'Oceanic Mist',
      'date': 'July 14, 2026',
      'comment': 'Reminds me of summer drives along the Amalfi coast. Crisp marine notes combined with sea salt and ambergris.',
    },
  ];

  void _showAddReviewDialog() {
    final nameController = TextEditingController();
    final reviewController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              title: const Text('Write a Review', style: TextStyle(fontFamily: 'Georgia', fontSize: 24)),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFc9a063),
                            size: 28,
                          ),
                          onPressed: () => setStateModal(() => rating = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Your Review', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final comment = reviewController.text.trim();
                    if (name.isNotEmpty && comment.isNotEmpty) {
                      setState(() {
                        _reviewsList.insert(0, {
                          'name': name,
                          'location': 'Verified Customer',
                          'rating': rating,
                          'product': 'Perfuma Collection',
                          'date': 'Just now',
                          'comment': comment,
                        });
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you! Your review has been posted.')),
                      );
                    }
                  },
                  child: const Text('SUBMIT REVIEW'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavbarWidget(scaffoldKey: _scaffoldKey, currentRoute: '/reviews'),
      drawer: const MobileNavDrawerWidget(currentRoute: '/reviews'),
      endDrawer: const CartDrawer(),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                color: const Color(0xFFfaf9f6),
                child: Column(
                  children: [
                    const Text(
                      'CUSTOMER REVIEWS & PRAISE',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 40,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (_) => const Icon(Icons.star, color: Color(0xFFc9a063), size: 24)),
                        const SizedBox(width: 10),
                        const Text(
                          '4.9 out of 5 Stars (1,240+ Verified Reviews)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFc9a063),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      onPressed: _showAddReviewDialog,
                      icon: const Icon(Icons.rate_review_outlined, size: 20),
                      label: const Text('WRITE A REVIEW', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Reviews Grid
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 800;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 30,
                      childAspectRatio: isWide ? 1.7 : 1.4,
                      children: _reviewsList.map((rev) {
                        return Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: List.generate(
                                          rev['rating'] as int,
                                          (_) => const Icon(Icons.star, color: Color(0xFFc9a063), size: 18),
                                        ),
                                      ),
                                      Text(rev['date'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '"${rev['comment']}"',
                                    style: const TextStyle(fontSize: 16, height: 1.6, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFc9a063).withOpacity(0.2),
                                    child: Text(
                                      (rev['name'] as String)[0],
                                      style: const TextStyle(color: Color(0xFFc9a063), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rev['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(rev['location'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              // Bottom CTA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                color: const Color(0xFFfaf9f6),
                child: Column(
                  children: [
                    const Text('Ready to find your signature scent?', style: TextStyle(fontFamily: 'Georgia', fontSize: 26)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      ),
                      onPressed: () => context.go('/shop'),
                      child: const Text('SHOP NOW', style: TextStyle(letterSpacing: 2)),
                    ),
                  ],
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
