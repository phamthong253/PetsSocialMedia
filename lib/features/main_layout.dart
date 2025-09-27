import 'package:flutter/material.dart';
import 'package:quanlythucung/features/3_profile/screens/profile_screen.dart';
import 'package:quanlythucung/features/4_pet/screens/my_pet_screen.dart';
import 'package:quanlythucung/features/5_post/presentation/screens/home_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Danh sách các màn hình con tương ứng với các tab
  // Sử dụng IndexedStack để giữ trạng thái của các màn hình khi chuyển tab
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MyPetsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Thú cưng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Đảm bảo label luôn hiển thị
      ),
    );
  }
}
