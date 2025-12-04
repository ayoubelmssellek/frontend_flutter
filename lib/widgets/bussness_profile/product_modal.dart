// lib/pages/restaurant_profile/widgets/product_modal.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/core/cart_storage.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/models/shop_model.dart';
import 'package:food_app/providers/cart/cart_provider.dart';

class ProductModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  final Shop shop;

  const ProductModal({
    super.key,
    required this.product,
    required this.shop,
  });

  @override
  ConsumerState<ProductModal> createState() => _ProductModalState();
}

class _ProductModalState extends ConsumerState<ProductModal> with SingleTickerProviderStateMixin {
  int _quantity = 1;
  bool _isBusinessOpen = true;
  final Map<String, int> _selectedExtras = {};
  final ScrollController _scrollController = ScrollController();
  bool _showHeader = false;
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _headerHeightAnimation;
  bool _hasLoadedExistingState = false;
  bool _isUpdatingCart = false;
  bool _isProductInCart = false;

  @override
  void initState() {
    super.initState();
    _checkBusinessHours();
    _initializeExtras();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _headerHeightAnimation = Tween<double>(
      begin: 0,
      end: 60,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scrollController.addListener(() {
      final shouldShowHeader = _scrollController.offset > 30;
      if (shouldShowHeader != _showHeader) {
        setState(() {
          _showHeader = shouldShowHeader;
        });
        
        if (_showHeader) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedExistingState) {
      _loadExistingProductState();
      _hasLoadedExistingState = true;
    }
  }

  void _checkBusinessHours() {
    setState(() {
      _isBusinessOpen = widget.shop.isOpen;
    });
  }

  void _initializeExtras() {
    final childProducts = widget.product['child_products'];
    if (childProducts != null && childProducts is List) {
      for (final extra in childProducts) {
        _selectedExtras[extra['id'].toString()] = 0;
      }
    }
  }

  void _loadExistingProductState() {
    final cartService = ref.read(cartServiceProvider);
    final productId = widget.product['id'].toString();
    final businessOwnerId = widget.shop.id.toString();
    
    setState(() {
      _isProductInCart = cartService.isProductInCart(productId, businessOwnerId);
    });
    
    final existingItem = cartService.getItemWithExtras(productId, businessOwnerId);
    
    if (existingItem != null) {
      final existingQuantity = existingItem['quantity'] ?? 1;
      setState(() {
        _quantity = existingQuantity;
      });
      
      final selectedExtras = existingItem['selected_extras'] as List<dynamic>?;
      if (selectedExtras != null && selectedExtras.isNotEmpty) {
        for (final extra in selectedExtras) {
          final extraId = extra['id'].toString();
          final quantity = extra['quantity'] ?? 1;
          if (_selectedExtras.containsKey(extraId)) {
            setState(() {
              _selectedExtras[extraId] = quantity;
            });
          }
        }
      }
    }
  }

  bool _hasExtras() {
    final childProducts = widget.product['child_products'];
    return childProducts != null && childProducts is List && childProducts.isNotEmpty;
  }

  List<dynamic> _getExtras() {
    return widget.product['child_products'] ?? [];
  }

  double _getBasePrice() {
    return double.tryParse(widget.product['price']?.toString() ?? '0.0') ?? 0.0;
  }

  double _getExtraPrice(String extraId) {
    final extras = _getExtras();
    final extra = extras.firstWhere(
      (e) => e['id'].toString() == extraId,
      orElse: () => {},
    );
    return double.tryParse(extra['price']?.toString() ?? '0.0') ?? 0.0;
  }

  double _getTotalPrice() {
    double total = _getBasePrice();
    
    _selectedExtras.forEach((extraId, quantity) {
      if (quantity > 0) {
        total += _getExtraPrice(extraId) * quantity;
      }
    });
    
    return total * _quantity;
  }

  int _getSelectedExtrasCount() {
    return _selectedExtras.values.where((quantity) => quantity > 0).length;
  }

  int _getTotalExtrasQuantity() {
    return _selectedExtras.values.fold(0, (sum, quantity) => sum + quantity);
  }

  bool _canSelectMoreExtras() {
    return _getTotalExtrasQuantity() < 5;
  }

  bool _canIncreaseExtra(String extraId) {
    final currentQuantity = _selectedExtras[extraId] ?? 0;
    return _canSelectMoreExtras() && currentQuantity < 5;
  }

  void _toggleExtra(String extraId) {
    if (!_selectedExtras.containsKey(extraId)) return;
    
    final currentQuantity = _selectedExtras[extraId] ?? 0;
    
    if (currentQuantity > 0) {
      setState(() {
        _selectedExtras[extraId] = 0;
      });
    } else if (_canSelectMoreExtras()) {
      setState(() {
        _selectedExtras[extraId] = 1;
      });
    }
  }

  void _increaseExtraQuantity(String extraId) {
    if (_canIncreaseExtra(extraId)) {
      setState(() {
        _selectedExtras[extraId] = (_selectedExtras[extraId] ?? 0) + 1;
      });
    }
  }

  void _decreaseExtraQuantity(String extraId) {
    final currentQuantity = _selectedExtras[extraId] ?? 0;
    if (currentQuantity > 1) {
      setState(() {
        _selectedExtras[extraId] = currentQuantity - 1;
      });
    } else if (currentQuantity == 1) {
      setState(() {
        _selectedExtras[extraId] = 0;
      });
    }
  }

  Future<void> _updateCart() async {
    if (!_isBusinessOpen || _isUpdatingCart) return;
    
    setState(() {
      _isUpdatingCart = true;
    });
    
    try {
      final cartService = ref.read(cartServiceProvider);
      final productId = widget.product['id'].toString();
      final businessOwnerId = widget.shop.id.toString();
      final uniqueKey = '${productId}_$businessOwnerId';
      
      if (_quantity == 0) {
        await cartService.removeItem(uniqueKey);
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
      
      final selectedExtrasList = [];
      _selectedExtras.forEach((extraId, quantity) {
        if (quantity > 0) {
          final extra = _getExtras().firstWhere(
            (e) => e['id'].toString() == extraId,
            orElse: () => {},
          );
          if (extra.isNotEmpty) {
            final extraWithQuantity = Map<String, dynamic>.from(extra);
            extraWithQuantity['quantity'] = quantity;
            selectedExtrasList.add(extraWithQuantity);
          }
        }
      });
      
      final itemData = {
        'id': productId,
        'product_name': widget.product['product_name'] ?? widget.product['name'] ?? 'Unknown Product',
        'price': _getBasePrice(),
        'quantity': _quantity,
        'image': widget.product['product_image']?.toString() ?? widget.product['image']?.toString() ?? '',
        'restaurantName': widget.shop.name,
        'business_owner_id': businessOwnerId,
        'selected_extras': selectedExtrasList,
      };
      if (kDebugMode) {
        if (kDebugMode) {
          print('🛒 Updating cart with item: $itemData');
          print('🛒 Product details: ${widget.product}');
        }
      }
      if (cartService.cartItems.containsKey(uniqueKey)) {
        await cartService.updateItemWithData(uniqueKey, itemData);
      } else {
        await cartService.addItem(itemData, quantity: _quantity);
        setState(() {
          _isProductInCart = true;
        });
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingCart = false;
        });
      }
    }
  }

  String _getButtonText() {
    if (_quantity == 0) {
      return 'Remove';
    }
    
    if (_isProductInCart) {
      return 'Update';
    } else {
      return 'Add';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExtras = _hasExtras();
    final extras = _getExtras();
    final totalPrice = _getTotalPrice();
    final selectedExtrasCount = _getSelectedExtrasCount();
    final totalExtrasQuantity = _getTotalExtrasQuantity();
    final productName = widget.product['product_name'] ?? widget.product['name'] ?? 'Product';
    final buttonText = _getButtonText();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: hasExtras ? MediaQuery.of(context).size.height * 0.9 : _calculateNoExtrasHeight(),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _headerHeightAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        height: _headerHeightAnimation.value,
                        child: OverflowBox(
                          maxHeight: 60,
                          alignment: Alignment.topCenter,
                          child: Opacity(
                            opacity: _headerAnimation.value,
                            child: _buildHeader(context, productName),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  Expanded(
                    child: Stack(
                      children: [
                        CustomScrollView(
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _buildImageSection(context),
                            ),
                            
                            SliverToBoxAdapter(
                              child: _buildTitleSection(),
                            ),
                            
                            if (hasExtras) 
                              _buildExtrasSection(extras, selectedExtrasCount, totalExtrasQuantity),
                            
                            if (!hasExtras)
                              SliverToBoxAdapter(
                                child: _buildQuantitySection(buttonText),
                              ),

                            if (hasExtras)
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 120),
                              ),
                          ],
                        ),
                        
                        if (!_showHeader)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                splashRadius: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  if (hasExtras) _buildBottomSection(totalPrice, buttonText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String productName) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1 * _headerAnimation.value),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 24),
              onPressed: () => Navigator.pop(context),
              splashRadius: 20,
            ),
            
            Expanded(
              child: Center(
                child: Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  double _calculateNoExtrasHeight() {
    return 180 + 80 + 140 + 50;
  }

  Widget _buildImageSection(BuildContext context) {
    final imageUrl = widget.product['product_image']?.toString() ?? widget.product['image']?.toString() ?? '';
    final categoryName = widget.product['category_name'] ?? '';

    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            child: CustomNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: 'restaurant',
            ),
          ),
        ),
        
        if (categoryName.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFC63232).withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                categoryName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitleSection() {
    final productName = widget.product['product_name'] ?? widget.product['name'] ?? 'Product';
    final description = widget.product['description'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySection(String buttonText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: _isBusinessOpen ? () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      } : null,
                      color: _isBusinessOpen ? Colors.black87 : Colors.grey.shade400,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: _isBusinessOpen ? () => setState(() => _quantity++) : null,
                      color: _isBusinessOpen ? Colors.black87 : Colors.grey.shade400,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _isBusinessOpen
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC63232),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isUpdatingCart ? null : _updateCart,
                    child: _isUpdatingCart
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '$buttonText ${_quantity == 0 ? '' : '$_quantity for ${_getTotalPrice().toStringAsFixed(2)} DH'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Currently Unavailable',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  SliverList _buildExtrasSection(List<dynamic> extras, int selectedExtrasCount, int totalExtrasQuantity) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Would you like some extras?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final currentTotalExtras = _getTotalExtrasQuantity();
                      return Text(
                        'Choose a maximum of 5 extras total ($currentTotalExtras/5 selected)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
          
          final extraIndex = index - 1;
          if (extraIndex >= extras.length) return null;
          
          final extra = extras[extraIndex];
          final extraId = extra['id'].toString();
          final extraName = extra['variant_name'] ?? extra['product_name'] ?? 'Extra';
          final extraPrice = double.tryParse(extra['price']?.toString() ?? '0.0') ?? 0.0;
          final extraImage = extra['product_image']?.toString() ?? extra['image']?.toString() ?? '';
          final extraQuantity = _selectedExtras[extraId] ?? 0;
          final isSelected = extraQuantity > 0;
          final isLast = extraIndex == extras.length - 1;
          final canIncrease = _canIncreaseExtra(extraId);

          return Container(
            color: Colors.white,
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isBusinessOpen ? () => _toggleExtra(extraId) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Extra image
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade100,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CustomNetworkImage(
                                imageUrl: extraImage,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                placeholder: 'restaurant',
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Extra info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  extraName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isBusinessOpen ? Colors.black87 : Colors.grey.shade400,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+${extraPrice.toStringAsFixed(2)} DH',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isBusinessOpen ? Color(0xFFC63232) : Colors.grey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Quantity selector or selection indicator
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove, 
                                      size: 16, 
                                      color: _isBusinessOpen ? Colors.black87 : Colors.grey.shade400
                                    ),
                                    onPressed: _isBusinessOpen ? () => _decreaseExtraQuantity(extraId) : null,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '${_selectedExtras[extraId] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _isBusinessOpen ? Colors.black87 : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                  
                                  IconButton(
                                    icon: Icon(
                                      Icons.add, 
                                      size: 16, 
                                      color: _isBusinessOpen && canIncrease ? Colors.black87 : Colors.grey.shade400
                                    ),
                                    onPressed: _isBusinessOpen && canIncrease ? () => _increaseExtraQuantity(extraId) : null,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isBusinessOpen ? Colors.grey.shade400 : Colors.grey.shade300,
                                  width: 2,
                                ),
                                color: Colors.transparent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 88, right: 16),
                    child: Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        },
        childCount: extras.length + 1,
      ),
    );
  }

  Widget _buildBottomSection(double totalPrice, String buttonText) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: _isBusinessOpen ? () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      } : null,
                      color: _isBusinessOpen ? Colors.black87 : Colors.grey.shade400,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: _isBusinessOpen ? () => setState(() => _quantity++) : null,
                      color: _isBusinessOpen ? Colors.black87 : Colors.grey.shade400,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _isBusinessOpen
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC63232),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isUpdatingCart ? null : _updateCart,
                    child: _isUpdatingCart
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '$buttonText ${_quantity == 0 ? '' : '$_quantity for ${_getTotalPrice().toStringAsFixed(2)} DH'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Currently Unavailable',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}