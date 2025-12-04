// widgets/checkout/order_loading_widget.dart
import 'package:flutter/material.dart';

class OrderLoadingWidget extends StatefulWidget {
  final Duration duration;

  const OrderLoadingWidget({
    super.key,
    this.duration = const Duration(seconds: 1),
  });

  @override
  State<OrderLoadingWidget> createState() => _OrderLoadingWidgetState();
}

class _OrderLoadingWidgetState extends State<OrderLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // white
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Motorcycle Animation
              _buildMotorcycleAnimation(),
              const SizedBox(height: 40),
              
              // Progress Bar
              _buildProgressBar(),
              const SizedBox(height: 20),
              
              // Loading Text
              _buildLoadingText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotorcycleAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Road
        Container(
          width: double.infinity,
          height: 2,
          color: const Color(0xFFF0F0F0), // lightGrey
        ),
        
        // Motorcycle
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                -MediaQuery.of(context).size.width * 0.4 + 
                (MediaQuery.of(context).size.width * 0.8 * _progressAnimation.value),
                0,
              ),
              child: child,
            );
          },
          child: Column(
            children: [
              const Icon(
                Icons.delivery_dining,
                size: 50,
                color: Color(0xFFC63232), // secondaryRed
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progressAnimation.value * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC63232), // secondaryRed
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _progressAnimation.value,
          backgroundColor: const Color(0xFFF8F8F8), // greyBg
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCFC000)), // primaryYellow
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 8),
        Text(
          'Creating your order...',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF666666), // greyText
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingText() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          _getLoadingText(_progressAnimation.value),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF666666), // greyText
          ),
        ),
      ],
    );
  }

  String _getLoadingText(double progress) {
    if (progress < 0.3) {
      return 'Preparing your items...';
    } else if (progress < 0.6) {
      return 'Processing driver...';
    } else if (progress < 0.9) {
      return 'Confirming with stores...';
    } else {
      return 'Almost done...';
    }
  }
}