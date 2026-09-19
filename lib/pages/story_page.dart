import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/navbar.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../main.dart';

class StoryPageScreen extends StatelessWidget {
  const StoryPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: NavbarWidget(scaffoldKey: scaffoldKey, currentRoute: '/story'),
      drawer: const MobileNavDrawerWidget(currentRoute: '/story'),
      endDrawer: const CartDrawer(),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Editorial Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                color: const Color(0xFFFAF9F6),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFc9a063), width: 1.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'OUR HERITAGE & CRAFTSMANSHIP',
                        style: TextStyle(
                          color: Color(0xFFc9a063),
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'The Art of French Perfumery',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 48,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Crafted in Paris with rare botanical essences for the modern soul.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Hero Editorial Showcase Section (Seamless Side-by-Side Grid)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 40),
                color: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isDesktop = constraints.maxWidth > 850;
                        return isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left Column: Perfume Bottle Image (No black bars, clean rounded image)
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                      height: 520,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 25,
                                            offset: const Offset(0, 10),
                                          )
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          'images/hero.jpg',
                                          fit: BoxFit.cover, // Fills container perfectly without black sidebars!
                                          alignment: Alignment.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 60),
                                  // Right Column: Story Narrative & Badges
                                  Expanded(
                                    flex: 6,
                                    child: _buildStoryNarrative(context),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  // Mobile Image Container
                                  Container(
                                    height: 380,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'images/hero.jpg',
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  _buildStoryNarrative(context),
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ),

              // 3. Perfumery Gallery Showcase (3 Columns)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                color: const Color(0xFFFAF9F6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        const Text(
                          'MASTER INGREDIENTS & ESSENCE',
                          style: TextStyle(
                            color: Color(0xFFc9a063),
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'From Grasse Fields to Crystal Bottles',
                          style: TextStyle(fontFamily: 'Georgia', fontSize: 36),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 800;
                            return isWide
                                ? Row(
                                    children: [
                                      Expanded(child: _buildGalleryCard('images/floral_hero.jpg', 'Grasse Roses & Jasmine', 'Hand-harvested at dawn in southern France')),
                                      const SizedBox(width: 30),
                                      Expanded(child: _buildGalleryCard('images/amber_hero.jpg', 'Rare Amber & Oud', 'Ethically sourced resinous woods for warmth')),
                                      const SizedBox(width: 30),
                                      Expanded(child: _buildGalleryCard('images/citrus_hero.jpg', 'Calabrian Bergamot', 'Crisp Mediterranean citrus top notes')),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildGalleryCard('images/floral_hero.jpg', 'Grasse Roses & Jasmine', 'Hand-harvested at dawn in southern France'),
                                      const SizedBox(height: 24),
                                      _buildGalleryCard('images/amber_hero.jpg', 'Rare Amber & Oud', 'Ethically sourced resinous woods for warmth'),
                                      const SizedBox(height: 24),
                                      _buildGalleryCard('images/citrus_hero.jpg', 'Calabrian Bergamot', 'Crisp Mediterranean citrus top notes'),
                                    ],
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Guiding Principles Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                color: Colors.white,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                        const Text(
                          'OUR GUIDING PRINCIPLES',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 30,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 35),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 650;
                            if (!isWide) {
                              return const Column(
                                children: [
                                  _ValueCard(
                                    icon: Icons.local_florist_outlined,
                                    title: '100% Vegan & Cruelty Free',
                                    description: 'Zero animal testing. Pure botanical formulations crafted with conscience.',
                                  ),
                                  SizedBox(height: 20),
                                  _ValueCard(
                                    icon: Icons.auto_awesome_outlined,
                                    title: 'Master Perfumer Formulations',
                                    description: 'Complex scent pyramids with top, heart, and base notes that evolve gracefully over 12+ hours.',
                                  ),
                                  SizedBox(height: 20),
                                  _ValueCard(
                                    icon: Icons.eco_outlined,
                                    title: 'Sustainable Packaging',
                                    description: 'Recyclable crystal glass bottles and FSC-certified minimalist eco cartons.',
                                  ),
                                  SizedBox(height: 20),
                                  _ValueCard(
                                    icon: Icons.card_giftcard_outlined,
                                    title: 'Signature Gift Presentation',
                                    description: 'Every bottle arrives wrapped in luxury silk paper with personalized wax seals.',
                                  ),
                                ],
                              );
                            }
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 30,
                              mainAxisSpacing: 30,
                              childAspectRatio: 1.6,
                              children: const [
                                _ValueCard(
                                  icon: Icons.local_florist_outlined,
                                  title: '100% Vegan & Cruelty Free',
                                  description: 'Zero animal testing. Pure botanical formulations crafted with conscience.',
                                ),
                                _ValueCard(
                                  icon: Icons.auto_awesome_outlined,
                                  title: 'Master Perfumer Formulations',
                                  description: 'Complex scent pyramids with top, heart, and base notes that evolve gracefully over 12+ hours.',
                                ),
                                _ValueCard(
                                  icon: Icons.eco_outlined,
                                  title: 'Sustainable Packaging',
                                  description: 'Recyclable crystal glass bottles and FSC-certified minimalist eco cartons.',
                                ),
                                _ValueCard(
                                  icon: Icons.card_giftcard_outlined,
                                  title: 'Signature Gift Presentation',
                                  description: 'Every bottle arrives wrapped in luxury silk paper with personalized wax seals.',
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 60),

                        // CTA Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F6),
                            border: Border.all(color: const Color(0xFFc9a063).withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Experience Perfuma Fragrances',
                                style: TextStyle(fontFamily: 'Georgia', fontSize: 26),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Find your signature scent today and enjoy complimentary sample vials with every purchase.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, height: 1.5),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                ),
                                onPressed: () => context.go('/shop'),
                                child: const Text('SHOP SIGNATURE SCENTS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Shared Footer
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryNarrative(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bottling Emotion, Creating Memories',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 32,
            color: Colors.black87,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Perfuma was born out of a passion for high perfumery and timeless elegance. Crafted in Paris, the fragrance capital of the world, our scents are designed to evoke deep emotional resonance and evoke memories that linger long after you leave the room.',
          style: TextStyle(
            fontSize: 16,
            height: 1.8,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'We collaborate with renowned master perfumers (Noses) who source rare natural essences from Grasse, Madagascar, and the Mediterranean coast. From hand-picked Jasmine to ethically extracted Oud, every ingredient undergoes rigorous quality evaluation.',
          style: TextStyle(
            fontSize: 16,
            height: 1.8,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 30),

        // Badges Row (Using Wrap for mobile screen protection!)
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _buildBadge('PARIS & PAKISTAN', 'Design & Hubs'),
            _buildBadge('12+ HOURS', 'Scent Longevity'),
            _buildBadge('100% PURE', 'Botanical Oils'),
          ],
        ),
        const SizedBox(height: 35),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc9a063),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          ),
          onPressed: () => context.go('/shop'),
          child: const Text('DISCOVER THE COLLECTION', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildBadge(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFc9a063), letterSpacing: 1),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildGalleryCard(String imagePath, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ValueCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFc9a063), size: 36),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
