import 'package:flutter/material.dart';
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
  List<Shop> _allShops = [];
  String _selectedCategory = 'All';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Convert businesses to Shop models
    _allShops = _convertToShopModels(widget.businesses);
    _filteredShops = List.from(_allShops);
  }

  // Convert business data to Shop models
  List<Shop> _convertToShopModels(List<dynamic> businesses) {
    return businesses
        .map((business) => Shop.fromJson(business))
        .where((shop) => shop.id != 0) // Filter out invalid shops
        .toList();
  }

  // Refresh function
  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // In a real app, you would fetch new data here:
    // final newData = await yourApiService.fetchBusinesses();
    // setState(() {
    //   _allShops = _convertToShopModels(newData);
    //   _filterShops();
    // });

    // For now, just update the UI
    setState(() {
      _isRefreshing = false;
    });

    // You could show a snackbar to indicate refresh completed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_tr('search_page.refresh_complete', 'List updated')),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _tr('search_page.title', 'Search Businesses'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, 
              size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isRefreshing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepOrange.shade400),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Categories Filter
          _buildCategoriesFilter(),
          
          // Results Count and Sort
          _buildResultsHeader(),
          
          // Businesses List with Refresh
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
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _handleBottomNavTap(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        backgroundColor: Colors.white,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.home_outlined, size: 24),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.home_filled, size: 24),
            ),
            label: _tr('home_page.home', 'Home'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepOrange.withOpacity(0.1),
              ),
              child: const Icon(Icons.search, size: 22, color: Colors.deepOrange),
            ),
            label: _tr('search_page.search', 'Search'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4),
              child: Badge(
                smallSize: 8,
                backgroundColor: Colors.deepOrange,
                child: const Icon(Icons.shopping_cart_outlined, size: 24),
              ),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(4),
              child: Badge(
                smallSize: 8,
                backgroundColor: Colors.deepOrange,
                child: const Icon(Icons.shopping_cart, size: 24),
              ),
            ),
            label: _tr('home_page.cart', 'Cart'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.person_outline, size: 24),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.person, size: 24),
            ),
            label: _tr('home_page.profile', 'Profile'),
          ),
        ],
      ),
    );
  }

  void _handleBottomNavTap(int index) {
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
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, 
                color: Colors.grey.shade600, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _tr('search_page.hint', 
                      'Search restaurants, cuisines, dishes...'),
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: _performSearch,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear_rounded, 
                    size: 20, color: Colors.grey.shade500),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    final allCategories = _getAllCategories();
    
    return Container(
      height: 80,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 12),
            child: Text(
              _tr('search_page.filter_by', 'Filter by'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 16),
              children: [
                // All Categories
                _buildCategoryChip(
                  label: _tr('search_page.all_categories', 'All'),
                  isSelected: _selectedCategory == 'All',
                  onTap: () {
                    setState(() {
                      _selectedCategory = _tr('search_page.all_categories', 'All');
                      _filterShops();
                    });
                  },
                ),
                
                // Other Categories
                ...allCategories.map((category) {
                  return _buildCategoryChip(
                    label: category,
                    isSelected: _selectedCategory == category,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _filterShops();
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredShops.length} ${_tr("search_page.results_found", "results")}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    size: 20, color: Colors.grey.shade600),
                onPressed: _handleRefresh,
                tooltip: _tr('search_page.refresh', 'Refresh'),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Row(
                  children: [
                    Icon(Icons.sort_rounded, 
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _tr('search_page.sort', 'Sort'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        const Icon(Icons.sort_by_alpha_rounded, 
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(_tr('search_page.sort_name', 'Name (A-Z)')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rating',
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, 
                            size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(_tr('search_page.sort_rating', 'Highest Rated')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'distance',
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, 
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(_tr('search_page.sort_distance', 'Nearest First')),
                      ],
                    ),
                  ),
                ],
                onSelected: _sortShops,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessesList() {
    if (_filteredShops.isEmpty) {
      return Expanded(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.deepOrange,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _tr('search_page.no_results', 'No results found'),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _tr('search_page.try_different', 
                            'Try different keywords or select another category'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedCategory = 'All';
                          _filteredShops = List.from(_allShops);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _tr('search_page.clear_filters', 'Clear All Filters'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.deepOrange,
        backgroundColor: Colors.white,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20, top: 8),
          itemCount: _filteredShops.length,
          itemBuilder: (context, index) {
            final shop = _filteredShops[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ShopCard(
                shop: shop,
                onTap: () => _navigateToBusinessDetails(shop),
              ),
            );
          },
        ),
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _filterShops(query: query);
    });
  }

  void _filterShops({String query = ''}) {
    List<Shop> results = List.from(_allShops);

    // Filter by search query
    if (query.isNotEmpty) {
      final searchQuery = query.toLowerCase();
      results = results.where((shop) {
        return shop.name.toLowerCase().contains(searchQuery) ||
            (shop.description?.toLowerCase().contains(searchQuery) ?? false) ||
            (shop.location?.toLowerCase().contains(searchQuery) ?? false) ||
            shop.businessType.toLowerCase().contains(searchQuery) ||
            shop.categories.any((category) => 
                category.toLowerCase().contains(searchQuery));
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

  void _sortShops(String sortBy) {
    setState(() {
      switch (sortBy) {
        case 'name':
          _filteredShops.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'rating':
          _filteredShops.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'distance':
          // Assuming Shop model has a distance property
          // _filteredShops.sort((a, b) => a.distance.compareTo(b.distance));
          // For now, sort by name if distance isn't available
          _filteredShops.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
      
      // Show snackbar for user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr('search_page.sorted_by', 'Sorted by ') + 
            (sortBy == 'name' ? _tr('search_page.name', 'name') : 
             sortBy == 'rating' ? _tr('search_page.rating', 'rating') : 
             _tr('search_page.distance', 'distance')),
          ),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.deepOrange,
        ),
      );
    });
  }

  List<String> _getAllCategories() {
    final allCategories = <String>{};
    
    for (final shop in _allShops) {
      allCategories.addAll(shop.categories);
    }
    
    // If no categories found, extract from business types
    if (allCategories.isEmpty) {
      for (final shop in _allShops) {
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
          shop: shop,
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