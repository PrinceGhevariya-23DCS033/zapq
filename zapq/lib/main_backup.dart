import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:io';
import 'firebase_options.dart';
import 'shared/models/business_model.dart';
import 'shared/models/user_model.dart';
import 'shared/models/review_model.dart';
import 'shared/models/offer_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(FirebaseDataPopulatorApp());
}

class FirebaseDataPopulatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🇮🇳 Firebase Business Data Populator',
      home: FirebaseDataPopulatorScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}

class FirebaseDataPopulatorScreen extends StatefulWidget {
  @override
  _FirebaseDataPopulatorScreenState createState() => _FirebaseDataPopulatorScreenState();
}

class _FirebaseDataPopulatorScreenState extends State<FirebaseDataPopulatorScreen> {
  bool _isPopulating = false;
  String _currentStatus = 'Ready to populate Firebase with Indian business data';
  List<String> _logs = [];
  List<String> _credentialsList = [];
  int _totalBusinesses = 0;
  int _totalCustomers = 0;
  int _totalServices = 0;
  int _totalReviews = 0;
  int _totalOffers = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();

  // Comprehensive Indian business data
  final Map<String, List<String>> businessNames = {
    'salon': [
      'Maharani Beauty Salon',
      'Kiran Hair Studio',
      'Priya\'s Beauty Parlour',
      'Lakshmi Hair & Beauty',
      'Sapna Beauty Center',
      'Radha Krishna Salon',
      'Shree Ganesh Beauty Studio',
      'Mumbai Hair Gallery',
      'Delhi Beauty Palace',
      'Chennai Hair Lounge'
    ],
    'barbershop': [
      'Sharma Brothers Barber Shop',
      'Raja Hair Cutting Salon',
      'Modern Gents Parlour',
      'Arjun Hair Studio',
      'Classic Men\'s Salon',
      'Punjabi Hair Cut Center',
      'Royal Barber Shop',
      'New Style Hair Salon',
      'Gents Hair Corner',
      'Smart Look Barber'
    ],
    'spa': [
      'Ayurveda Wellness Spa',
      'Shanti Yoga & Spa',
      'Himalayan Retreat Spa',
      'Kerala Ayurvedic Center',
      'Lotus Healing Spa',
      'Zen Meditation Spa',
      'Gupta Wellness Center',
      'Traditional Indian Spa',
      'Nirvana Health Spa',
      'Vedic Healing Center'
    ],
    'dental': [
      'Dr. Sharma Dental Clinic',
      'Smile Care Dental Center',
      'Patel Dental Hospital',
      'Modern Dental Clinic',
      'Tooth Care Center',
      'Dental Plus Clinic',
      'Bright Smile Dental',
      'Gupta Dental Care',
      'Family Dental Clinic',
      'Advanced Dental Center'
    ],
    'medical': [
      'Raj Medical Center',
      'City Health Clinic',
      'Apollo Mini Clinic',
      'Fortis Health Care',
      'Max Care Medical',
      'Life Care Clinic',
      'Wellness Medical Center',
      'Cure Plus Clinic',
      'Metro Health Care',
      'Primary Care Center'
    ],
    'fitness': [
      'Gold\'s Gym Mumbai',
      'Fitness First Delhi',
      'Body Builders Gym',
      'Power House Fitness',
      'Muscle Factory Gym',
      'Iron Paradise Fitness',
      'Shape Up Gym',
      'Fit India Gym',
      'Strong Body Fitness',
      'Champions Gym'
    ]
  };

  final List<String> indianNames = [
    'Aarav Sharma', 'Vivaan Patel', 'Aditya Gupta', 'Vihaan Singh', 'Arjun Kumar',
    'Sai Verma', 'Reyansh Jain', 'Ayaan Khan', 'Krishna Mishra', 'Ishaan Agarwal',
    'Ananya Sharma', 'Diya Patel', 'Isha Gupta', 'Myra Singh', 'Sara Kumar',
    'Aanya Verma', 'Kavya Jain', 'Aditi Khan', 'Navya Mishra', 'Kiara Agarwal',
    'Priya Reddy', 'Sneha Iyer', 'Pooja Nair', 'Divya Pillai', 'Meera Menon',
    'Ravi Krishnan', 'Suresh Nair', 'Ramesh Pillai', 'Vijay Menon', 'Ajay Reddy',
    'Amit Chopra', 'Rohit Malhotra', 'Vikram Sethi', 'Karan Khanna', 'Rahul Kapoor',
    'Neha Chopra', 'Ritu Malhotra', 'Simran Sethi', 'Tanya Khanna', 'Vidya Kapoor',
    'Aryan Joshi', 'Dev Shukla', 'Yash Pandey', 'Om Tiwari', 'Harsh Dubey',
    'Riya Joshi', 'Nisha Shukla', 'Sakshi Pandey', 'Tanvi Tiwari', 'Shreya Dubey',
    'Rohan Aggarwal', 'Karan Bansal', 'Varun Goyal', 'Nikhil Agarwal', 'Siddharth Jain',
    'Kaveri Bansal', 'Ritika Goyal', 'Nidhi Agarwal', 'Swati Jain', 'Preeti Sharma'
  ];

