import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/enhanced_business_provider.dart';
import '../../../../shared/models/business_model.dart';
import '../../../../shared/services/photo_upload_service.dart';

class BusinessEditPage extends StatefulWidget {
  final String businessId;

  const BusinessEditPage({super.key, required this.businessId});

  @override
  State<BusinessEditPage> createState() => _BusinessEditPageState();
}

class _BusinessEditPageState extends State<BusinessEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedCategory = 'salon';
  final List<String> _categories = [
    'salon',
    'beauty_parlor',
    'barbershop',
    'spa',
    'medical',
    'dental',
    'restaurant',
    'retail',
    'fitness',
    'auto',
    'education',
    'other'
  ];

  BusinessModel? _business;
  BusinessHours _businessHours = BusinessHours.defaultHours();
  bool _isLoading = false;
  bool _hasChanges = false;
  
  // Image upload related
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  final List<String> _newImageUrls = [];
  File? _newThumbnailImage;
  String? _existingThumbnailUrl;
  String? _newThumbnailUrl;


  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'salon':
        return 'Hair Salon';
      case 'beauty_parlor':
        return 'Beauty Parlor';
      case 'barbershop':
        return 'Barbershop';
      case 'spa':
        return 'Spa & Wellness';
      case 'medical':
        return 'Medical Clinic';
      case 'dental':
        return 'Dental Clinic';
      case 'restaurant':
        return 'Restaurant';
      case 'retail':
        return 'Retail Shop';
      case 'fitness':
        return 'Fitness Center';
      case 'auto':
        return 'Auto Service';
      case 'education':
        return 'Education';
      default:
        return 'Other';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  void _loadBusiness() async {
    final businessProvider = context.read<BusinessProvider>();
    
    // Refresh business data from server
    print('🔄 Refreshing business data from server...');
    await businessProvider.loadUserBusiness();
    
    setState(() {
      _business = businessProvider.userBusiness;
      if (_business != null) {
        print('🏪 Loading business for edit:');
        print('📸 Profile image URL: ${_business!.profileImageUrl}');
        print('📷 Image URLs: ${_business!.imageUrls}');
        
        _nameController.text = _business!.name;
        _descriptionController.text = _business!.description;
        _addressController.text = _business!.address;
        _phoneController.text = _business!.phoneNumber;
        _emailController.text = _business!.email ?? '';
        _selectedCategory = _business!.category;
        _businessHours = _business!.businessHours;
        _existingImageUrls.clear();
        _existingImageUrls.addAll(_business!.imageUrls);
        _existingThumbnailUrl = _business!.profileImageUrl;
        
        print('📸 Loaded thumbnail URL: $_existingThumbnailUrl');
        print('📷 Loaded image URLs: $_existingImageUrls');
      } else {
        print('❌ No business data found!');
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_business == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Try multiple navigation methods for reliability
              try {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/business-home');
                }
              } catch (e) {
                // Fallback to business home
                context.go('/business-home');
              }
            },
          ),
          title: const Text('Edit Business'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Try multiple navigation methods for reliability
            try {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/business-home');
              }
            } catch (e) {
              // Fallback to business home
              context.go('/business-home');
            }
          },
        ),
        title: const Text('Edit Business'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveBusiness,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter business name';
                          }
                          return null;
                        },
                        onChanged: (_) => _markChanged(),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryDisplayName(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                            _markChanged();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          helperText: 'Tell customers about your business',
                        ),
                        maxLines: 3,
                        onChanged: (_) => _markChanged(),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                        maxLines: 2,
                        onChanged: (_) => _markChanged(),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter phone number';
                                }
                                return null;
                              },
                              onChanged: (_) => _markChanged(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isNotEmpty == true && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                                  return 'Please enter valid email';
                                }
                                return null;
                              },
                              onChanged: (_) => _markChanged(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Business Photos Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Photos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Thumbnail/Logo Section
                      Text(
                        'Business Logo/Thumbnail',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Main image that appears as your business logo in listings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickThumbnail,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: (_newThumbnailImage != null || _existingThumbnailUrl != null) 
                                      ? AppColors.primary : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _newThumbnailImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(
                                        _newThumbnailImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _existingThumbnailUrl != null && _existingThumbnailUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.network(
                                            _existingThumbnailUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[100],
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              print('❌ Error loading thumbnail: $error');
                                              print('🔗 URL: $_existingThumbnailUrl');
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.error, color: Colors.red),
                                                    Text('Failed to load', 
                                                      style: TextStyle(fontSize: 10, color: Colors.red),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              color: Colors.grey[400],
                                              size: 32,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Add Logo',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_newThumbnailImage != null || _existingThumbnailUrl != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _newThumbnailImage = null;
                                  _existingThumbnailUrl = null;
                                });
                                _markChanged();
                              },
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Remove'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[100],
                                foregroundColor: Colors.red[700],
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Gallery Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Photo Gallery',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Photos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Additional photos to showcase your business (maximum 10 photos total)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Existing Images
                      if (_existingImageUrls.isNotEmpty) ...[
                        Text(
                          'Current Photos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingImageUrls.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _existingImageUrls[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[100],
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ Error loading gallery image ${index}: $error');
                                          print('🔗 URL: ${_existingImageUrls[index]}');
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.error, color: Colors.red, size: 20),
                                                Text('Failed', 
                                                  style: TextStyle(fontSize: 8, color: Colors.red),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          onPressed: () => _removeExistingImage(index),
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // New Images
                      if (_selectedImages.isNotEmpty) ...[
                        Text(
                          'New Photos to Upload',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImages[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          onPressed: () => _removeNewImage(index),
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
                      // No photos message
                      if (_existingImageUrls.isEmpty && _selectedImages.isEmpty)
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'No photos yet\nTap "Add Photos" to add some',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      
                      // Photo count
                      if (_existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${_existingImageUrls.length + _selectedImages.length} photo(s) total',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Business Hours
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Business Hours',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _showBusinessHoursDialog,
                            icon: const Icon(Icons.schedule, size: 16),
                            label: const Text('Edit Hours'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Display current hours
                      Column(
                        children: _businessHours.hours.entries.map((entry) {
                          final day = entry.key;
                          final dayHours = entry.value;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    day.substring(0, 1).toUpperCase() + day.substring(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    dayHours.isOpen 
                                        ? '${dayHours.openTime} - ${dayHours.closeTime}'
                                        : 'Closed',
                                    style: TextStyle(
                                      color: dayHours.isOpen ? AppColors.textPrimary : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Danger Zone
              Card(
                color: AppColors.error.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(
                            'Danger Zone',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'These actions are permanent and cannot be undone.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showDeleteBusinessDialog,
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Delete Business'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _showBusinessHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => _BusinessHoursDialog(
        businessHours: _businessHours,
        onHoursUpdated: (hours) {
          setState(() {
            _businessHours = hours;
            _markChanged();
          });
        },
      ),
    );
  }

  void _showDeleteBusinessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 12),
            const Text('Delete Business'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${_business!.name}"?'),
            const SizedBox(height: 8),
            Text(
              'This action will:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Delete all business data\n• Cancel all pending bookings\n• Remove all reviews and ratings\n• Cannot be undone',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete business
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete business feature will be implemented soon'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Business', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickThumbnail() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _newThumbnailImage = File(image.path);
        });
        _markChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking thumbnail: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if ((_selectedImages.length + _existingImageUrls.length) < 10) { // Limit to 10 images total
              _selectedImages.add(File(image.path));
            }
          }
        });
        _markChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
    _markChanged();
  }

  Future<void> _uploadNewImages() async {
    if (_selectedImages.isEmpty && _newThumbnailImage == null) {
      print('🚫 No new images to upload');
      return;
    }

    print('⬆️ Starting image upload process...');
    print('📸 New thumbnail image: ${_newThumbnailImage != null ? 'Yes' : 'No'}');
    print('📷 New gallery images: ${_selectedImages.length}');

    try {
      final photoUploadService = PhotoUploadService();
      
      // Upload new thumbnail if selected
      if (_newThumbnailImage != null) {
        print('⬆️ Uploading new thumbnail...');
        _newThumbnailUrl = await photoUploadService.uploadImage(
          imageFile: _newThumbnailImage!,
          folderPath: 'business_thumbnails',
          fileName: 'thumbnail_${_business!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        print('✅ Thumbnail uploaded: $_newThumbnailUrl');
      }
      
      // Upload gallery images
      if (_selectedImages.isNotEmpty) {
        print('⬆️ Uploading ${_selectedImages.length} gallery images...');
        final uploadedUrls = await photoUploadService.uploadMultipleImages(
          imageFiles: _selectedImages,
          folderPath: 'business_gallery/${_business!.id}',
        );
        _newImageUrls.addAll(uploadedUrls);
        print('✅ Gallery images uploaded: $uploadedUrls');
      }
      
      _selectedImages.clear(); // Clear selected images after upload
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {

    }
  }

  Future<void> _saveBusiness() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final businessProvider = context.read<BusinessProvider>();
        
        // Upload new images first
        await _uploadNewImages();
        
        // Combine existing and new image URLs
        final allImageUrls = [..._existingImageUrls, ..._newImageUrls];
        
        // Determine final thumbnail URL
        final finalThumbnailUrl = _newThumbnailUrl ?? _existingThumbnailUrl;
        
        print('🔄 Updating business with images:');
        print('📸 Final thumbnail URL: $finalThumbnailUrl');
        print('📷 All image URLs: $allImageUrls');
        print('🔗 New thumbnail URL: $_newThumbnailUrl');
        print('🔗 Existing thumbnail URL: $_existingThumbnailUrl');
        print('📋 New image URLs: $_newImageUrls');
        print('📋 Existing image URLs: $_existingImageUrls');
        
        // Convert BusinessHours to operatingHours map
        final operatingHoursMap = <String, String>{};
        _businessHours.hours.forEach((day, dayHours) {
          if (dayHours.isOpen) {
            operatingHoursMap[day] = '${dayHours.openTime}-${dayHours.closeTime}';
          } else {
            operatingHoursMap[day] = 'Closed';
          }
        });
        
        // Update business with new data
        final updatedBusiness = _business!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          businessHours: _businessHours,
          operatingHours: operatingHoursMap,
          imageUrls: allImageUrls,
          profileImageUrl: finalThumbnailUrl,
          updatedAt: DateTime.now(),
        );

        final success = await businessProvider.updateBusiness(updatedBusiness);
        
        if (success && mounted) {
          setState(() {
            _hasChanges = false;
            _business = updatedBusiness;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(businessProvider.errorMessage ?? 'Failed to update business'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

// Business Hours Dialog (reused from registration page)
class _BusinessHoursDialog extends StatefulWidget {
  final BusinessHours businessHours;
  final Function(BusinessHours) onHoursUpdated;

  const _BusinessHoursDialog({
    required this.businessHours,
    required this.onHoursUpdated,
  });

  @override
  State<_BusinessHoursDialog> createState() => _BusinessHoursDialogState();
}

class _BusinessHoursDialogState extends State<_BusinessHoursDialog> {
  late BusinessHours _businessHours;

  @override
  void initState() {
    super.initState();
    // Create a copy of the business hours
    _businessHours = BusinessHours(
      hours: Map.from(widget.businessHours.hours),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Business Hours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Hours List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: _businessHours.hours.entries.map((entry) {
                  final day = entry.key;
                  final dayHours = entry.value;
                  
                  return _buildDayHoursCard(day, dayHours);
                }).toList(),
              ),
            ),

            // Action Buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onHoursUpdated(_businessHours);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Save Hours',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHoursCard(String day, DayHours dayHours) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  day.substring(0, 1).toUpperCase() + day.substring(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: dayHours.isOpen,
                  onChanged: (value) {
                    setState(() {
                      _businessHours.hours[day] = DayHours(
                        isOpen: value,
                        openTime: dayHours.openTime,
                        closeTime: dayHours.closeTime,
                      );
                    });
                  },
                  activeColor: AppColors.success,
                ),
              ],
            ),
            if (dayHours.isOpen) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      'Open Time',
                      dayHours.openTime,
                      (time) {
                        setState(() {
                          _businessHours.hours[day] = DayHours(
                            isOpen: dayHours.isOpen,
                            openTime: time,
                            closeTime: dayHours.closeTime,
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      'Close Time',
                      dayHours.closeTime,
                      (time) {
                        setState(() {
                          _businessHours.hours[day] = DayHours(
                            isOpen: dayHours.isOpen,
                            openTime: dayHours.openTime,
                            closeTime: time,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, String currentTime, Function(String) onTimeSelected) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(currentTime.split(':')[0]),
            minute: int.parse(currentTime.split(':')[1]),
          ),
        );
        
        if (time != null) {
          final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          onTimeSelected(timeString);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentTime,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
