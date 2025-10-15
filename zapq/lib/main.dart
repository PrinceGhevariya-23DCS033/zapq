import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/user_provider.dart';
import 'shared/providers/enhanced_business_provider.dart';
import 'shared/providers/booking_provider.dart';
import 'shared/providers/slot_provider.dart';
import 'shared/providers/queue_provider.dart';
import 'shared/providers/offer_provider.dart';
import 'features/authentication/presentation/pages/splash_page.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/authentication/presentation/pages/register_page.dart';
import 'features/authentication/presentation/pages/role_selection_page.dart';
import 'features/customer/presentation/pages/customer_home_page.dart';
import 'features/business_owner/presentation/pages/business_home_page.dart';
import 'features/business_owner/presentation/pages/business_registration_page.dart';
import 'features/business_owner/presentation/pages/service_management_page.dart';
import 'features/business_owner/presentation/pages/business_edit_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only if not already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase is already initialized, which is fine
    if (!e.toString().contains('duplicate-app')) {
      // If it's not a duplicate app error, rethrow
      rethrow;
    }
  }
  
  runApp(const ZapQApp());
}

class ZapQApp extends StatelessWidget {
  const ZapQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SlotProvider()),
        ChangeNotifierProvider(create: (_) => QueueProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        final userType = state.uri.queryParameters['userType'];
        return RegisterPage(userType: userType);
      },
    ),
    GoRoute(
      path: '/customer-home',
      builder: (context, state) => const CustomerHomePage(),
    ),
    GoRoute(
      path: '/business-home',
      builder: (context, state) => const BusinessHomePage(),
    ),
    GoRoute(
      path: '/business-registration',
      builder: (context, state) => const BusinessRegistrationPage(),
    ),
    GoRoute(
      path: '/service-management/:businessId',
      builder: (context, state) {
        final businessId = state.pathParameters['businessId']!;
        return ServiceManagementPage(businessId: businessId);
      },
    ),
    GoRoute(
      path: '/business-edit/:businessId',
      builder: (context, state) {
        final businessId = state.pathParameters['businessId']!;
        return BusinessEditPage(businessId: businessId);
      },
    ),
  ],
);
