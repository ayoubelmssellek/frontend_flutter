import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/pages/cart/checkout_page.dart';
import 'package:food_app/pages/home/client_home_page.dart';
import 'package:food_app/pages/home/profile_page/client_profile_page.dart';
import 'package:food_app/pages/restaurant_profile/restaurant_profile.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/widgets/home_page/ShopCard.dart';

// Color Palette from Home Page
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

String _tr(String key, String fallback) {
  try {
    final translation = key.tr();
    return translation == key ? fallback : translation;
  } catch (e) {
    return fallback;
  }
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Shop> _filteredShops = [];
  List<Shop> _allShops = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _allCategories = ['All']; // Initialize with 'All'

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get businesses from provider
      final businessOwnersAsync = ref.read(businessOwnersProvider);
      
      businessOwnersAsync.when(
        data: (data) {
          final businesses = data['data'] as List<dynamic>? ?? [];
          final shops = _convertToShopModels(businesses);
          
          if (mounted) {
            setState(() {
              _allShops = shops;
              _filteredShops = shops;
              _isLoading = false;
              _updateCategories(); // Update categories after loading shops
            });
          }
        },
        loading: () {
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        error: (error, stackTrace) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.toString();
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _updateCategories() {
    final categories = <String>{};
    
    for (final shop in _allShops) {
      // Add shop categories
      categories.addAll(shop.categories);
      
      // Also add business type if it's not empty and not 'General'
      if (shop.businessType.isNotEmpty && shop.businessType != 'General') {
        categories.add(shop.businessType);
      }
    }
    
    // Sort categories alphabetically
    final sortedCategories = categories.toList()..sort();
    
    if (mounted) {
      setState(() {
        _allCategories = ['All'] + sortedCategories;
      });
    }
  }

  void _refreshData() async {
    // Invalidate provider to force refresh
    ref.invalidate(businessOwnersProvider);
    await _loadBusinesses();
  }

  List<Shop> _convertToShopModels(List<dynamic> businesses) {
    return businesses
        .map((business) {
          try {
            return Shop.fromJson(business);
          } catch (e) {
            return null;
          }
        })
        .where((shop) => shop != null && shop.id != 0)
        .cast<Shop>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for updates
    final businessOwnersAsync = ref.watch(businessOwnersProvider);
    
    // Listen for changes in the provider
    if (businessOwnersAsync.hasValue && businessOwnersAsync.value != null) {
      final data = businessOwnersAsync.value!;
      final businesses = data['data'] as List<dynamic>? ?? [];
      final shops = _convertToShopModels(businesses);
      
      // Update shops if they've changed
      if (!_listEquals(shops, _allShops)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _allShops = shops;
              _filteredShops = shops;
              _isLoading = false;
              _updateCategories(); // Update categories when shops change
            });
          }
        });
      }
    }

    return Scaffold(
   appBar: AppBar(
        title: Text(
          _tr('search_page.title', 'Search Businesses'),
          style: const TextStyle(
            color: black,
            fontWeight: FontWeight.w700,
          ),
        ),
        
         flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryYellow, accentYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: black),
     
      ),

      backgroundColor: greyBg,
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildMainContent(),
      bottomNavigationBar: _buildBottomNavigationBar(1),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(secondaryRed),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _tr('search_page.loading_businesses', 'Loading businesses...'),
            style: const TextStyle(
              fontSize: 16,
              color: greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: secondaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: secondaryRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _tr('search_page.loading_error', 'Failed to load businesses'),
              style: const TextStyle(
                fontSize: 18,
                color: black,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: greyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(_tr('common.retry', 'Retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryRed,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_allShops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryYellow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: primaryYellow,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _tr('search_page.no_businesses_available', 'No businesses available'),
                style: const TextStyle(
                  fontSize: 18,
                  color: black,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _tr('search_page.try_again_later', 'Please try again later'),
                style: const TextStyle(
                  fontSize: 14,
                  color: greyText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryYellow, accentYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: _tr('search_page.hint', 'Search for businesses, categories...'),
            prefixIcon: const Icon(Icons.search_rounded, color: primaryYellow),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: greyText),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: const TextStyle(color: greyText),
          ),
          style: const TextStyle(
            color: black,
            fontWeight: FontWeight.w500,
          ),
          onChanged: _performSearch,
        ),
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    return Container(
      color: white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: _allCategories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _selectedCategory == category,
                label: Text(
                  category,
                  style: TextStyle(
                    color: _selectedCategory == category ? white : black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                    _filterShops();
                  });
                },
                backgroundColor: lightGrey,
                selectedColor: secondaryRed,
                checkmarkColor: white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResultsCount() {
    return Container(
      color: white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: primaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_filteredShops.length}${_tr("search_page.businesses_found", " businesses found")}',
              style: const TextStyle(
                fontSize: 14,
                color: black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (_filteredShops.isNotEmpty && _allShops.isNotEmpty)
            Text(
              '${((_filteredShops.length / _allShops.length) * 100).toInt()}%${_tr("search_page.of_total", " of total")}',
              style: const TextStyle(
                fontSize: 12,
                color: greyText,
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
        child: Container(
          color: greyBg,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    color: white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: primaryYellow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _tr('search_page.no_businesses_found', 'No businesses found'),
                  style: const TextStyle(
                    fontSize: 18,
                    color: black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _tr('search_page.try_different_keywords', 'Try different keywords or categories'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: greyText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _searchController.clear();
                      _filteredShops = _allShops;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryRed,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(_tr('search_page.clear_filters', 'Clear Filters')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        color: greyBg,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: _filteredShops.length,
          itemBuilder: (context, index) {
            final shop = _filteredShops[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ShopCard(
                shop: shop,
                onTap: () {
                  _navigateToBusinessDetails(shop);
                },
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
      results = results.where((shop) {
        final searchQuery = query.toLowerCase();
        
        return shop.name.toLowerCase().contains(searchQuery) ||
            (shop.description?.toLowerCase().contains(searchQuery) ?? false) ||
            (shop.location?.toLowerCase().contains(searchQuery) ?? false) ||
            shop.businessType.toLowerCase().contains(searchQuery) ||
            shop.categories.any((category) => category.toLowerCase().contains(searchQuery));
      }).toList();
    }

    // Filter by category (except when 'All' is selected)
    if (_selectedCategory != 'All') {
      results = results.where((shop) {
        // Check if shop has the selected category
        if (shop.categories.contains(_selectedCategory)) {
          return true;
        }
        // Also check business type
        if (shop.businessType == _selectedCategory) {
          return true;
        }
        return false;
      }).toList();
    }

    setState(() {
      _filteredShops = results;
    });
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

  bool _listEquals(List<Shop> list1, List<Shop> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  Widget _buildBottomNavigationBar(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ClientHomePage()),
              (route) => false,
            );
          } else if (index == 1) {
            // Already on search page
            if (!_isLoading && _errorMessage != null) {
              _refreshData();
            }
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: white,
        selectedItemColor: secondaryRed,
        unselectedItemColor: greyText,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentIndex == 0 
                    ? secondaryRed.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_rounded,
                size: 22,
                color: currentIndex == 0 ? secondaryRed : greyText,
              ),
            ),
            label: _tr('home_page.home','Home'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentIndex == 1 
                    ? secondaryRed.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 22,
                color: currentIndex == 1 ? secondaryRed : greyText,
              ),
            ),
            label: _tr('home_page.search','Search'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentIndex == 2 
                    ? secondaryRed.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_cart_rounded,
                size: 22,
                color: currentIndex == 2 ? secondaryRed : greyText,
              ),
            ),
            label: _tr('home_page.cart','Cart'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: currentIndex == 3 
                    ? secondaryRed.withOpacity(0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 22,
                color: currentIndex == 3 ? secondaryRed : greyText,
              ),
            ),
            label: _tr('home_page.profile','Profile'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}