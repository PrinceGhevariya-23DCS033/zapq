import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Configure GoogleSignIn - remove clientId to use default from google-services.json
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isCustomer => _userModel?.userType == 'customer';
  bool get isBusinessOwner => _userModel?.userType == 'business_owner';

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    if (_user == null) {
      print('❌ Cannot load user data: _user is null');
      return;
    }

    try {
      print('🔍 Loading user data for: ${_user!.uid}');
      print('📧 User email: ${_user!.email}');
      
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      
      if (doc.exists) {
        final data = doc.data();
        print('📄 Raw Firestore data: $data');
        
        _userModel = UserModel.fromJson(data!);
        print('✅ User model created: ${_userModel!.toJson()}');
        print('🏷️ User type from model: ${_userModel!.userType}');
        print('👤 User name: ${_userModel!.name}');
        
        notifyListeners();
      } else {
        print('❌ User document not found in Firestore for UID: ${_user!.uid}');
        _setError('User profile not found. Please contact support.');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Temporary fallback: Create a default user profile based on email
      print('🔄 Creating temporary user profile...');
      final email = _user!.email ?? '';
      
      // Determine user type based on email pattern or create business owner by default
      String userType = 'business_owner'; // Default to business owner for testing
      if (email.contains('customer') || email.contains('user')) {
        userType = 'customer';
      }
      
      _userModel = UserModel(
        id: _user!.uid,
        email: email,
        name: _user!.displayName ?? 'User',
        phoneNumber: '',
        userType: userType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('✅ Temporary user profile created: ${_userModel!.toJson()}');
      notifyListeners();
      
      // Try to save to Firestore when it becomes available
      _attemptFirestoreSave();
    }
  }

  // Attempt to save user data to Firestore (for when API becomes available)
  Future<void> _attemptFirestoreSave() async {
    if (_userModel == null || _user == null) return;
    
    try {
      await _firestore.collection('users').doc(_user!.uid).set(_userModel!.toJson());
      print('✅ Successfully saved user data to Firestore');
    } catch (e) {
      print('⚠️ Could not save to Firestore yet: $e');
    }
  }

  // Debug method to check all users in Firestore
  Future<void> debugCheckAllUsers() async {
    try {
      print('🔍 Checking all users in Firestore...');
      final querySnapshot = await _firestore.collection('users').get();
      print('📊 Total users found: ${querySnapshot.docs.length}');
      
      for (var doc in querySnapshot.docs) {
        print('👤 User ${doc.id}: ${doc.data()}');
      }
    } catch (e) {
      print('❌ Error checking users: $e');
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      print('🔐 Starting login for: $email');

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase authentication successful');
      _user = result.user;
      
      // Load user data and wait for it to complete
      await loadUserData();
      
      // Verify user data was loaded (either from Firestore or temporary profile)
      if (_userModel == null) {
        print('❌ User model is still null after loadUserData');
        _setError('Failed to load user profile. Please try again.');
        return false;
      }

      print('✅ Login complete - User type: ${_userModel!.userType}');
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      print('❌ Login error: $e');
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String userType,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      print('🔐 Starting email registration...');
      print('📧 Email: $email');
      print('👤 Name: $name');
      print('📱 Phone: $phoneNumber');
      print('🏷️ Type: $userType');
      print('🔒 Password length: ${password.length}');

      // Validate inputs
      if (email.isEmpty || !email.contains('@')) {
        _setError('Please enter a valid email address.');
        return false;
      }
      
      if (password.length < 6) {
        _setError('Password must be at least 6 characters long.');
        return false;
      }

      if (name.isEmpty) {
        _setError('Please enter your name.');
        return false;
      }

      print('✅ Input validation passed');

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase user created: ${result.user?.uid}');
      print('📧 Firebase user email: ${result.user?.email}');

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(name);
        print('✅ Display name updated: $name');
        
        _user = result.user;
        
        // Create user model
        _userModel = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          userType: userType,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save user data to Firestore
        print('💾 Saving user data to Firestore...');
        print('📄 User data: ${_userModel!.toJson()}');
        await _firestore.collection('users').doc(result.user!.uid).set(_userModel!.toJson());
        print('✅ User data saved to Firestore successfully');

        // Verify the data was saved
        final savedDoc = await _firestore.collection('users').doc(result.user!.uid).get();
        if (savedDoc.exists) {
          print('✅ Verification: User data exists in Firestore');
          print('📄 Saved data: ${savedDoc.data()}');
        } else {
          print('❌ Verification failed: User data not found in Firestore');
        }

        print('✅ User model created successfully');
        print('🎉 Registration completed for: ${_userModel!.email}');
        return true;
      }
      
      print('❌ Failed to create user account - result.user is null');
      _setError('Failed to create user account.');
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException during registration:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      
      String errorMessage = _getAuthErrorMessage(e.code);
      print('   User message: $errorMessage');
      _setError(errorMessage);
      return false;
    } catch (e) {
      print('❌ Unexpected error during registration: $e');
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      print('🔍 Starting Google Sign-In process...');
      print('📱 Package name: com.zappq.queue');

      // Sign out first to ensure clean state
      await _googleSignIn.signOut();
      print('🚪 Cleared existing Google session');

      // Attempt sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Google sign-in was cancelled by user');
        _setError('Google sign-in was cancelled.');
        return false;
      }

      print('👤 Google user obtained: ${googleUser.email}');
      print('🆔 Google ID: ${googleUser.id}');
      print('📧 Display name: ${googleUser.displayName}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('🔑 Access token available: ${googleAuth.accessToken != null}');
      print('🎫 ID token available: ${googleAuth.idToken != null}');

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('❌ Missing Google authentication tokens');
        _setError('Failed to get Google authentication tokens.');
        return false;
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔗 Firebase credential created, signing in...');

      // Sign in to Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);
      _user = result.user;

      if (_user != null) {
        print('✅ Firebase sign-in successful: ${_user!.uid}');
        print('📧 Firebase user email: ${_user!.email}');

        // Check if user already exists in Firestore
        final existingDoc = await _firestore.collection('users').doc(_user!.uid).get();
        
        if (existingDoc.exists) {
          // Load existing user data
          _userModel = UserModel.fromJson(existingDoc.data()!);
          print('✅ Loaded existing user from Firestore');
        } else {
          // Create new user model
          _userModel = UserModel(
            id: _user!.uid,
            email: _user!.email ?? '',
            name: _user!.displayName ?? 'User',
            phoneNumber: _user!.phoneNumber ?? '',
            userType: 'customer',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Save new user data to Firestore
          await _firestore.collection('users').doc(_user!.uid).set(_userModel!.toJson());
          print('✅ New user data saved to Firestore successfully');
        }

        print('🎉 Google Sign-In completed successfully');
        return true;
      }

      print('❌ Firebase user is null after sign-in');
      _setError('Failed to complete Google sign-in.');
      return false;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      print('❌ Google Sign-In Error Details: $e');
      String errorString = e.toString();
      
      if (errorString.contains('ApiException: 10')) {
        print('🔧 Error 10: DEVELOPER_ERROR - SHA-1 fingerprint mismatch');
        print('🔧 Current SHA-1: 2B:EE:1C:95:A3:A8:86:48:4C:7C:15:90:A3:4C:AD:2E:EA:BD:A3:BE');
        print('🔧 Registered SHA-1: d07c939a6fee4e208e9b22ad8c7e0619e1045bd8');
        _setError('Google Sign-In temporarily unavailable. Please use email/password login.');
      } else if (errorString.contains('ApiException: 7')) {
        print('🔧 Error 7: NETWORK_ERROR');
        _setError('Network error. Please check your internet connection.');
      } else if (errorString.contains('ApiException: 8')) {
        print('🔧 Error 8: INTERNAL_ERROR');
        _setError('Google services internal error. Please try again.');
      } else if (errorString.contains('ApiException: 12500')) {
        print('🔧 Error 12500: SIGN_IN_REQUIRED');
        _setError('Please try signing in again.');
      } else if (errorString.contains('PlatformException')) {
        print('🔧 Platform Exception - Check Google Play Services');
        _setError('Google Play Services required. Please update Google Play Services.');
      } else {
        _setError('Google Sign-In failed. Please try email/password login.');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check Google Sign-In configuration
  Future<bool> checkGoogleSignInConfiguration() async {
    try {
      print('🔍 Checking Google Sign-In configuration...');
      print('📱 Package name: com.zappq.queue');
      print('🔑 Current SHA-1: 2B:EE:1C:95:A3:A8:86:48:4C:7C:15:90:A3:4C:AD:2E:EA:BD:A3:BE');
      print('🔑 Registered SHA-1: d07c939a6fee4e208e9b22ad8c7e0619e1045bd8');
      
      // Try to get current signed in account
      final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        print('✅ User already signed in: ${currentUser.email}');
        return true;
      }
      
      // Try silent sign-in
      final GoogleSignInAccount? silentUser = await _googleSignIn.signInSilently();
      if (silentUser != null) {
        print('✅ Silent sign-in successful: ${silentUser.email}');
        return true;
      }
      
      print('⚠️ Google Sign-In requires manual authorization');
      return false;
    } catch (e) {
      print('❌ Google Sign-In configuration check failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _user = null;
      _userModel = null;
    } catch (e) {
      _setError('Sign out failed. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Email address is invalid.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'account-exists-with-different-credential':
        return 'Account exists with different sign-in method.';
      case 'invalid-credential':
        return 'Invalid sign-in credentials.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication error: $errorCode';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
