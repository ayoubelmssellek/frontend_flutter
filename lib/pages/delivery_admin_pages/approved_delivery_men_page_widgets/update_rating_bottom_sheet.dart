// pages/delivery_admin_pages/widgets/update_rating_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_app/providers/delivery_admin_providers/admin_providers.dart';

class UpdateRatingBottomSheet extends ConsumerStatefulWidget {
  final int driverId;
  final double? currentRating;
  final Function(double) onRatingUpdated;

  const UpdateRatingBottomSheet({
    super.key,
    required this.driverId,
    required this.currentRating,
    required this.onRatingUpdated,
  });

  @override
  ConsumerState<UpdateRatingBottomSheet> createState() => _UpdateRatingBottomSheetState();
}

class _UpdateRatingBottomSheetState extends ConsumerState<UpdateRatingBottomSheet> {
  final TextEditingController _ratingController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _ratingController.text = widget.currentRating?.toStringAsFixed(1) ?? '0.0';
  }

  @override
  void dispose() {
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _updateRating() async {
    if (_ratingController.text.isEmpty) return;

    final newRating = double.tryParse(_ratingController.text);
    if (newRating == null || newRating < 0 || newRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid rating between 0 and 5'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await ref.read(updateDeliveryDriverAvgRatingProvider((
        driverId: widget.driverId,
        avgRating: newRating,
      )).future);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Rating updated to $newRating'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        widget.onRatingUpdated(newRating);
        Navigator.pop(context);
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update rating'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Update Driver Rating',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current Rating: ${widget.currentRating?.toStringAsFixed(1) ?? '0.0'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _ratingController,
            decoration: InputDecoration(
              labelText: 'New Rating (0-5)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange.shade400),
              ),
              prefixIcon: Icon(Icons.edit, color: Colors.orange),
              hintText: 'Enter rating between 0 and 5',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a value between 0.0 and 5.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updateRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Update Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}