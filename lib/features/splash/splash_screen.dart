import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _showOnboarding = false;
  bool _isError = false;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Easy Hotel Booking',
      'desc': 'Search and book hotels in seconds.',
      'image': 'assets/images/onboarding1.png',
    },
    {
      'title': 'Best Deals',
      'desc': 'Get exclusive discounts and offers.',
      'image': 'assets/images/onboarding2.png',
    },
    {
      'title': 'Real Reviews',
      'desc': 'Read trusted reviews before booking.',
      'image': 'assets/images/onboarding3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('onboarding_done') ?? false;

      // Wait for AuthProvider to finish loading user
      await Future.doWhile(() async {
        if (!authProvider.isLoading) return false;
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      });

      // Navigate based on auth and onboarding status
      if (mounted) {
        if (authProvider.isAuthenticated) {
          Navigator.pushReplacementNamed(
              context, authProvider.isAdmin ? '/admin' : '/home');
        } else if (seen) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          setState(() => _showOnboarding = true);
        }
      }
    } catch (e) {
      debugPrint("Error in splash screen: $e");
      if (mounted) {
        setState(() => _isError = true);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signup');
      }
    } catch (e) {
      debugPrint("Error completing onboarding: $e");
      if (mounted) {
        setState(() => _isError = true);
      }
    }
  }

  Future<void> _retry() async {
    setState(() => _isError = false);
    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Something went wrong", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : _showOnboarding
              ? _buildOnboarding()
              : _buildSplash(),
    );
  }

  Widget _buildSplash() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.hotel,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Hotel Booking App",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text(
                "Log In",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboarding() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        final contentWidth = isWideScreen ? constraints.maxWidth * 0.6 : constraints.maxWidth * 0.9;

        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  final item = onboardingData[index];
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          item['image']!,
                          height: isWideScreen ? 400 : 300,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: isWideScreen ? 400 : 300,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 100),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          item['title']!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            item['desc']!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 12 : 8,
                  height: _currentIndex == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? Colors.indigo : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      "Skip",
                      style: TextStyle(color: Colors.indigo, fontSize: 16),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          "Log In",
                          style: TextStyle(color: Colors.indigo, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentIndex == onboardingData.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _currentIndex == onboardingData.length - 1 ? "Get Started" : "Next",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}