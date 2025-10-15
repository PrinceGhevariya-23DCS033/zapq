class CloudinaryConfig {
  // Cloudinary configuration - Updated with your credentials
  static const String cloudName = 'debs8ro5i'; // Your Cloudinary cloud name
  static const String uploadPreset = 'zapq_uploder'; // Your upload preset name
  
  // Alternative preset names to try if 'zapq_uploder' doesn't work
  static const String fallbackPreset = 'ml_default'; // Cloudinary's default unsigned preset
  
  // For signed uploads (optional - we're using unsigned uploads for simplicity)  
  static const String apiKey = '561716415328652';
  static const String apiSecret = 'Msej3PibyGUZWxEUPYpPbETqsAs';
  
  // Cloudinary upload URL
  static String get uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  
  // Transform URLs for different image sizes
  static String getTransformedUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl; // Return original if not a Cloudinary URL
    }
    
    // Build transformation string
    List<String> transformations = [];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    // Insert transformations into URL
    final transformString = transformations.join(',');
    return originalUrl.replaceFirst(
      '/image/upload/',
      '/image/upload/$transformString/',
    );
  }
  
  // Get thumbnail URL (300x300)
  static String getThumbnailUrl(String originalUrl) {
    return getTransformedUrl(
      originalUrl,
      width: 300,
      height: 300,
    );
  }
  
  // Get medium size URL (800x600)
  static String getMediumUrl(String originalUrl) {
    return getTransformedUrl(
      originalUrl,
      width: 800,
      height: 600,
    );
  }
}