import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/widgets/home_page/ShopCard.dart'; // Import the ShopCard

class SearchPage extends StatefulWidget {
  final List<dynamic> businesses;

  const SearchPage({super.key, required this.businesses});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredBusinesses = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _filteredBusinesses = widget.businesses;
  }

  // Map backend business owners data to shop format (UPDATED FOR NEW API)
  Map<String, dynamic> _mapBusinessToShop(dynamic business) {
    // Calculate if business is currently open
    final now = DateTime.now();
    final isOpen = _isBusinessOpen(
      business['opening_time']?.toString(), 
      business['closing_time']?.toString(), 
      now
    );
    
    // Get business type from the new API structure
    final businessType = business['business_type']?.toString() ?? 'General';
    
    // Get categories from the new API structure (list of strings)
    final categories = (business['categories'] as List<dynamic>? ?? [])
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toList();

    return {
      'id': business['id'].toString(),
      'name': business['business_name'] ?? 'Unknown Business',
      'image': business['avatar'], // Use avatar for profile image
      'rating': double.tryParse(business['rating']?.toString() ?? '0.0') ?? 0.0,
      'business_type': businessType, // Use the direct business_type field
      'isOpen': business['is_active'] == 1 && isOpen,
      'description': business['description'] ?? '',
      'location': business['location'] ?? '',
      'categories': categories, // List of category names
      'opening_time': business['opening_time'],
      'closing_time': business['closing_time'],
      'cover_image': business['cover_image'], // Use cover_image for cover
      'phone': business['number_phone'] ?? '',
      'is_active': business['is_active'] ?? 0,
    };
  }

  // ✅ FIXED: Helper method to check if business is currently open (24-hour format)
  bool _isBusinessOpen(String? openingTime, String? closingTime, DateTime now) {
    if (openingTime == null || closingTime == null) return true;
    
    try {
      // Parse opening time (assuming 24-hour format like "08:00:00" or "08:00")
      final openParts = openingTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      
      // Parse closing time (assuming 24-hour format)
      final closeParts = closingTime.split(':');
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);
      
      // Create DateTime objects for today with the business hours
      final openToday = DateTime(now.year, now.month, now.day, openHour, openMinute);
      DateTime closeToday = DateTime(now.year, now.month, now.day, closeHour, closeMinute);
      
      // Handle businesses that close after midnight (e.g., 23:00 to 03:00)
      if (closeToday.isBefore(openToday)) {
        closeToday = closeToday.add(const Duration(days: 1));
      }
      
      // Debug print to see what's happening
      print('🕒 SearchPage - Business Hours Check:');
      print('   Now: $now');
      print('   Open: $openToday (${openHour.toString().padLeft(2, '0')}:${openMinute.toString().padLeft(2, '0')})');
      print('   Close: $closeToday (${closeHour.toString().padLeft(2, '0')}:${closeMinute.toString().padLeft(2, '0')})');
      print('   Is Open: ${now.isAfter(openToday) && now.isBefore(closeToday)}');
      
      return now.isAfter(openToday) && now.isBefore(closeToday);
    } catch (e) {
      print('❌ SearchPage - Error parsing business hours: $e');
      print('   Opening time: $openingTime');
      print('   Closing time: $closingTime');
      return true; // If there's an error parsing, assume open
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Businesses'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Categories Filter
          _buildCategoriesFilter(),
          
          // Results Count
          _buildResultsCount(),
          
          // Businesses List
          _buildBusinessesList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for businesses, categories...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: _performSearch,
        ),
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    final allCategories = _getAllCategories();
    
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All Categories
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: _selectedCategory == 'All',
              label: const Text('All'),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = 'All';
                  _filterBusinesses();
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
            ),
          ),
          
          // Other Categories
          ...allCategories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _selectedCategory == category,
                label: Text(category),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                    _filterBusinesses();
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_filteredBusinesses.length} businesses found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessesList() {
    if (_filteredBusinesses.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No businesses found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or categories',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredBusinesses.length,
        itemBuilder: (context, index) {
          final business = _filteredBusinesses[index];
          // Map the business to shop format before passing to ShopCard
          final shop = _mapBusinessToShop(business);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShopCard(
              shop: shop, // Pass the mapped shop data to ShopCard
              onTap: () {
                _navigateToBusinessDetails(shop);
              },
            ),
          );
        },
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _filterBusinesses(query: query);
    });
  }

  void _filterBusinesses({String query = ''}) {
    List<dynamic> results = widget.businesses;

    // Filter by search query
    if (query.isNotEmpty) {
      results = results.where((business) {
        final name = business['business_name']?.toString().toLowerCase() ?? '';
        final description = business['description']?.toString().toLowerCase() ?? '';
        final location = business['location']?.toString().toLowerCase() ?? '';
        final businessType = business['business_type']?.toString().toLowerCase() ?? '';
        final categories = _getBusinessCategories(business);
        
        return name.contains(query.toLowerCase()) ||
            description.contains(query.toLowerCase()) ||
            location.contains(query.toLowerCase()) ||
            businessType.contains(query.toLowerCase()) ||
            categories.any((category) => category.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      results = results.where((business) {
        final categories = _getBusinessCategories(business);
        return categories.contains(_selectedCategory);
      }).toList();
    }

    setState(() {
      _filteredBusinesses = results;
    });
  }

  List<String> _getAllCategories() {
    final allCategories = <String>{};
    
    for (final business in widget.businesses) {
      final categories = _getBusinessCategories(business);
      allCategories.addAll(categories);
    }
    
    return allCategories.toList()..sort();
  }

  List<String> _getBusinessCategories(dynamic business) {
    // Get categories from the new API structure (list of strings)
    final categories = (business['categories'] as List<dynamic>? ?? [])
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toList();

    // If no categories, use business type
    if (categories.isEmpty) {
      final businessType = business['business_type']?.toString();
      return businessType != null && businessType.isNotEmpty ? [businessType] : ['General'];
    }
    
    return categories;
  }

  void _navigateToBusinessDetails(Map<String, dynamic> shop) {
    // Navigate to restaurant profile with the mapped shop data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantProfile(shop: shop, business: null),
      ),
    );
  }
}