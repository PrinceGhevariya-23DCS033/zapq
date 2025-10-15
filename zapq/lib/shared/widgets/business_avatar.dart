import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/business_model.dart';

class BusinessAvatar extends StatelessWidget {
  final BusinessModel business;
  final double radius;
  final bool showBorder;
  final Color? borderColor;

  const BusinessAvatar({
    super.key,
    required this.business,
    this.radius = 20,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use profileImageUrl if available, fallback to imageUrls[0], then default icon
    String? imageUrl = business.profileImageUrl;
    if ((imageUrl == null || imageUrl.isEmpty) && business.imageUrls.isNotEmpty) {
      imageUrl = business.imageUrls.first;
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Show business thumbnail image
      return Container(
        decoration: showBorder ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppColors.primary,
            width: 2,
          ),
        ) : null,
        child: CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(imageUrl),
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          onBackgroundImageError: (exception, stackTrace) {
            // If image fails to load, show fallback
          },
          child: null, // Will show background image if loaded
        ),
      );
    } else {
      // Show category-based icon fallback
      return Container(
        decoration: showBorder ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppColors.primary,
            width: 2,
          ),
        ) : null,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            _getCategoryIcon(),
            color: AppColors.primary,
            size: radius * 0.8,
          ),
        ),
      );
    }
  }

  IconData _getCategoryIcon() {
    final category = business.category.toLowerCase();
    if (category.contains('restaurant') || category.contains('food')) {
      return Icons.restaurant;
    } else if (category.contains('salon') || category.contains('beauty')) {
      return Icons.content_cut;
    } else if (category.contains('medical') || category.contains('health')) {
      return Icons.medical_services;
    } else if (category.contains('spa')) {
      return Icons.spa;
    } else if (category.contains('fitness')) {
      return Icons.fitness_center;
    } else if (category.contains('auto')) {
      return Icons.car_repair;
    } else if (category.contains('education')) {
      return Icons.school;
    } else if (category.contains('shop') || category.contains('store') || category.contains('retail')) {
      return Icons.store;
    } else {
      return Icons.business;
    }
  }
}