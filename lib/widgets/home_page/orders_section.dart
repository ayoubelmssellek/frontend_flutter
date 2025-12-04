import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/providers/auth_providers.dart';
import 'package:food_app/providers/order_providers.dart';
import 'package:food_app/models/client_order_model.dart';

// Color Palette from Logo
const Color primaryYellow = Color(0xFFCFC000);
const Color secondaryRed = Color(0xFFC63232);
const Color accentYellow = Color(0xFFFFD600);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color greyBg = Color(0xFFF8F8F8);
const Color greyText = Color(0xFF666666);
const Color lightGrey = Color(0xFFF0F0F0);

class OrdersSection extends ConsumerStatefulWidget {
  final VoidCallback onViewAllOrders;

  const OrdersSection({
    super.key,
    required this.onViewAllOrders,
  });

  @override
  ConsumerState<OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends ConsumerState<OrdersSection> {
  @override
  void initState() {
    super.initState();
    // Load orders in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClientOrders();
    });
  }

  Future<void> _loadClientOrders() async {
    try {
      // Check if user is logged in before loading orders
      final isLoggedIn = ref.read(authStateProvider);
      if (!isLoggedIn) {
        return;
      }
      
      final clientId = ref.read(clientIdProvider);
      if (clientId != 0) {
        await ref.read(clientOrdersProvider.notifier).loadClientOrders(clientId);
      }
    } catch (e) {
      // Silent error - section will be hidden
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientOrdersAsync = ref.watch(clientOrdersProvider);
    
    return clientOrdersAsync.when(
      data: (orders) {
        // Handle null or empty orders list
        if (orders == null || orders.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Filter out empty orders and show only pending/accepted
        final activeOrders = orders.where((order) => 
          order != null &&
          !order.isEmpty && 
          (order.status == OrderStatus.pending || order.status == OrderStatus.accepted)
        ).toList();

        // If no active orders, don't show anything
        if (activeOrders.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return _buildOrdersSectionContent(activeOrders);
      },
      loading: () {
        // Check if we have cached data to show while loading
        final cachedData = ref.read(clientOrdersProvider).value;
        
        // Handle null cached data
        if (cachedData == null || cachedData.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Filter cached orders
        final activeOrders = cachedData.where((order) => 
          order != null &&
          !order.isEmpty && 
          (order.status == OrderStatus.pending || order.status == OrderStatus.accepted)
        ).toList();
        
        if (activeOrders.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Show cached data with loading overlay
        return Stack(
          children: [
            _buildOrdersSectionContent(activeOrders),
            Positioned.fill(
              child: Container(
                color: white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(secondaryRed),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stack) {
        // Check if we have cached data to show on error
        final cachedData = ref.read(clientOrdersProvider).value;
        
        // Handle null cached data
        if (cachedData == null || cachedData.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Filter cached orders
        final activeOrders = cachedData.where((order) => 
          order != null &&
          !order.isEmpty && 
          (order.status == OrderStatus.pending || order.status == OrderStatus.accepted)
        ).toList();
        
        if (activeOrders.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Show cached data even if refresh failed
        return _buildOrdersSectionContent(activeOrders);
      },
    );
  }

  Widget _buildOrdersSectionContent(List<ClientOrder> activeOrders) {
    // Check if activeOrders is empty (should be handled by caller but adding safety check)
    if (activeOrders.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('home_page.my_orders'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: black,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onViewAllOrders,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: secondaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr('home_page.view_all'),
                          style: TextStyle(
                            color: secondaryRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: secondaryRed,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Horizontal Scroll for Active Orders - FIXED: Added null safety
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeOrders.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                // Ensure order is not null before building
                if (order == null) {
                  return Container(
                    width: 320,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 8 : 12,
                      right: index == activeOrders.length - 1 ? 8 : 0,
                    ),
                    child: const SizedBox(),
                  );
                }
                
                final isFirst = index == 0;
                final isLast = index == activeOrders.length - 1;
                
                return Container(
                  width: 320,
                  margin: EdgeInsets.only(
                    left: isFirst ? 8 : 12,
                    right: isLast ? 8 : 0,
                  ),
                  child: _buildOrderCard(order),
                );
              },
            ),
          ),
          
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // Helper method to get unique store names from order
  List<String> _getUniqueStores(ClientOrder order) {
    final storeNames = order.items.values
        .where((item) => item.businessName.isNotEmpty)
        .map((item) => item.businessName)
        .toSet()
        .toList();
    
    // Also include the main business name if it exists
    if (order.restaurantName != null && 
        order.restaurantName!.isNotEmpty && 
        !storeNames.contains(order.restaurantName)) {
      storeNames.add(order.restaurantName!);
    }
    
    return storeNames;
  }

  // Helper method to get all stores in the order (for modal display)
  List<String> _getAllStoresInOrder(ClientOrder order) {
    final allStoreNames = <String>{};
    
    // Add the main business name
    if (order.restaurantName != null && order.restaurantName!.isNotEmpty) {
      allStoreNames.add(order.restaurantName!);
    }
    
    // Add all business names from items
    for (final item in order.items.values) {
      if (item.businessName.isNotEmpty) {
        allStoreNames.add(item.businessName);
      }
    }
    
    return allStoreNames.toList();
  }

  Widget _buildOrderCard(ClientOrder order) {
    // Get first item for display - with null safety
    final firstItem = order.items.isNotEmpty && order.items.values.first != null 
        ? order.items.values.first 
        : null;
    final uniqueStores = _getUniqueStores(order);
    final hasMultipleStores = uniqueStores.length > 1;
    
    return SizedBox(
      width: 320,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              _showOrderDetails(order);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: lightGrey,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Header with Order ID and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        secondaryRed.withOpacity(0.1),
                                        secondaryRed.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '#${order.id}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: secondaryRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _formatOrderTime(order.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: greyText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (order.restaurantName != null && order.restaurantName!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.store_rounded,
                                    size: 12, 
                                    color: greyText.withOpacity(0.8)
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.restaurantName!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        // Show multiple stores indicator if applicable
                                        if (hasMultipleStores)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.storefront_rounded,
                                                  size: 10,
                                                  color: secondaryRed,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '+ ${uniqueStores.length - 1} ${tr('order.more_stores')}',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: secondaryRed,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 100),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: _getStatusGradient(order.status),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(order.status).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(order.status),
                              size: 12,
                              color: white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _getStatusText(order.status),
                                style: const TextStyle(
                                  color: white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          lightGrey.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Order Items Summary
                  Row(
                    children: [
                      // Item Image
                      Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: greyBg,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: firstItem != null && firstItem.productImage.isNotEmpty
                              ? CustomNetworkImage(
                                  imageUrl: firstItem.productImage,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: 'default',
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.shopping_bag_rounded,
                                    size: 20,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (firstItem != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstItem.productName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${firstItem.quantity}x • ${firstItem.unitPrice.toStringAsFixed(2)} ${tr('currency.mad')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: greyText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                tr('order.no_items'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: greyText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            
                            if (order.items.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '+ ${order.items.length - 1} ${tr('order.more_items')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: secondaryRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Footer with Total and Delivery Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Total Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tr('order.total'),
                            style: TextStyle(
                              fontSize: 10,
                              color: greyText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${order.totalPrice.toStringAsFixed(2)} ${tr('currency.mad')}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: secondaryRed,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(ClientOrder order) {
    final allStores = _getAllStoresInOrder(order);
    final hasMultipleStores = allStores.length > 1;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tr('order.order')} #${order.id}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDetailedTime(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: greyText,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _getStatusGradient(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          size: 14,
                          color: white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(order.status),
                          style: const TextStyle(
                            color: white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: greyBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: lightGrey,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Show all stores in a list if multiple stores
                          if (hasMultipleStores)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: secondaryRed.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.store_rounded,
                                        size: 18,
                                        color: secondaryRed,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tr('order.stores'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: greyText,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ...allStores.map((store) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              '• $store',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: black,
                                              ),
                                            ),
                                          )).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            )
                          else if (order.restaurantName != null && order.restaurantName!.isNotEmpty)
                            _buildOrderDetailRow(
                              Icons.store_rounded,
                              tr('order.stores'),
                              order.restaurantName!,
                            ),
                          
                          const SizedBox(height: 12),
                          _buildOrderDetailRow(
                            Icons.location_on_rounded,
                            tr('order.address'),
                            order.address.isNotEmpty ? order.address : tr('common.not_available'),
                          ),
                          const SizedBox(height: 12),
                          _buildOrderDetailRow(
                            Icons.shopping_bag_rounded,
                            tr('order.items_count'),
                            '${order.totalItemsQuantity} ${tr('order.items')}',
                          ),
                          
                          if (order.deliveryDriver != null)
                            Column(
                              children: [
                                const SizedBox(height: 12),
                                _buildOrderDetailRow(
                                  Icons.delivery_dining_rounded,
                                  tr('order.delivery_driver'),
                                  order.deliveryDriver!.name,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    // Items Section
                    Text(
                      tr('order.order_summary'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Items List
                    if (order.items.isNotEmpty)
                      ...order.items.values.where((item) => item != null).map((item) => _buildOrderItem(item!)).toList()
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: greyBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 48,
                                color: greyText,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr('order.no_items'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: greyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Total Price Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            secondaryRed.withOpacity(0.1),
                            secondaryRed.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: secondaryRed.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('order.total'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: black,
                            ),
                          ),
                          Text(
                            '${order.totalPrice.toStringAsFixed(2)} ${tr('currency.mad')}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: secondaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: secondaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: secondaryRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: greyText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(ClientOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lightGrey,
        ),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Item
          Row(
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: greyBg,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomNetworkImage(
                    imageUrl: item.productImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: 'default',
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: lightGrey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: greyText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.unitPrice.toStringAsFixed(2)} ${tr('currency.mad')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: greyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Show business/store name if available
                    if (item.businessName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 12,
                              color: secondaryRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.businessName,
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${item.subtotal.toStringAsFixed(2)} ${tr('currency.mad')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: black,
                ),
              ),
            ],
          ),
          
          // Extras
          if (item.extras != null && item.extras!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: greyBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 14,
                        color: greyText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr('order.extras'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: greyText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...item.extras!.values.where((extra) => extra != null).map((extra) => _buildOrderExtra(extra!)).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderExtra(ClientOrderExtra extra) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: secondaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: secondaryRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extra.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${extra.quantity}x',
                  style: TextStyle(
                    fontSize: 11,
                    color: greyText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${extra.subtotal.toStringAsFixed(2)} ${tr('currency.mad')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: secondaryRed,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time_rounded;
      case OrderStatus.accepted:
        return Icons.check_circle_rounded;
      case OrderStatus.delivered:
        return Icons.local_shipping_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  LinearGradient _getStatusGradient(OrderStatus status) {
    final color = _getStatusColor(status);
    return LinearGradient(
      colors: [
        color,
        color.withOpacity(0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return primaryYellow;
      case OrderStatus.accepted:
        return accentYellow;
      case OrderStatus.delivered:
        return secondaryRed;
      case OrderStatus.cancelled:
        return greyText;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return tr('order_status.pending').toUpperCase();
      case OrderStatus.accepted:
        return tr('order_status.accepted').toUpperCase();
      case OrderStatus.delivered:
        return tr('order_status.delivered').toUpperCase();
      case OrderStatus.cancelled:
        return tr('order_status.cancelled').toUpperCase();
    }
  }

  String _formatOrderTime(DateTime orderTime) {
    final now = DateTime.now();
    final difference = now.difference(orderTime);
    
    if (difference.inMinutes < 1) {
      return tr('time.just_now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${tr('time.minutes_ago')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${tr('time.hours_ago')}';
    } else {
      return '${difference.inDays}${tr('time.days_ago')}';
    }
  }

  String _formatDetailedTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year • $hour:$minute';
  }
}