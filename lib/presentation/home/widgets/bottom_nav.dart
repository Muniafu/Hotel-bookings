import 'package:flutter/material.dart';
import 'package:bookings/presentation/home/home.dart';
import 'package:bookings/presentation/home/profile.dart';
import 'package:bookings/presentation/search/search.dart';
import 'package:bookings/providers/navigation.dart';
import 'package:provider/provider.dart';

import '../../../providers/hotel.dart';

class BottomBar extends StatelessWidget {
  BottomBar({
    super.key,
  });
  final List<Widget> currentTab = [
    MyHomePage(title: 'Hotel Page'),
    const SearchScreen(title: '',),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HotelProvider()),
        ChangeNotifierProvider(
            create: (context) => BottomNavigationBarProvider()),
      ],
      child: Consumer<BottomNavigationBarProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            body: currentTab[provider.currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: provider.currentIndex,
              onTap: (index) {
                provider.currentIndex = index;
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}