  // Services with realistic Indian pricing
  final Map<String, List<Map<String, dynamic>>> servicesByCategory = {
    'salon': [
      {'name': 'Hair Cut & Style', 'price': 300, 'duration': 60, 'description': 'Professional hair cutting and styling'},
      {'name': 'Hair Wash & Blow Dry', 'price': 200, 'duration': 30, 'description': 'Hair wash with blow dry styling'},
      {'name': 'Hair Coloring', 'price': 1500, 'duration': 120, 'description': 'Professional hair coloring service'},
      {'name': 'Hair Spa Treatment', 'price': 800, 'duration': 90, 'description': 'Deep conditioning hair spa'},
      {'name': 'Keratin Treatment', 'price': 3000, 'duration': 180, 'description': 'Keratin hair smoothening treatment'},
      {'name': 'Facial Clean Up', 'price': 500, 'duration': 45, 'description': 'Deep cleansing facial treatment'},
      {'name': 'Bridal Makeup', 'price': 5000, 'duration': 180, 'description': 'Complete bridal makeup package'},
      {'name': 'Party Makeup', 'price': 2000, 'duration': 90, 'description': 'Party and event makeup'},
      {'name': 'Eyebrow Threading', 'price': 100, 'duration': 15, 'description': 'Eyebrow shaping and threading'},
      {'name': 'Manicure & Pedicure', 'price': 600, 'duration': 60, 'description': 'Hand and foot care treatment'}
    ],
    'barbershop': [
      {'name': 'Regular Hair Cut', 'price': 150, 'duration': 30, 'description': 'Standard men\'s haircut'},
      {'name': 'Beard Trim', 'price': 100, 'duration': 20, 'description': 'Beard trimming and shaping'},
      {'name': 'Hair Wash', 'price': 80, 'duration': 15, 'description': 'Hair wash and conditioning'},
      {'name': 'Traditional Shaving', 'price': 120, 'duration': 25, 'description': 'Traditional razor shaving'},
      {'name': 'Hair Styling', 'price': 200, 'duration': 45, 'description': 'Professional hair styling'},
      {'name': 'Head Massage', 'price': 150, 'duration': 30, 'description': 'Relaxing head massage'},
      {'name': 'Face Clean Up', 'price': 300, 'duration': 45, 'description': 'Men\'s facial cleanup'},
      {'name': 'Complete Grooming', 'price': 500, 'duration': 90, 'description': 'Full grooming package'}
    ],
    'spa': [
      {'name': 'Full Body Massage', 'price': 2000, 'duration': 90, 'description': 'Complete body relaxation massage'},
      {'name': 'Ayurvedic Massage', 'price': 2500, 'duration': 120, 'description': 'Traditional Ayurvedic massage'},
      {'name': 'Head & Shoulder Massage', 'price': 800, 'duration': 45, 'description': 'Stress relief massage'},
      {'name': 'Deep Tissue Massage', 'price': 2200, 'duration': 90, 'description': 'Therapeutic deep tissue massage'},
      {'name': 'Hot Stone Therapy', 'price': 3000, 'duration': 120, 'description': 'Hot stone relaxation therapy'},
      {'name': 'Aromatherapy', 'price': 1800, 'duration': 75, 'description': 'Essential oil aromatherapy'},
      {'name': 'Reflexology', 'price': 1200, 'duration': 60, 'description': 'Foot reflexology treatment'},
      {'name': 'Couples Massage', 'price': 4000, 'duration': 90, 'description': 'Couples relaxation massage'},
      {'name': 'Body Scrub', 'price': 1500, 'duration': 60, 'description': 'Exfoliating body scrub'},
      {'name': 'Steam Bath', 'price': 500, 'duration': 30, 'description': 'Detoxifying steam bath'}
    ],
    'dental': [
      {'name': 'Dental Checkup', 'price': 500, 'duration': 30, 'description': 'Complete dental examination'},
      {'name': 'Teeth Cleaning', 'price': 800, 'duration': 45, 'description': 'Professional teeth cleaning'},
      {'name': 'Tooth Filling', 'price': 1200, 'duration': 60, 'description': 'Cavity filling treatment'},
      {'name': 'Root Canal Treatment', 'price': 8000, 'duration': 90, 'description': 'Root canal therapy'},
      {'name': 'Teeth Whitening', 'price': 3000, 'duration': 60, 'description': 'Professional teeth whitening'},
      {'name': 'Dental Crown', 'price': 5000, 'duration': 90, 'description': 'Dental crown placement'},
      {'name': 'Tooth Extraction', 'price': 1500, 'duration': 45, 'description': 'Tooth removal procedure'},
      {'name': 'Braces Consultation', 'price': 1000, 'duration': 45, 'description': 'Orthodontic consultation'},
      {'name': 'Dental Implant', 'price': 25000, 'duration': 120, 'description': 'Dental implant procedure'},
      {'name': 'Gum Treatment', 'price': 2000, 'duration': 60, 'description': 'Gum disease treatment'}
    ],
    'medical': [
      {'name': 'General Consultation', 'price': 400, 'duration': 30, 'description': 'Doctor consultation'},
      {'name': 'Blood Pressure Check', 'price': 100, 'duration': 15, 'description': 'BP monitoring'},
      {'name': 'Diabetes Checkup', 'price': 800, 'duration': 45, 'description': 'Diabetes screening'},
      {'name': 'ECG Test', 'price': 300, 'duration': 20, 'description': 'Electrocardiogram test'},
      {'name': 'Blood Test', 'price': 500, 'duration': 15, 'description': 'Laboratory blood work'},
      {'name': 'X-Ray', 'price': 600, 'duration': 30, 'description': 'Digital X-ray imaging'},
      {'name': 'Vaccination', 'price': 200, 'duration': 15, 'description': 'Immunization service'},
      {'name': 'Health Checkup', 'price': 2000, 'duration': 60, 'description': 'Complete health screening'},
      {'name': 'Physiotherapy', 'price': 600, 'duration': 45, 'description': 'Physical therapy session'},
      {'name': 'Wound Dressing', 'price': 200, 'duration': 20, 'description': 'Wound care and dressing'}
    ],
    'fitness': [
      {'name': 'Monthly Membership', 'price': 2000, 'duration': 0, 'description': 'Monthly gym membership'},
      {'name': 'Personal Training', 'price': 800, 'duration': 60, 'description': '1-on-1 training session'},
      {'name': 'Group Fitness Class', 'price': 300, 'duration': 60, 'description': 'Group workout class'},
      {'name': 'Yoga Session', 'price': 400, 'duration': 75, 'description': 'Yoga and meditation'},
      {'name': 'Zumba Class', 'price': 350, 'duration': 60, 'description': 'High-energy dance workout'},
      {'name': 'Weight Training', 'price': 500, 'duration': 90, 'description': 'Strength training session'},
      {'name': 'Cardio Session', 'price': 300, 'duration': 45, 'description': 'Cardiovascular workout'},
      {'name': 'Nutrition Consultation', 'price': 1000, 'duration': 45, 'description': 'Diet planning consultation'},
      {'name': 'Body Composition Analysis', 'price': 500, 'duration': 30, 'description': 'Body fat analysis'},
      {'name': 'Fitness Assessment', 'price': 600, 'duration': 45, 'description': 'Complete fitness evaluation'}
    ]
  };

