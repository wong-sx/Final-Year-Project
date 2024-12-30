
import 'package:flutter/material.dart';
import 'package:fyp/pages/homepage.dart';
import 'package:fyp/pages/login.dart';
import 'package:fyp/pages/account_profile.dart'; // Import AccountProfilePage
import 'package:fyp/pages/register.dart';
import 'package:fyp/pages/forgotPassword.dart';
import 'package:provider/provider.dart';
import 'package:fyp/providers/location_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/add_place.dart';
import 'package:fyp/pages/saved_place.dart';
import 'package:fyp/pages/navigation_history.dart';
import 'package:fyp/pages/register_emergency_contact.dart';
import 'package:fyp/providers/weather_provider.dart';
import 'package:fyp/pages/drowsiness_detection.dart';
import 'package:fyp/pages/drowsiness_detection_usageList.dart';
import 'package:fyp/pages/admin_page.dart';
import 'package:fyp/services/drowsiness_detection_service.dart';

import 'package:fyp/pages/weather.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures binding before Firebase initialization
  await Firebase.initializeApp(); // Initializes Firebase
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => DetectionService()..initialize()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // Set the Firebase Auth locale
    FirebaseAuth.instance.setLanguageCode('en'); // Set to the desired language code, e.g., 'en' for English

    
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: AuthGate(), // Checks auth state before navigating
    
      routes: {
        '/account': (context) => const AccountProfilePage(), // Route to Account Profile Page
        /*
        '/savePlace': (context) => const SavePlacePage(), // Route to Save Place Page
        '/navigationHistory': (context) => const NavigationHistoryPage(), // Route to Navigation History Page
        '/drowsinessReport': (context) => const DrowsinessReportPage(), // Route to Drowsiness Report Page
        */
        
        '/adminPage': (context) => AdminPage(),
        '/drowsiness': (context) => DrowsinessDetectionPage(),
        '/emergency': (context) => RegisterEmergencyContactPage(),
        '/navigationHistory': (context) => const NavigationHistoryPage(),
        '/savedPlaces': (context) => const SavedPlacesPage(),
        '/addPlace': (context) => const AddPlacePage(),
        '/drowsinessReport' : (context) => UsageListPage(),
        '/login': (context) => const LoginPage(), // Route to Login Page
        '/register': (context) => const RegisterPage(), // Register route
        '/forgotPassword': (context) => ForgotPasswordPage(), // Forgot Password route
        '/home': (context) => const HomePage(), // Route to Home Page
        '/weather': (context) =>  WeatherPage(), // Route to Home Page
      },
    );
  }
}

// AuthGate widget to determine if the user is logged in or not
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading spinner while waiting for the auth state
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // If user is logged in, show the HomePage
          return const HomePage();
        } else {
          // If user is not logged in, show the LoginPage
          return const LoginPage();
        }
      },
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:fyp/pages/homepage.dart';
import 'package:fyp/pages/login.dart';
import 'package:fyp/pages/account_profile.dart'; // Import AccountProfilePage
import 'package:fyp/pages/register.dart';
import 'package:fyp/pages/forgotPassword.dart';
import 'package:provider/provider.dart';
import 'package:fyp/providers/location_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/pages/add_place.dart';
import 'package:fyp/pages/saved_place.dart';
import 'package:fyp/pages/navigation_history.dart';
import 'package:fyp/pages/register_emergency_contact.dart';
import 'package:fyp/providers/weather_provider.dart';
import 'package:fyp/pages/drowsiness_detection.dart';
import 'package:fyp/pages/drowsiness_detection_usageList.dart';
import 'package:fyp/pages/admin_page.dart';
import 'package:fyp/services/drowsiness_detection_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:fyp/services/drowsiness_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures binding before Firebase initialization
  await Firebase.initializeApp(); // Initializes Firebase
  await initializeService(); // Initialize the background service

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => DrowsinessDetectionService()..init()),
      ],
      child: const MyApp(),
    ),
  );
}

/// This function sets up the background service to handle drowsiness detection
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'drowsiness_detection_service', // Must match with MainActivity
      initialNotificationTitle: 'Drowsiness Detection Running',
      initialNotificationContent: 'The detection system is monitoring for drowsiness.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );

  // Start the service
  service.startService();
}

/// This function runs when the background service starts
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService(); // Ensures the service runs in the foreground

    // Allow the service to be managed from other parts of the app
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Additional code to run your detection logic in the background can be added here
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: const AuthGate(), // Checks auth state before navigating
      routes: {
        '/account': (context) => const AccountProfilePage(), // Route to Account Profile Page
        '/adminPage': (context) => AdminPage(),
        '/drowsiness': (context) => DrowsinessDetectionPage(),
        '/emergency': (context) => RegisterEmergencyContactPage(),
        '/navigationHistory': (context) => const NavigationHistoryPage(),
        '/savedPlaces': (context) => const SavedPlacesPage(),
        '/addPlace': (context) => const AddPlacePage(),
        '/drowsinessReport': (context) => UsageListPage(),
        '/login': (context) => const LoginPage(), // Route to Login Page
        '/register': (context) => const RegisterPage(), // Register route
        '/forgotPassword': (context) => ForgotPasswordPage(), // Forgot Password route
        '/home': (context) => const HomePage(), // Route to Home Page
      },
    );
  }
}

// AuthGate widget to determine if the user is logged in or not
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading spinner while waiting for the auth state
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // If user is logged in, show the HomePage
          return const HomePage();
        } else {
          // If user is not logged in, show the LoginPage
          return const LoginPage();
        }
      },
    );
  }
}
*/
