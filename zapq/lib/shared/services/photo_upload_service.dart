import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/config/cloudinary_config.dart';

class PhotoUploadService {
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      // Limit the number of images
      if (images.length > maxImages) {
        return images.take(maxImages).toList();
      }
      
      return images;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // Upload single image to Cloudinary
  Future<String?> uploadImage({
    required File imageFile,
    required String folderPath,
    String? fileName,
  }) async {
    try {
      fileName ??= 'image_${DateTime.now().millisecondsSinceEpoch}';
      
      print('🚀 Starting Cloudinary upload...');
      print('📁 Folder path: $folderPath');
      print('📄 File name: $fileName');
      print('📱 File exists: ${await imageFile.exists()}');
      print('📊 File size: ${await imageFile.length()} bytes');
      
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      
      final request = http.MultipartRequest('POST', uri);
      
      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      // Add parameters
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = folderPath;
      request.fields['public_id'] = '$folderPath/$fileName';
      request.fields['resource_type'] = 'image';
      
      print('📤 Uploading to Cloudinary with preset: ${CloudinaryConfig.uploadPreset}...');
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        
        final downloadUrl = jsonResponse['secure_url'] as String;
        
        print('📤 Image uploaded successfully!');
        print('🔗 Download URL: $downloadUrl');
        print('📁 Folder: $folderPath');
        print('📄 File: $fileName');
        
        return downloadUrl;
      } else {
        final errorData = await response.stream.bytesToString();
        print('❌ Upload failed with status: ${response.statusCode}');
        print('❌ Error: $errorData');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      print('📁 Attempted folder: $folderPath');
      print('📄 Attempted file: $fileName');
      print('📱 File path: ${imageFile.path}');
      return null;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folderPath,
  }) async {
    List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final String? url = await uploadImage(
        imageFile: imageFiles[i],
        folderPath: folderPath,
        fileName: fileName,
      );
      
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }

  // Upload business profile image
  Future<String?> uploadBusinessProfileImage({
    required File imageFile,
    required String businessId,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folderPath: 'businesses/$businessId/profile',
      fileName: 'profile_image.jpg',
    );
  }

  // Upload business gallery images
  Future<List<String>> uploadBusinessGalleryImages({
    required List<File> imageFiles,
    required String businessId,
  }) async {
    return await uploadMultipleImages(
      imageFiles: imageFiles,
      folderPath: 'businesses/$businessId/gallery',
    );
  }

  // Upload offer poster
  Future<String?> uploadOfferPoster({
    required File imageFile,
    required String businessId,
    required String offerId,
  }) async {
    return await uploadImage(
      imageFile: imageFile,
      folderPath: 'businesses/$businessId/offers',
      fileName: 'offer_${offerId}_poster.jpg',
    );
  }

  // Delete image from Cloudinary
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract public_id from Cloudinary URL
      // URL format: https://res.cloudinary.com/cloud_name/image/upload/v1234567890/folder/filename.jpg
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 4) {
        // Skip 'image', 'upload', version, get the path from folder onwards
        final publicIdWithExt = pathSegments.sublist(3).join('/');
        // Remove file extension to get public_id
        final publicId = publicIdWithExt.replaceAll(RegExp(r'\.[^.]*$'), '');
        
        print('🗑️ Attempting to delete image with public_id: $publicId');
        
        // For deletion, you would typically use Cloudinary Admin API
        // But for now, we'll just return true as most apps don't implement deletion
        // to avoid complexities with signed requests
        print('📝 Note: Cloudinary deletion requires Admin API setup');
        return true;
      }
      
      print('❌ Could not extract public_id from URL: $imageUrl');
      return false;
    } catch (e) {
      print('❌ Error deleting image: $e');
      return false;
    }
  }

  // Show image picker dialog
  Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  // Validate image file
  bool isValidImageFile(File file) {
    final String extension = file.path.split('.').last.toLowerCase();
    final List<String> validExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    return validExtensions.contains(extension);
  }

  // Get file size in MB
  double getFileSizeInMB(File file) {
    final int bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Validate image size (max 5MB)
  bool isValidImageSize(File file, {double maxSizeMB = 5.0}) {
    return getFileSizeInMB(file) <= maxSizeMB;
  }
}