  final List<String> positiveReviews = [
    'Excellent service! Very professional and friendly staff. Highly recommend!',
    'Amazing experience. The quality of service exceeded my expectations.',
    'Great quality service at very reasonable prices. Will definitely visit again.',
    'The staff is incredibly skilled and courteous. Five star service!',
    'Clean and hygienic environment. Professional approach throughout.',
    'Outstanding service quality. Best place in the locality.',
    'Very satisfied with the treatment received. Highly professional.',
    'Wonderful experience from start to finish. Great team!',
    'Top-notch facilities and excellent customer service.',
    'Fantastic results! The staff really knows what they\'re doing.',
    'Superb service quality and great value for money.',
    'Highly skilled professionals. Very impressed with the results.',
    'Perfect service! Clean, professional, and friendly.',
    'Excellent facilities and very experienced staff members.',
    'Amazing service! They really care about customer satisfaction.',
    'Outstanding quality and professional service. Loved it!',
    'Great experience! Will definitely recommend to friends.',
    'Impressive service standards. Very happy with the results.',
    'Professional staff and excellent service quality.',
    'Best service experience I\'ve had. Highly recommended!'
  ];

  final List<String> neutralReviews = [
    'Good service overall. There\'s some room for improvement.',
    'Decent experience. Service quality could be better.',
    'Average service. Nothing particularly special but okay.',
    'Fair experience. Met basic expectations adequately.',
    'Good but not exceptional. Standard service level.',
    'Acceptable service at reasonable pricing.',
    'Okay experience. Could improve on customer service.',
    'Not bad but have experienced better elsewhere.',
    'Standard service quality. Nothing to complain about.',
    'Decent but could be more attentive to details.'
  ];

