import 'package:flutter/material.dart';
class ImageHelper {
  static const String baseUrl = 'http://192.168.1.140:8000';

  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    String cleanPath = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;

    return '$baseUrl/storage/$cleanPath';
  }

  static bool isValidUrl(String? url) {
    return url != null && url.isNotEmpty && url.startsWith('http');
  }
}

class CustomNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String placeholder;
  final Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder = 'default',
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final String fullUrl = ImageHelper.getImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: ImageHelper.isValidUrl(fullUrl)
          ? _buildNetworkImage(fullUrl)
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _buildLoadingWidget(),
      errorBuilder: (context, error, stackTrace) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error, stackTrace);
        }
        return _buildPlaceholderImage();
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: _getPlaceholderImage(),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _getPlaceholderImage() {
    String assetPath = 'assets/images/placeholder_cover.png';

    if (placeholder == 'avatar') {
      assetPath = 'assets/images/placeholder_avatar.png';
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        placeholder == 'avatar' ? Icons.person : Icons.store,
        size: 32,
        color: Colors.grey.shade400,
      ),
    );
  }
}

class LocalImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const LocalImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image_not_supported),
            ),
          );
        },
      ),
    );
  }
}
