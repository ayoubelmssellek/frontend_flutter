import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/core/image_helper.dart';
import 'package:food_app/providers/rating_providers.dart';

class RatingSection extends ConsumerStatefulWidget {
  const RatingSection({super.key});

  @override
  ConsumerState<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<RatingSection> {
  @override
  void initState() {
    super.initState();
    // Refresh last order data when widget initializes (background loading)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshRatingSection(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lastOrderAsync = ref.watch(lastOrderDataProvider);
    
    return lastOrderAsync.when(
      data: (lastOrderData) {
        if (lastOrderData == null) {
          return const SizedBox.shrink();
        }
        
        final orderId = lastOrderData['order_id'];
        final driverId = lastOrderData['driver_id'];
        final driverName = lastOrderData['name'];
        final avatar = lastOrderData['avatar'];
        
        return _buildModernRatingSection(
          orderId: orderId,
          driverId: driverId,
          driverName: driverName,
          avatar: avatar,
        );
      },
      loading: () {
        // Check if we have any cached data to show while loading in background
        final cachedData = ref.read(lastOrderDataProvider).value;
        
        if (cachedData != null) {
          // Show cached data with skeleton loading overlay
          final orderId = cachedData['order_id'];
          final driverId = cachedData['driver_id'];
          final driverName = cachedData['name'];
          final avatar = cachedData['avatar'];
          
          return _buildModernRatingSection(
            orderId: orderId,
            driverId: driverId,
            driverName: driverName,
            avatar: avatar,
            isLoading: true, // Show skeleton loading state
          );
        } else {
          // No cached data, don't show anything while loading in background
          return const SizedBox.shrink();
        }
      },
      error: (error, stack) {
        // On error, check if we have cached data to show
        final cachedData = ref.read(lastOrderDataProvider).value;
        
        if (cachedData != null) {
          // Show cached data even if refresh failed
          final orderId = cachedData['order_id'];
          final driverId = cachedData['driver_id'];
          final driverName = cachedData['name'];
          final avatar = cachedData['avatar'];
          
          return _buildModernRatingSection(
            orderId: orderId,
            driverId: driverId,
            driverName: driverName,
            avatar: avatar,
          );
        } else {
          // No cached data and error occurred - hide section
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildModernRatingSection({
    required int orderId,
    required int driverId,
    required String driverName,
    required String? avatar,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade50,
                Colors.red.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar with skeleton loading
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade500,
                                Colors.red.shade500,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade300.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: isLoading 
                                ? Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade300,
                                          Colors.grey.shade400,
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.delivery_dining,
                                      size: 28,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : CustomNetworkImage(
                                    imageUrl: avatar,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: 'avatar',
                                    borderRadius: BorderRadius.circular(30),
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.shade500,
                                              Colors.red.shade500,
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delivery_dining,
                                          size: 28,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title with skeleton loading
                              isLoading
                                  ? Container(
                                      width: 150,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    )
                                  : Text(
                                      tr('rating.rate_your_experience'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                              const SizedBox(height: 6),
                              isLoading
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 200,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 180,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    )
                                  : RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(text: tr('rating.rate_driver_message_prefix')),
                                          TextSpan(
                                            text: driverName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                          TextSpan(text: tr('rating.rate_driver_message_suffix')),
                                        ],
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade100.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: isLoading ? Colors.grey.shade400 : Colors.orange.shade600,
                              ),
                              const SizedBox(width: 6),
                              isLoading
                                  ? Container(
                                      width: 80,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    )
                                  : Text(
                                      tr('rating.last_delivery'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          isLoading
                              ? Container(
                                  width: 60,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                )
                              : Text(
                                  '${tr('order.order')} #$orderId',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: isLoading 
                                    ? Container(
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      )
                                    : _buildSkipButton(orderId),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: isLoading
                                    ? Container(
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                      )
                                    : _buildRateButton(orderId, driverId, driverName, avatar),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Loading overlay
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(int orderId) {
    return OutlinedButton(
      onPressed: () => _skipRating(orderId),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: Text(
        tr('rating.skip'),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRateButton(int orderId, int driverId, String driverName, String? avatar) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade500,
            Colors.red.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade300.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBottomSheetRatingDialog(
            orderId: orderId,
            driverId: driverId,
            driverName: driverName,
            avatar: avatar,
          ),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('rating.rate_now'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  // ... rest of your methods remain the same (_showBottomSheetRatingDialog, _buildCancelButton, _buildSubmitButton, _submitRating, _skipRating)
  void _showBottomSheetRatingDialog({
    required int orderId,
    required int driverId,
    required String driverName,
    required String? avatar,
  }) {
    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade500,
                                Colors.red.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: CustomNetworkImage(
                                    imageUrl: avatar,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: 'avatar',
                                    borderRadius: BorderRadius.circular(25),
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: Icon(
                                          Icons.delivery_dining,
                                          size: 24,
                                          color: Colors.orange.shade700,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('rating.rate_driver'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      driverName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          tr('rating.how_was_delivery'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$rating ${tr('rating.stars')}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        rating = index + 1;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr('rating.poor'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      tr('rating.excellent'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('rating.comment_optional'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: TextField(
                                controller: commentController,
                                decoration: InputDecoration(
                                  hintText: tr('rating.comment_hint'),
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                maxLines: 3,
                                maxLength: 200,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildCancelButton(context),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSubmitButton(
                                orderId: orderId,
                                driverId: driverId,
                                rating: rating,
                                comment: commentController.text,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: Text(
        tr('common.cancel'),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required int orderId,
    required int driverId,
    required int rating,
    required String comment,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade500,
            Colors.red.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade300.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _submitRating(
            orderId: orderId,
            driverId: driverId,
            rating: rating,
            comment: comment,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                tr('rating.submit_rating'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating({
    required int orderId,
    required int driverId,
    required int rating,
    required String comment,
  }) async {
    try {
      final trimmedComment = comment.trim();
      final finalComment = trimmedComment.isNotEmpty ? trimmedComment : null;
      
      
      final result = await ref.read(rateDriverOrOwnerProvider(
        RateParams(
          driverId: driverId,
          orderId: orderId,
          rating: rating,
          comment: finalComment,
        ),
      ).future);

      if (result['success'] == true) {
        
        // Mark order as rated and refresh section immediately
        markOrderAsRated(ref, orderId);
        
        if (mounted) {
          Navigator.pop(context); // Close bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('rating.rating_submitted'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result['message'] ?? tr('rating.rating_error'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('rating.rating_error'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    }
  }

  Future<void> _skipRating(int orderId) async {
    try {
      
      final result = await ref.read(markOrderAsSkippedProvider(orderId).future);

      if (result['success'] == true) {
        
        // Mark order as skipped and refresh section immediately
        markOrderAsSkipped(ref, orderId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('rating.rating_skipped'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result['message'] ?? tr('rating.skip_error'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('rating.skip_error'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    }
  }
}