import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/firebase/auth_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logolda/models/task.dart';
import 'package:logolda/screens/details_page.dart';
// import 'package:intl/intl.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<List<Task>> _userTasks;

  @override
  void initState() {
    super.initState();
    _userTasks = _fetchUserTasks();
  }

  Future<List<Task>> _fetchUserTasks() async {
    final userId = _authService.getLoggedInUser()?.uid;
    try {
      final querySnapshot = await _firestore
          .collection('Tasks')
          .where('uid', isEqualTo: userId)
          .where('isDone', isEqualTo: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _showSnackBar('Error fetching tasks: $e');
      return [];
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceCadet,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Page title
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(32),
                child: const Text('Archívum',
                    style: TextStyle(
                        fontSize: 28, color: AppColors.antiFlashWhite))),
            FutureBuilder<List<Task>>(
              future: _userTasks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Nincs megjeleníthető esemény.',
                      style: TextStyle(color: AppColors.antiFlashWhite));
                } else {
                  final tasks = snapshot.data!;
                  return TaskCategorySection(title: 'Kész', tasks: tasks);
                }
              },
            )
          ],
        ),
      ),
    );
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
              () => Navigator.pop(context)),
          _buildDrawerItem('Archívum', Icons.archive_rounded,
              () => Navigator.pushNamed(context, '/archive')),
          _buildDrawerItem('Eredménytábla', Icons.leaderboard_rounded, () {}),
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
      leading: Icon(icon, color: AppColors.spaceCadet),
      title: Text(title,
          style: const TextStyle(color: AppColors.spaceCadet, fontSize: 16)),
      onTap: onTap,
    );
  }
}

class TaskCategorySection extends StatefulWidget {
  final String title;
  final List<Task> tasks;

  const TaskCategorySection(
      {super.key, required this.title, required this.tasks});

  @override
  State<TaskCategorySection> createState() => _TaskCategorySectionState();
}

class _TaskCategorySectionState extends State<TaskCategorySection> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: customBoxDeoration(AppColors.springBud),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            title: Text(
              widget.title,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            showTrailingIcon: false,
            initiallyExpanded: true,
            enabled: false,
            children: widget.tasks.map((task) {
              return customContainerForArchivedTasks(task, context);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

BoxDecoration customBoxDeoration(Color color) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(8),
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

Container customContainerForArchivedTasks(Task task, BuildContext context) {
  return Container(
    margin: const EdgeInsets.all(12),
    // padding: const EdgeInsets.symmetric(horizontal: 24.0),
    decoration: customBoxDeoration(AppColors.coolGrey),
    child: ListTile(
      title: Text(task.title,
          style: const TextStyle(color: AppColors.antiFlashWhite)),
      trailing: IconButton(
        icon: const Icon(Icons.read_more_rounded,
            color: AppColors.antiFlashWhite, size: 40),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TaskDetailsPage(task: task, title: "Kész",)),
          );
        },
      ),
    ),
  );
}
