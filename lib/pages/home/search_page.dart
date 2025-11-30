import 'package:flutter/material.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/widgets/home_page/ShopCard.dart';
import 'package:easy_localization/easy_localization.dart';


class SearchPage extends StatefulWidget {
  final List<dynamic> businesses;

  const SearchPage({super.key, required this.businesses});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

  String _tr(String key, String fallback) {
    try {
      final translation = key.tr();
      return translation == key ? fallback : translation;
    } catch (e) {
      return fallback;
    }
  }

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Shop> _filteredShops = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Convert businesses to Shop models
    _filteredShops = _convertToShopModels(widget.businesses);
  }

  // Convert business data to Shop models
  List<Shop> _convertToShopModels(List<dynamic> businesses) {
    return businesses
        .map((business) => Shop.fromJson(business))
        .where((shop) => shop.id != 0) // Filter out invalid shops
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tr('search_page.title', 'Search Businesses')),
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
      bottomNavigationBar: _buildBottomNavigationBar(1),
    );
  }

  Widget _buildBottomNavigationBar(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // Handle navigation based on index
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ClientHomePage()),
            );
          } else if (index == 1) {
            // Already on search page
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => CheckoutPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: _tr('home_page.home', 'Home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: _tr('search_page.title', 'Search'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: _tr('home_page.cart', 'Cart'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: _tr('home_page.profile', 'Profile'),
          ),
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
            hintText: _tr('search_page.hint', 'Search for businesses, categories...'),
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
              label:  Text(_tr('search_page.all_categories', 'All')),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = _tr('search_page.all_categories', 'All');
                  _filterShops();
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
                    _filterShops();
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
            '${_filteredShops.length}${_tr("search_page.businesses_found", " businesses found")}',
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
    if (_filteredShops.isEmpty) {
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
                _tr('search_page.no_businesses_found', 'No businesses found'),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tr('search_page.try_different_keywords', 'Try different keywords or categories'),
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
        itemCount: _filteredShops.length,
        itemBuilder: (context, index) {
          final shop = _filteredShops[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShopCard(
              shop: shop, // Pass the Shop model directly
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
      _filterShops(query: query);
    });
  }

  void _filterShops({String query = ''}) {
    List<Shop> results = _convertToShopModels(widget.businesses);

    // Filter by search query
    if (query.isNotEmpty) {
      results = results.where((shop) {
        final searchQuery = query.toLowerCase();
        
        return shop.name.toLowerCase().contains(searchQuery) ||
            (shop.description?.toLowerCase().contains(searchQuery) ?? false) ||
            (shop.location?.toLowerCase().contains(searchQuery) ?? false) ||
            shop.businessType.toLowerCase().contains(searchQuery) ||
            shop.categories.any((category) => category.toLowerCase().contains(searchQuery));
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      results = results.where((shop) {
        return shop.categories.contains(_selectedCategory);
      }).toList();
    }

    setState(() {
      _filteredShops = results;
    });
  }

  List<String> _getAllCategories() {
    final allCategories = <String>{};
    
    for (final shop in _convertToShopModels(widget.businesses)) {
      allCategories.addAll(shop.categories);
    }
    
    // If no categories found, extract from business types
    if (allCategories.isEmpty) {
      for (final shop in _convertToShopModels(widget.businesses)) {
        if (shop.businessType.isNotEmpty && shop.businessType != 'General') {
          allCategories.add(shop.businessType);
        }
      }
    }
    
    return allCategories.toList()..sort();
  }

  void _navigateToBusinessDetails(Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantProfile(
          shop: shop, // Convert Shop model to JSON for the profile page
          business: null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}