import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'layanan_screen.dart';
import 'jadwal_screen.dart';
import 'pusat_informasi_screen.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MainScreen({super.key, required this.userData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(userData: widget.userData),
      LayananScreen(userData: widget.userData),
      JadwalScreen(userData: widget.userData),
      const PusatInformasiScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Tagihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Layanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
        ],
      ),
    );
  }
}