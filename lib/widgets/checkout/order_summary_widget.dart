// widgets/checkout/order_summary_widget.dart
import 'package:flutter/material.dart';

class OrderSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final String selectedDeliveryOption;
  final String? selectedDeliveryMan;
  final Function(String) onDeliveryOptionChanged;
  final VoidCallback onSelectDeliveryMan;

  const OrderSummaryWidget({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.selectedDeliveryOption,
    required this.selectedDeliveryMan,
    required this.onDeliveryOptionChanged,
    required this.onSelectDeliveryMan,
  });

  @override
  Widget build(BuildContext context) {
    final total = subtotal + deliveryFee + serviceFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // white
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05), // black with opacity
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFFC63232), size: 18), // secondaryRed
              SizedBox(width: 6),
              Text(
                'Order Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', subtotal),
          _buildSummaryRow('Delivery Fee', deliveryFee),
          _buildSummaryRow('Service Fee', serviceFee),
          const Divider(height: 20),
          _buildSummaryRow('Total', total, isTotal: true),
          const SizedBox(height: 16),
          
          // Delivery Options
          const Text(
            'Delivery Preference',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDeliveryOption(
                  'All Partners',
                  'Fastest delivery',
                  'all',
                  Icons.group,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDeliveryOption(
                  'Choose Partner',
                  'Select preferred',
                  'choose',
                  Icons.person,
                ),
              ),
            ],
          ),
          
          if (selectedDeliveryOption == 'choose') ...[
            const SizedBox(height: 12),
            if (selectedDeliveryMan != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFCFC000).withOpacity(0.1), // primaryYellow with opacity
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFFCFC000), size: 18), // primaryYellow
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Selected: $selectedDeliveryMan',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: onSelectDeliveryMan,
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: Color(0xFFC63232), // secondaryRed
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCFC000).withOpacity(0.1), // primaryYellow with opacity
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCFC000).withOpacity(0.3)), // primaryYellow with opacity
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFFCFC000), size: 18), // primaryYellow
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please select a delivery partner',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onSelectDeliveryMan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC63232), // secondaryRed
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Select',
                        style: TextStyle(
                          color: Color(0xFFFFFFFF), // white
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(String title, String subtitle, String value, IconData icon) {
    final isSelected = selectedDeliveryOption == value;
    
    return GestureDetector(
      onTap: () => onDeliveryOptionChanged(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFC63232).withOpacity(0.1) // secondaryRed with opacity
              : const Color(0xFFF8F8F8), // greyBg
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFC63232) // secondaryRed
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon, 
              color: isSelected ? const Color(0xFFC63232) : const Color(0xFF666666), // secondaryRed : greyText
              size: 18
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isSelected ? const Color(0xFFC63232) : const Color(0xFF000000), // secondaryRed : black
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: const Color(0xFF666666), // greyText
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? const Color(0xFF000000) : const Color(0xFF666666), // black : greyText
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} MAD',
            style: TextStyle(
              fontSize: isTotal ? 16 : 12,
              fontWeight: FontWeight.w700,
              color: isTotal ? const Color(0xFFC63232) : const Color(0xFF666666), // secondaryRed : greyText
            ),
          ),
        ],
      ),
    );
  }
}