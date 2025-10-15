import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/services/photo_upload_service.dart';
import '../../../core/theme/app_colors.dart';

class PhotoGalleryWidget extends StatefulWidget {
  final List<String> imageUrls;
  final Function(List<String>) onImagesUpdated;
  final bool isEditable;
  final int maxImages;
  final String? businessId;

  const PhotoGalleryWidget({
    Key? key,
    required this.imageUrls,
    required this.onImagesUpdated,
    this.isEditable = false,
    this.maxImages = 10,
    this.businessId,
  }) : super(key: key);

  @override
  State<PhotoGalleryWidget> createState() => _PhotoGalleryWidgetState();
}

class _PhotoGalleryWidgetState extends State<PhotoGalleryWidget> {
  final PhotoUploadService _photoService = PhotoUploadService();
  List<String> _imageUrls = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photo Gallery',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isEditable)
              TextButton.icon(
                onPressed: _isUploading ? null : _addPhotos,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo),
                label: Text(_isUploading ? 'Uploading...' : 'Add Photos'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_imageUrls.isEmpty)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No photos added yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                if (widget.isEditable) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addPhotos,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add Photos'),
                  ),
                ],
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _imageUrls.length + (widget.isEditable && _imageUrls.length < widget.maxImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _imageUrls.length && widget.isEditable) {
                // Add photo button
                return GestureDetector(
                  onTap: _addPhotos,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 32,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Photo tile
              return GestureDetector(
                onTap: () => _showImageViewer(index),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(_imageUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (widget.isEditable)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _addPhotos() async {
    if (_imageUrls.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum ${widget.maxImages} photos allowed')),
      );
      return;
    }

    final ImageSource? source = await _photoService.showImageSourceDialog(context);
    if (source == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      List<XFile> selectedImages = [];
      
      if (source == ImageSource.camera) {
        final XFile? image = await _photoService.pickImage(source: source);
        if (image != null) {
          selectedImages.add(image);
        }
      } else {
        // For gallery, allow multiple selection
        selectedImages = await _photoService.pickMultipleImages(
          maxImages: widget.maxImages - _imageUrls.length,
        );
      }

      if (selectedImages.isNotEmpty && widget.businessId != null) {
        // Convert XFile to File
        final List<File> imageFiles = selectedImages
            .map((xFile) => File(xFile.path))
            .toList();

        // Upload images
        final List<String> uploadedUrls = await _photoService.uploadBusinessGalleryImages(
          imageFiles: imageFiles,
          businessId: widget.businessId!,
        );

        if (uploadedUrls.isNotEmpty) {
          setState(() {
            _imageUrls.addAll(uploadedUrls);
          });
          widget.onImagesUpdated(_imageUrls);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${uploadedUrls.length} photo(s) uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removePhoto(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Photo'),
          content: const Text('Are you sure you want to remove this photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _imageUrls.removeAt(index);
                });
                widget.onImagesUpdated(_imageUrls);
                // Note: We're not deleting from Firebase Storage here
                // You might want to implement that functionality
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showImageViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewerPage(
          imageUrls: _imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class PhotoViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PhotoViewerPage({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} of ${widget.imageUrls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}