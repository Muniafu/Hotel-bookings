import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import './providers/auth_provider.dart' as app;
import './providers/hotel_provider.dart';
import './providers/booking_provider.dart';
import './providers/payment_provider.dart';
import './providers/notification_provider.dart';
import './services/payment_service.dart';
import './services/notification_service.dart';
import './models/room_model.dart';
import './models/hotel_model.dart';
import './features/splash/splash_screen.dart';
import './features/auth/login_screen.dart';
import './features/auth/signup_screen.dart';
import './features/booking/booking_screen.dart';
import './features/booking/confirmation_screen.dart';
import './features/home/home_screen.dart';
import './features/hotel_detail/hotel_detail_screen.dart';
import './features/profile/profile_screen.dart';
import './features/admin/admin_dashboard_screen.dart';
import './features/admin/manage_bookings_screen.dart';
import './features/admin/manage_properties_screen.dart';
import './features/profile/my_bookings_screen.dart';
import './features/profile/wishlist_screen.dart';
import './features/admin/add_edit_property_screen.dart';
import './features/admin/analytics_dashboard_screen.dart';
import './features/review/submit_review_screen.dart';
import './features/admin/send_notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  final notificationService = NotificationService();
  await notificationService.initFCM();

  final paymentService = PaymentService(
    paystackPublicKeyTest: 'pk_test_94b67a918deefd624913bd5a2a378a5131a4e5c4',
    paystackSecretKey: 'sk_test_1234567890abcdef1234567890abcdef12345678',
    isSandbox: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app.AuthProvider()),
        ChangeNotifierProvider(create: (_) => HotelProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider(paymentService)),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Booking App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/wishlist': (context) => const WishlistScreen(),
        '/my-bookings': (context) => const MyBookingsScreen(),
        '/submit-review': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SubmitReviewScreen(
            bookingId: args['bookingId'],
            hotelId: args['hotelId'],
          );
        },
        '/admin': (context) => Provider.of<app.AuthProvider>(context).isAdmin
            ? const AdminDashboardScreen()
            : const HomeScreen(),
        '/admin/properties': (context) => const ManagePropertiesScreen(),
        '/admin/bookings': (context) => const ManageBookingsScreen(),
        '/admin/add-property': (context) => const AddEditPropertyScreen(),
        '/admin/analytics': (context) => const AnalyticsDashboardScreen(),
        '/admin/send-notification': (context) => const SendNotificationScreen(),
        '/hotel-detail': (context) {
          final hotel = ModalRoute.of(context)!.settings.arguments as HotelModel;
          return HotelDetailScreen(hotel: hotel);
        },
        '/booking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BookingScreen(
            room: args['room'] as RoomModel,
            hotel: args['hotel'] as HotelModel,
          );
        },
        '/confirmation': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ConfirmationScreen(
            bookingId: args['bookingId'],
            paymentId: args['paymentId'],
          );
        },
      },
    );
  }
}