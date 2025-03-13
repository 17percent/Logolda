import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/firebase/auth_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StandingsPage extends StatefulWidget {
  const StandingsPage({super.key});

  @override
  _StandingsPageState createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  Map<String, Map<String, dynamic>> _standings = {};

  @override
  void initState() {
    super.initState();
    user = _authService.getLoggedInUser();
    _fetchUsers();
  }
  
  Future _fetchUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Users').get();
      setState(() {
        _standings = {
          for (var doc in snapshot.docs)
            doc['uid']: {'username': doc['name'], 'seed': doc['seeds']}
        };
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void _sortMappedUsers() {
    var sortedEntries = _standings.entries.toList()
      ..sort((a, b) => b.value['seed'].compareTo(a.value['seed']));
    _standings = Map.fromEntries(sortedEntries);
  }

  AppBar _buildAppBar() {
    return AppBar(
      actions: [
        // Info button is needed
      ],
      backgroundColor: AppColors.coolGrey,
      toolbarHeight: 80,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded,
              size: 60, color: AppColors.antiFlashWhite),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem('Események', Icons.home_rounded,
              () => Navigator.pushNamed(context, '/home')),
          _buildDrawerItem('Új esemény', Icons.task_rounded,
              () => Navigator.pushNamed(context, '/create')),
          _buildDrawerItem('Új kategória', Icons.category_rounded,
              () => Navigator.pushNamed(context, '/category')),
          _buildDrawerItem('Archívum', Icons.archive_rounded,
              () => Navigator.pushNamed(context, '/archive')),
          _buildDrawerItem('Eredménytábla', Icons.leaderboard_rounded,
              () => Navigator.pushNamed(context, '/standings')),
          _buildDrawerItem('Kijelentkezés', Icons.logout_rounded, () {
            _authService.signOut();
            Navigator.pushReplacementNamed(context, '/');
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return SizedBox(
      height: 250,
      child: DrawerHeader(
        decoration: const BoxDecoration(color: AppColors.coolGrey),
        child: Column(
          children: [
            Image.asset('assets/drawer_logo.png', height: 100),
            const Text(
              'LOGOLDA',
              style: TextStyle(color: AppColors.antiFlashWhite, fontSize: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      leading: Icon(icon, color: AppColors.spaceCadet, size: 30),
      title: Text(title,
          style: const TextStyle(color: AppColors.spaceCadet, fontSize: 18)),
      onTap: onTap,
    );
  }

  Widget _buildStandings() {
    if (_standings.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        decoration: customBoxDeoration(AppColors.antiFlashWhite, 18),
        child: const Text(
          'Nincs megjeleníthető adat.',
          style: TextStyle(color: AppColors.spaceCadet, fontSize: 16),
        ),
      );
    } else {
      _sortMappedUsers();
    return Column(
      children: _standings.entries.map((entry) {
      int index = _standings.keys.toList().indexOf(entry.key);
      BoxDecoration decoration;
      if (index == 0) {
        decoration = customBoxDeoration(AppColors.goldYellow, 18);
      } else if (index == 1) {
        decoration = customBoxDeoration(AppColors.silverGrey, 18);
      } else if (index == 2) {
        decoration = customBoxDeoration(AppColors.bronzeBrown, 18);
      } else {
        decoration = customBoxDeoration(AppColors.antiFlashWhite, 18);
      }
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
        decoration: decoration,
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
          child: Text(
            (index + 1).toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.spaceCadet, fontSize: 16),
          ),
          ),
          Expanded(
          child: Text(
            entry.value['seed'].floor().toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.spaceCadet, fontSize: 16),
          ),
          ),
          Expanded(
          child: Text(
            entry.value['username'],
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.spaceCadet, fontSize: 16),
          ),
          ),
        ],
        ),
      );
      }).toList(),
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceCadet,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.public_rounded,
                      size: 100,
                      color: AppColors.antiFlashWhite.withOpacity(0.2)),
                  const Text('Eredménytábla',
                      style: TextStyle(
                          fontSize: 28, color: AppColors.antiFlashWhite)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Helyezés',
                    style: TextStyle(
                        color: AppColors.antiFlashWhite, fontSize: 16)),
                SizedBox(width: 10),
                Text('Seed',
                    style: TextStyle(
                        color: AppColors.antiFlashWhite, fontSize: 16)),
                SizedBox(width: 10),
                Text('Felhasználó',
                    style: TextStyle(
                        color: AppColors.antiFlashWhite, fontSize: 16)),
              ],
            ),
            _buildStandings(),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

BoxDecoration customBoxDeoration(Color color, double radius) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: color,
    boxShadow: [
      BoxShadow(
        blurRadius: 10,
        blurStyle: BlurStyle.normal,
        color: Colors.black.withOpacity(0.5),
        offset: const Offset(0, 5),
        spreadRadius: 0,
      )
    ],
  );
}


