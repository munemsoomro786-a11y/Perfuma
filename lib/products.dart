class Product {
  final String id;
  final String title;
  final String description;
  final int basePrice;
  final String image;
  final String category;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.image,
    required this.category,
  });
}

const List<Product> allProducts = [
  Product(id: 'velvet-rose', title: 'Velvet Rose', description: 'Damask Rose, Patchouli, Plum', basePrice: 4800, image: 'images/rose.jpg', category: 'Best Sellers'),
  Product(id: 'ocean-breeze', title: 'Ocean Breeze', description: 'Sea Salt, Driftwood, Sage', basePrice: 3300, image: 'images/ocean.jpg', category: 'Best Sellers'),
  Product(id: 'forest-and-spice', title: 'Forest & Spice', description: 'Amber, Cedarwood, Cinnamon', basePrice: 4200, image: 'images/amber.jpg', category: 'Best Sellers'),
  Product(id: 'vanille-royale', title: 'Vanille Royale', description: 'Madagascar Vanilla, Orchid', basePrice: 3900, image: 'images/vanilla.jpg', category: 'Best Sellers'),
  
  Product(id: 'peach-blossom', title: 'Peach Blossom', description: 'White Peach, Magnolia, Vanilla', basePrice: 3400, image: 'images/peach.jpg', category: 'New Arrivals'),
  Product(id: 'sandalwood-noir', title: 'Sandalwood Noir', description: 'Dark Sandalwood, Vetiver', basePrice: 4600, image: 'images/sandalwood.jpg', category: 'New Arrivals'),
  Product(id: 'citrus-fleur', title: 'Citrus Fleur', description: 'Bergamot, Neroli, Lemon', basePrice: 3100, image: 'images/citrus.jpg', category: 'New Arrivals'),
  Product(id: 'matcha-zen', title: 'Matcha Zen', description: 'Green Tea, Bamboo, Bergamot', basePrice: 3200, image: 'images/greentea.jpg', category: 'New Arrivals'),
  
  Product(id: 'giftset-signature', title: 'The Signature Collection', description: 'Our Top 3 Perfumes Set', basePrice: 12500, image: 'images/giftset_signature.jpg', category: 'Gift Sets'),
  Product(id: 'giftset-travel', title: 'Travel Miniatures', description: '5 Mini Vials For On The Go', basePrice: 8500, image: 'images/giftset_travel.jpg', category: 'Gift Sets'),
  Product(id: 'giftset-holiday', title: 'Holiday Exclusive', description: 'Perfume & Scented Candle', basePrice: 9900, image: 'images/giftset_holiday.jpg', category: 'Gift Sets'),

  Product(id: 'perfuma-florale', title: 'Perfuma Florale', description: 'Rose, Jasmine, White Musk', basePrice: 3500, image: 'images/floral.jpg', category: 'All Perfumes'),
  Product(id: 'aether-minimal', title: 'Aether Minimal', description: 'Clean Cotton, White Tea', basePrice: 3800, image: 'images/minimal.jpg', category: 'All Perfumes'),
  Product(id: 'oud-and-leather', title: 'Oud & Leather', description: 'Dark Oud, Rich Leather, Smoke', basePrice: 4900, image: 'images/leather.jpg', category: 'All Perfumes'),
  Product(id: 'lavender-night', title: 'Lavender Night', description: 'French Lavender, Vanilla, Musk', basePrice: 3600, image: 'images/lavender.jpg', category: 'All Perfumes'),
];
