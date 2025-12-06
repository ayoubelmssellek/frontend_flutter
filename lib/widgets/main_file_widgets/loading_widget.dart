import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Color(0xFFCFC000), Color(0xFFFFD600)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo from assets
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if logo not found
                      return Container(
                        color: Colors.white,
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Color(0xFFC63232),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // App Name
              Text(
                'uniqque',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black26,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // CSS-inspired Animated Loader
              _buildCssLoader(),
              const SizedBox(height: 20),
              
              // Loading Text
              Text(
                'loading',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCssLoader() {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: const Color(0xFFC63232), // Starting color
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(20, 0),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(-20, 0),
          ),
        ],
      ),
      child: TweenAnimationBuilder(
        duration: const Duration(seconds: 1),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, value, child) {
          return Container(
            decoration: BoxDecoration(
              color: _getAnimatedColor(value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getShadow1Color(value),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(20, 0),
                ),
                BoxShadow(
                  color: _getShadow2Color(value),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(-20, 0),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getAnimatedColor(double value) {
    if (value < 0.33) {
      return const Color(0xFFC63232); // Red
    } else if (value < 0.66) {
      return const Color(0xFFC63232).withOpacity(0.5); // Red with opacity
    } else {
      return const Color(0xFFC63232).withOpacity(0.5); // Red with opacity
    }
  }

  Color _getShadow1Color(double value) {
    if (value < 0.33) {
      return Colors.black.withOpacity(0.5); // Dark shadow
    } else if (value < 0.66) {
      return Colors.black.withOpacity(0.5); // Dark shadow
    } else {
      return Colors.black.withOpacity(0.2); // Light shadow
    }
  }

  Color _getShadow2Color(double value) {
    if (value < 0.33) {
      return Colors.black.withOpacity(0.2); // Light shadow
    } else if (value < 0.66) {
      return Colors.black.withOpacity(0.2); // Light shadow
    } else {
      return Colors.black.withOpacity(0.5); // Dark shadow
    }
  }
}