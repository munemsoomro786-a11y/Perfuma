import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  int start = content.indexOf('  Widget _buildCategoryTabs() {');
  int end = content.indexOf('  List<Widget> _getProductsForCategory() {', start);
  
  if (start != -1 && end != -1) {
    String before = content.substring(0, start);
    String after = content.substring(end);
    
    String searchBarCode = r'''  Widget _buildCategoryTabs() {
    final categories = ['All Perfumes', 'Best Sellers', 'New Arrivals', 'Gift Sets'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          Container(
            width: 400,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search fragrances by name or note...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: List.generate(categories.length, (index) {
              final isSelected = _selectedCategoryIndex == index;
              return InkWell(
                onTap: () => setState(() {
                  _selectedCategoryIndex = index;
                  _searchQuery = ''; // Reset search on category change
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.transparent,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

''';

    File('lib/main.dart').writeAsStringSync(before + searchBarCode + after);
  }
}
