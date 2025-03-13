import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/firebase/auth_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.categorizedTasksAmount = const {}});

  final Map<String, int> categorizedTasksAmount;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, int> _categorizedTasksAmount;

  @override
  void initState() {
    super.initState();
    _categorizedTasksAmount = widget.categorizedTasksAmount;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getLoggedInUser();

    return Scaffold(
      backgroundColor: AppColors.spaceCadet,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(color: AppColors.antiFlashWhite, fontSize: 28),
        ),
        centerTitle: true,
        backgroundColor: AppColors.coolGrey,
        toolbarHeight: 80,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.arrow_circle_left_outlined,
                  size: 60, color: AppColors.antiFlashWhite),
              onPressed: () {
                Navigator.pop(context);
              },
              // Acessibility feature
              // tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<DocumentSnapshot>(
          // Fetch user-specific document from Firestore
          future: _firestore.collection('Users').doc(currentUser?.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator()); // Show loading indicator
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error fetching user data!'));
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              // Extract user data
              final userData = snapshot.data!.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(children: [
                          const Icon(Icons.account_circle,
                              color: AppColors.antiFlashWhite, size: 140),
                          const SizedBox(height: 10),
                          Text(
                            '${userData['name']}',
                            style: const TextStyle(
                                fontSize: 24, color: AppColors.antiFlashWhite),
                          ),
                        ]),
                        const SizedBox(width: 50),
                        Column(
                          children: [
                            const Text(
                              'Rank',
                              style: TextStyle(
                                  color: AppColors.antiFlashWhite,
                                  fontSize: 20),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              alignment: Alignment.center,
                              width: 150,
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                              decoration: customBoxDeoration(
                                  AppColors.antiFlashWhite, 18),
                              child: Text(
                                '${userData['rank']}',
                                style: const TextStyle(
                                    color: AppColors.spaceCadet, fontSize: 20),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Seeds',
                              style: TextStyle(
                                  color: AppColors.antiFlashWhite,
                                  fontSize: 20),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 150,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                              decoration: customBoxDeoration(
                                  AppColors.antiFlashWhite, 18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.spa_rounded,
                                      color: AppColors.coolGrey),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${userData['seeds'].floor()}',
                                    style: const TextStyle(
                                        color: AppColors.spaceCadet,
                                        fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Divider(
                      color: AppColors.antiFlashWhite,
                      thickness: 2,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Feladatok',
                      style: TextStyle(
                          color: AppColors.antiFlashWhite, fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    buildTaskRows(_categorizedTasksAmount),
                  ],
                ),
              );
            }

            return const Center(child: Text('No user data found!'));
          },
        ),
      ),
    );
  }
}

Widget buildTaskRows(Map<String, int> tasks) {
  return Column(
    children: tasks.entries.map((entry) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        padding: const EdgeInsets.all(16),
        decoration: customBoxDeoration(getColorBasedOnStatus(entry.key), 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              entry.key,
              style: const TextStyle(
                color: AppColors.spaceCadet,
                fontSize: 18,
              ),
            ),
            Text(
              entry.value.toString(),
              style: const TextStyle(
                color: AppColors.spaceCadet,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

Color getColorBasedOnStatus(String status) {
  switch (status) {
    case 'Esedékes':
      return AppColors.amethystPurple;
    case 'Közelgő':
      return AppColors.goldYellow;
    case 'Függő':
      return AppColors.orangePeel;
    case 'Lejárt':
      return AppColors.pantoneRed;
    case 'Kész':
      return AppColors.springBud;
    default:
      return AppColors.antiFlashWhite;
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
