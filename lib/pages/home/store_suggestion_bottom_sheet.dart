import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class StoreSuggestionBottomSheet extends StatefulWidget {
  final Function(String) onSuggestStore;
  final VoidCallback onDismiss;

  const StoreSuggestionBottomSheet({
    super.key,
    required this.onSuggestStore,
    required this.onDismiss,
  });

  @override
  State<StoreSuggestionBottomSheet> createState() => _StoreSuggestionBottomSheetState();
}

class _StoreSuggestionBottomSheetState extends State<StoreSuggestionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasDismissed = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    super.dispose();
  }

  void _submitSuggestion() {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);
      
      // Call the callback with ONLY the store name
      widget.onSuggestStore(_storeNameController.text.trim());
      
      // Close the bottom sheet after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _dismissPermanently() {
    if (!_hasDismissed) {
      _hasDismissed = true;
      widget.onDismiss();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('store_suggestion.title'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr('store_suggestion.subtitle'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _dismissPermanently,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: tr('store_suggestion.dismiss'),
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.grey.shade200,
            ),
            
            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Name Only
                    Text(
                      tr('store_suggestion.store_name'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: InputDecoration(
                        hintText: tr('store_suggestion.store_name_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFC63232), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return tr('store_suggestion.store_name_required');
                        }
                        if (value.trim().length < 2) {
                          return tr('store_suggestion.store_name_min_length');
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitSuggestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC63232),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                tr('store_suggestion.submit'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dismiss Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _dismissPermanently,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          tr('store_suggestion.dismiss_permanently'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}