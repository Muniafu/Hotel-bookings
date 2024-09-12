import 'package:bookings/presentation/authentication/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:bookings/presentation/authentication/screens/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bookings/presentation/home/home.dart';
import 'package:bookings/presentation/home/widgets/bottom_nav.dart';
import 'package:bookings/presentation/onboarding/onboarding.dart';
import 'package:bookings/providers/booking.dart';
import 'package:bookings/providers/hotel.dart';
import 'package:bookings/providers/navigation.dart';
import 'core/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:bookings/providers/auth.dart';
import 'presentation/authentication/screens/admin.dart';
import 'presentation/authentication/screens/login.dart';
import 'presentation/dashboard/add_hotels.dart';
import 'presentation/dashboard/widgets/bottom_nav.dart';
import 'presentation/home/profile.dart';
import 'providers/admin.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
            create: (context) => BottomNavigationBarProvider()),
        ChangeNotifierProvider(
          create: (context) => AdminProvider(),
        ),
        ChangeNotifierProvider(create: (context) => HotelProvider()),
        ChangeNotifierProvider(create: (context) => BookingProvider()),
      ],
      child: const Hotel(),
    ),
  );
}
class Hotel extends StatelessWidget {
  const Hotel({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Muniafu Hotel',
      themeMode: ThemeMode.system,
      theme: AppTheme.theme,
      home: authProvider.isLoggedIn ? BottomBar() : const WelcomeScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => MyHomePage(title: 'Hotel Page'),
        '/signUp': (context) => const SignUpScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => AdminScreen(),
        '/addHotels': (context) => const AddHotelScreen(),
        '/bottomNav': (context) => const BottomNavAdmin(),
      },
    );
  }
}