  final List<String> indianCities = [
    'Mumbai, Maharashtra',
    'Delhi, Delhi',
    'Bangalore, Karnataka',
    'Chennai, Tamil Nadu',
    'Kolkata, West Bengal',
    'Hyderabad, Telangana',
    'Pune, Maharashtra',
    'Ahmedabad, Gujarat',
    'Jaipur, Rajasthan',
    'Lucknow, Uttar Pradesh'
  ];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
      _currentStatus = message;
    });
    print(message);
  }

  String _generateIndianPhone() {
    List<String> prefixes = ['98', '97', '96', '95', '94', '93', '92', '91', '90', '89'];
    String prefix = prefixes[_random.nextInt(prefixes.length)];
    String remaining = '';
    for (int i = 0; i < 8; i++) {
      remaining += _random.nextInt(10).toString();
    }
    return '+91$prefix$remaining';
  }

  String _generateEmail(String name, String type) {
    String cleanName = name.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('\'', '')
        .replaceAll('&', 'and')
        .replaceAll('.', '');
    
    List<String> domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
    String domain = domains[_random.nextInt(domains.length)];
    
    String email = '$cleanName${_random.nextInt(999)}@$domain';
    _credentialsList.add('$email - $type - admin123');
    return email;
  }

  Future<String> _createFirebaseUser(String name, String email, String phone, String type) async {
    try {
      // Try to create user with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'admin123',
      );

      String userId = userCredential.user!.uid;

      // Create user document in Firestore
      UserModel userModel = UserModel(
        id: userId,
        name: name,
        email: email,
        phoneNumber: phone,
        userType: type,
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('users').doc(userId).set(userModel.toJson());
      _addLog('✅ Created $type: $name');
      
      // Sign out immediately to avoid conflicts
      await _auth.signOut();
      
      return userId;
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        _addLog('⚠️ Email exists, skipping: $email');
        return '';
      }
      _addLog('❌ Error creating $name: $e');
      return '';
    }
  }

  Future<void> _populateFirebaseWithBusinessData() async {
    if (_isPopulating) return;
    
    setState(() {
      _isPopulating = true;
      _logs.clear();
      _credentialsList.clear();
      _totalBusinesses = 0;
      _totalCustomers = 0;
      _totalServices = 0;
      _totalReviews = 0;
      _totalOffers = 0;
    });

    try {
      _addLog('🚀 Starting Firebase population with Indian business data...');
      
      List<String> categories = businessNames.keys.toList();
      int businessCount = 8; // Generate 8 businesses
      
      for (int i = 0; i < businessCount; i++) {
        String category = categories[i % categories.length];
        List<String> namesInCategory = List.from(businessNames[category]!);
        String businessName = namesInCategory[_random.nextInt(namesInCategory.length)];
        
        await _createSingleBusinessInFirebase(businessName, category);
        _totalBusinesses++;
        
        // Small delay to avoid Firebase rate limits
        await Future.delayed(Duration(milliseconds: 500));
      }

      await _saveCredentialsFile();
      
      _addLog('🎉 Firebase population completed successfully!');
      _addLog('📊 Summary: $_totalBusinesses businesses, $_totalCustomers customers, $_totalServices services, $_totalReviews reviews, $_totalOffers offers');
      
    } catch (e) {
      _addLog('❌ Error in Firebase population: $e');
    } finally {
      setState(() {
        _isPopulating = false;
      });
    }
  }

  Future<void> _createSingleBusinessInFirebase(String businessName, String category) async {
    _addLog('🏪 Creating business: $businessName ($category)');
    
    // Create business owner
    String ownerName = indianNames[_random.nextInt(indianNames.length)];
    String ownerEmail = _generateEmail('$businessName owner', 'owner');
    String ownerPhone = _generateIndianPhone();
    
    String ownerId = await _createFirebaseUser(ownerName, ownerEmail, ownerPhone, 'business_owner');
    if (ownerId.isEmpty) {
      // Create a mock owner ID if Firebase Auth fails
      ownerId = _firestore.collection('users').doc().id;
      UserModel mockOwner = UserModel(
        id: ownerId,
        name: ownerName,
        email: ownerEmail,
        phoneNumber: ownerPhone,
        userType: 'business_owner',
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      await _firestore.collection('users').doc(ownerId).set(mockOwner.toJson());
    }

    // Create business in Firestore
    String city = indianCities[_random.nextInt(indianCities.length)];
    String businessId = _firestore.collection('businesses').doc().id;
    
    BusinessModel business = BusinessModel(
      id: businessId,
      name: businessName,
      description: 'Professional $category services with experienced staff and modern facilities. We provide high-quality treatments in a clean and comfortable environment.',
      category: category,
      ownerId: ownerId,
      address: '${_random.nextInt(500) + 1}, ${_getRandomStreet()}, ${city.split(', ')[0]}',
      phoneNumber: _generateIndianPhone(),
      email: _generateEmail(businessName, 'business'),
      imageUrls: [],
      galleryUrls: [],
      operatingHours: {
        'monday': '09:00-20:00',
        'tuesday': '09:00-20:00',
        'wednesday': '09:00-20:00',
        'thursday': '09:00-20:00',
        'friday': '09:00-20:00',
        'saturday': '09:00-21:00',
        'sunday': '10:00-18:00',
      },
      maxCustomersPerDay: 50,
      averageServiceTimeMinutes: 30,
      rating: 0.0, // Will be calculated from reviews
      totalRatings: 0,
      reviewCount: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('businesses').doc(businessId).set(business.toJson());
    _addLog('✅ Business created in Firebase: $businessName');

    // Create services for this business
    await _createServicesInFirebase(businessId, category);

    // Create customers and reviews
    await _createCustomersAndReviewsInFirebase(businessId);

    // Create some offers for this business
    await _createOffersInFirebase(businessId, category);
  }

  String _getRandomStreet() {
    List<String> streets = [
      'Main Street', 'MG Road', 'Brigade Road', 'Commercial Street', 'Park Street',
      'Linking Road', 'Hill Road', 'Carter Road', 'Residency Road', 'Church Street',
      'Gandhi Nagar', 'Nehru Place', 'Connaught Place', 'Khan Market', 'Karol Bagh'
    ];
    return streets[_random.nextInt(streets.length)];
  }

  Future<void> _createServicesInFirebase(String businessId, String category) async {
    List<Map<String, dynamic>> availableServices = servicesByCategory[category]!;
    
    // Create all services for this category
    for (var serviceData in availableServices) {
      String serviceId = _firestore.collection('services').doc().id;
      
      ServiceModel service = ServiceModel(
        id: serviceId,
        name: serviceData['name'],
        description: serviceData['description'],
        price: serviceData['price'].toDouble(),
        durationMinutes: serviceData['duration'],
        maxCapacity: 1,
        isActive: true,
      );

      await _firestore.collection('services').doc(serviceId).set(service.toJson());
      _totalServices++;
    }
    
    _addLog('✅ Created ${availableServices.length} services in Firebase');
  }

  Future<void> _createCustomersAndReviewsInFirebase(String businessId) async {
    int customerCount = 25 + _random.nextInt(6); // 25-30 customers
    List<String> customerIds = [];

    // Create customers
    for (int i = 0; i < customerCount; i++) {
      String customerName = indianNames[_random.nextInt(indianNames.length)];
      String customerEmail = _generateEmail(customerName, 'customer');
      String customerPhone = _generateIndianPhone();
      
      String customerId = await _createFirebaseUser(customerName, customerEmail, customerPhone, 'customer');
      if (customerId.isEmpty) {
        // Create mock customer if Firebase Auth fails
        customerId = _firestore.collection('users').doc().id;
        UserModel mockCustomer = UserModel(
          id: customerId,
          name: customerName,
          email: customerEmail,
          phoneNumber: customerPhone,
          userType: 'customer',
          profileImageUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );
        await _firestore.collection('users').doc(customerId).set(mockCustomer.toJson());
      }
      
      if (customerId.isNotEmpty) {
        customerIds.add(customerId);
        _totalCustomers++;
      }
    }

    _addLog('✅ Created ${customerIds.length} customers in Firebase');

    // Create reviews
    int reviewCount = 25 + _random.nextInt(6); // 25-30 reviews
    double totalRating = 0.0;
    
    // Create a list to store customer info for reviews
    List<Map<String, String>> customerInfo = [];
    for (int i = 0; i < customerIds.length; i++) {
      customerInfo.add({
        'id': customerIds[i],
        'name': indianNames[_random.nextInt(indianNames.length)],
        'email': _generateEmail('customer$i', 'review_customer'),
      });
    }

    for (int i = 0; i < reviewCount && i < customerInfo.length; i++) {
      Map<String, String> customer = customerInfo[i];
      
      // Generate realistic ratings (weighted towards positive)
      double rating;
      int ratingType = _random.nextInt(10);
      if (ratingType < 6) { // 60% get 4-5 stars
        rating = 4.0 + _random.nextDouble();
      } else if (ratingType < 9) { // 30% get 3-4 stars
        rating = 3.0 + _random.nextDouble();
      } else { // 10% get 2-3 stars
        rating = 2.0 + _random.nextDouble();
      }
      
      totalRating += rating;

      // Select appropriate review text
      String reviewText;
      if (rating >= 4.0) {
        reviewText = positiveReviews[_random.nextInt(positiveReviews.length)];
      } else {
        reviewText = neutralReviews[_random.nextInt(neutralReviews.length)];
      }

      String reviewId = _firestore.collection('reviews').doc().id;
      
      ReviewModel review = ReviewModel(
        id: reviewId,
        businessId: businessId,
        customerId: customer['id']!,
        customerName: customer['name']!,
        customerEmail: customer['email']!,
        rating: rating,
        comment: reviewText,
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(90))),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('reviews').doc(reviewId).set(review.toJson());
      _totalReviews++;
    }

    // Update business with calculated rating
    double averageRating = totalRating / reviewCount;
    await _firestore.collection('businesses').doc(businessId).update({
      'rating': double.parse(averageRating.toStringAsFixed(1)),
      'totalReviews': reviewCount,
    });

    _addLog('✅ Created $reviewCount reviews (avg rating: ${averageRating.toStringAsFixed(1)})');
  }

  Future<void> _createOffersInFirebase(String businessId, String category) async {
    // Create 2-3 offers per business
    int offerCount = 2 + _random.nextInt(2);
    
    List<String> offerTitles = [
      '20% Off First Visit',
      'Buy 2 Get 1 Free',
      'Special Weekend Discount',
      'New Customer Offer',
      'Festival Special Offer',
      'Combo Package Deal',
      'Student Discount',
      'Senior Citizen Special'
    ];

    List<String> offerDescriptions = [
      'Get 20% discount on your first visit to our salon',
      'Book any 2 services and get the 3rd one absolutely free',
      'Special 15% discount available on weekends',
      'New customers get 25% off on all services',
      'Celebrate festivals with our special discount offers',
      'Book our combo package and save more',
      'Students get 10% discount on all services',
      'Special pricing for senior citizens'
    ];

    for (int i = 0; i < offerCount; i++) {
      String offerId = _firestore.collection('offers').doc().id;
      
      DateTime startDate = DateTime.now().subtract(Duration(days: _random.nextInt(30)));
      DateTime endDate = DateTime.now().add(Duration(days: 30 + _random.nextInt(60)));
      
      OfferModel offer = OfferModel(
        id: offerId,
        businessId: businessId,
        title: offerTitles[_random.nextInt(offerTitles.length)],
        description: offerDescriptions[_random.nextInt(offerDescriptions.length)],
        posterUrl: null,
        discountPercentage: _random.nextBool() ? 20.0 : null,
        originalPrice: _random.nextBool() ? 1000.0 : null,
        discountedPrice: _random.nextBool() ? 800.0 : null,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        terms: ['Valid for limited time', 'Cannot be combined with other offers'],
        category: 'discount',
      );

      await _firestore.collection('offers').doc(offerId).set(offer.toJson());
      _totalOffers++;
    }
    
    _addLog('✅ Created $offerCount offers in Firebase');
  }

  Future<void> _saveCredentialsFile() async {
    try {
      String content = '''# 🇮🇳 INDIAN BUSINESS DATA - FIREBASE CREDENTIALS
# Generated on: ${DateTime.now()}
# Format: Email - Type - Password
# Password for ALL accounts: admin123

=================================================================
                    📊 SUMMARY
=================================================================
Total Businesses: $_totalBusinesses
Total Business Owners: $_totalBusinesses  
Total Customers: $_totalCustomers
Total Services: $_totalServices
Total Reviews: $_totalReviews
Total Offers: $_totalOffers
Total Accounts: ${_credentialsList.length}

=================================================================
                    🔑 LOGIN CREDENTIALS
=================================================================
${_credentialsList.join('\n')}

=================================================================
                    📝 FIREBASE DATA POPULATED
=================================================================
✅ All data has been automatically populated in Firebase
✅ Users collection: Business owners and customers
✅ Businesses collection: Complete business profiles
✅ Services collection: Realistic services with Indian pricing
✅ Reviews collection: Genuine reviews with ratings
✅ Offers collection: Promotional offers for businesses

=================================================================
                    🚀 READY TO USE
=================================================================
Your ZapQ app is now populated with realistic Indian business data!
You can immediately start using the app with these credentials.

Generated with ❤️ for ZapQ Indian Business Database
=================================================================
''';

      // Try to save to file (may not work on all platforms)
      try {
        File file = File('firebase_indian_business_credentials.txt');
        await file.writeAsString(content);
        _addLog('✅ Credentials saved to file: ${file.path}');
      } catch (e) {
        _addLog('ℹ️ Credentials shown in UI (file save not available)');
      }
      
    } catch (e) {
      _addLog('❌ Error saving credentials: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🇮🇳 Firebase Business Data Populator'),
        backgroundColor: Colors.blue[700],
        elevation: 4,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.orange, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Firebase Auto-Populator',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Status: $_currentStatus',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue[700]),
                    ),
                    SizedBox(height: 12),
                    Text('This will automatically populate Firebase with:', style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    _buildFeatureRow('🏢', '8 Indian businesses (different categories)'),
                    _buildFeatureRow('👥', '200+ customers with Indian names'),
                    _buildFeatureRow('🛠️', '50+ services with realistic INR pricing'),
                    _buildFeatureRow('⭐', '200+ genuine reviews and ratings'),
                    _buildFeatureRow('🎁', '20+ promotional offers'),
                    _buildFeatureRow('🔑', 'All passwords: admin123'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPopulating ? null : _populateFirebaseWithBusinessData,
                child: _isPopulating 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Populating Firebase...', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload),
                        SizedBox(width: 8),
                        Text('Populate Firebase with Indian Business Data', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isPopulating ? Colors.grey : Colors.blue[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Progress Stats
            if (_isPopulating || _totalBusinesses > 0)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Businesses', _totalBusinesses.toString()),
                      _buildStatColumn('Customers', _totalCustomers.toString()),
                      _buildStatColumn('Services', _totalServices.toString()),
                      _buildStatColumn('Reviews', _totalReviews.toString()),
                      _buildStatColumn('Offers', _totalOffers.toString()),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 16),
            
            // Logs
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      child: Text(
                        'Firebase Population Log',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(8.0),
                        itemCount: _logs.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          String log = _logs[_logs.length - 1 - index];
                          Color textColor = Colors.black87;
                          if (log.contains('✅')) textColor = Colors.green[700]!;
                          if (log.contains('❌')) textColor = Colors.red[700]!;
                          if (log.contains('⚠️')) textColor = Colors.orange[700]!;
                          if (log.contains('🎉')) textColor = Colors.purple[700]!;
                          
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontSize: 12, 
                                fontFamily: 'monospace',
                                color: textColor,
                              ),
                            ),
                          );
                        },
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

  Widget _buildFeatureRow(String icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700]),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}