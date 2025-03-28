import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/util/styles.dart';
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

  Widget _buildUserStanding() {
    final keyUser = user?.uid;
    if (keyUser == null || !_standings.containsKey(keyUser)) {
      return const CircularProgressIndicator();
    } else {
      _sortMappedUsers();
      final userStanding = _standings[keyUser];
      if (userStanding == null) {
        return const CircularProgressIndicator();
      }
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 10, 24, 10),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    (_standings.keys.toList().indexOf(keyUser) + 1).toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.antiFlashWhite,
                        fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userStanding['seed'].floor().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.antiFlashWhite, fontSize: 16),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.spa_rounded,
                          color: AppColors.antiFlashWhite, size: 20),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    userStanding['username'],
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.antiFlashWhite, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStandings() {
    if (_standings.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        decoration: AppStyles.customBoxDecoration(AppColors.antiFlashWhite, 18),
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
          Color decorationColor;

          switch (index) {
            case 0:
              decorationColor = AppColors.goldYellow;
              break;
            case 1:
              decorationColor = AppColors.silverGrey;
              break;
            case 2:
              decorationColor = AppColors.bronzeBrown;
              break;
            default:
              decorationColor = AppColors.antiFlashWhite;
          }

          BoxDecoration decoration =
              AppStyles.customBoxDecoration(decorationColor, 18);
          if (entry.key == user!.uid) {
            decoration = decoration.copyWith(
              border: Border.all(color: AppColors.pantoneRed, width: 3),
            );
          }
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
            decoration: decoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    (index + 1).toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.spaceCadet,
                        fontSize: 16),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.value['seed'].floor().toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.spaceCadet, fontSize: 16),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.spa_rounded,
                          color: AppColors.coolGrey, size: 20),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value['username'],
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.spaceCadet, fontSize: 16),
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
              Column(
                children: [
                  Icon(Icons.leaderboard_rounded,
                      color: AppColors.antiFlashWhite, size: 30),
                  SizedBox(height: 5),
                  Text('Helyezés',
                      style: TextStyle(
                          color: AppColors.antiFlashWhite, fontSize: 16)),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.spa_rounded,
                      color: AppColors.antiFlashWhite, size: 30),
                  SizedBox(height: 5),
                  Text('Seed',
                      style: TextStyle(
                          color: AppColors.antiFlashWhite, fontSize: 16)),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.account_circle_rounded,
                      color: AppColors.antiFlashWhite, size: 30),
                  SizedBox(height: 5),
                  Text('Felhasználó',
                      style: TextStyle(
                          color: AppColors.antiFlashWhite, fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildUserStanding(),
          const SizedBox(height: 10),
          const Divider(
            color: AppColors.antiFlashWhite,
            indent: 30,
            endIndent: 30,
            thickness: 2,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: _buildStandings(),
            ),
          ),
        ],
      ),
    );
  }
}
