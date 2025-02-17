// HomePage widget that displays the user's tasks in categorized sections
// and allows the user to navigate to the details page of a task

import 'package:flutter/material.dart';
import 'package:logolda/screens/profile_page.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/firebase/auth_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logolda/models/task.dart';
import 'package:logolda/screens/details_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<List<Task>> _userTasks;
  late Map<String, List<Task>> _categorizedTasks = {};
  final Map<String, int> _categorizedTasksAmount = {
    'Esedékes': 0,
    'Közelgő': 0,
    'Függő': 0,
    'Lejárt': 0,
    'Kesz': 0,
  };

  @override
  void initState() {
    super.initState();
    _userTasks = _fetchAndCategorizeUserTasks();
  }

  Future<List<Task>> _fetchAndCategorizeUserTasks() async {
    final userId =
        _authService.getLoggedInUser()?.uid; // Get the current user's ID
    if (userId == null) return [];

    final tasks = await _fetchUserTasks(userId); // Fetch the user's tasks
    setState(() {
      _categorizedTasks = _categorizeTasksByDate(tasks); // Categorize the tasks
    });
    _updateCategorizedTasksAmount();
    return tasks;
  }

  Future _updateCategorizedTasksAmount() async {
    for (var entry in _categorizedTasks.entries) {
      _categorizedTasksAmount[entry.key] = entry.value.length;
    }
  }

  Future<List<Task>> _fetchUserTasks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('Tasks')
          .where('uid', isEqualTo: userId)
          .get();
      return querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      _showSnackBar('Error fetching tasks: $e');
      return [];
    }
  }

  Map<String, List<Task>> _categorizeTasksByDate(List<Task> tasks) {
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);
    final plusThreeDays = currentDate.add(const Duration(days: 3));
    final dateFormatter = DateFormat('yyyy-MM-dd');

    final todayTasks = <Task>[];
    final threeDaysLaterTasks = <Task>[];
    final futureTasks = <Task>[];
    final pastTasks = <Task>[];
    final doneTasks = <Task>[];

    for (var task in tasks) {
      final startDateString = task.startDate;
      final dueDateString = task.dueDate;
      if (startDateString == null ||
          startDateString.isEmpty ||
          dueDateString == null ||
          dueDateString.isEmpty) continue;

      try {
        final taskStartDate = dateFormatter.parse(startDateString);
        final taskDueDate = dateFormatter.parse(dueDateString);

        if (task.isDone) {
          doneTasks.add(task);
        } else if ((taskStartDate.isBefore(currentDate) &&
                taskDueDate.isAfter(currentDate)) ||
            taskStartDate == currentDate) {
          todayTasks.add(task);
        } else if ((taskStartDate.isAfter(currentDate) &&
                taskStartDate.isBefore(plusThreeDays)) ||
            taskStartDate == plusThreeDays) {
          threeDaysLaterTasks.add(task);
        } else if (taskStartDate.isAfter(plusThreeDays)) {
          futureTasks.add(task);
        } else if (taskDueDate.isBefore(currentDate)) {
          pastTasks.add(task);
        }
      } catch (e) {
        _showSnackBar(
            "Invalid date format for task '${task.title}': $startDateString");
      }
    }

    return {
      'Esedékes': todayTasks,
      'Közelgő': threeDaysLaterTasks,
      'Függő': futureTasks,
      'Lejárt': pastTasks,
      'Kesz': doneTasks,
    };
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
            const LocalDateDisplay(),
            FutureBuilder<List<Task>>(
              future: _userTasks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData ||
                    snapshot.data!.isEmpty ||
                    snapshot.data!.every((task) => task.isDone)) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        padding: const EdgeInsets.all(16),
                        decoration:
                            customBoxDeoration(AppColors.antiFlashWhite, 18),
                        child: Text('Hozd létre saját eseményeidet!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.spaceCadet)),
                      ),
                      Divider(
                        color: AppColors.antiFlashWhite,
                        thickness: 2,
                        indent: 35,
                        endIndent: 35,
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Az eseményeket kategóriákba rendezheted! Ne felejtsd el létrehozni a kategóriákat is, ha korábban még nem tetted!',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.antiFlashWhite),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Create new task button
                          _buildActionButtons(
                              const Icon(Icons.add_circle_outline_rounded,
                                  color: AppColors.antiFlashWhite, size: 50),
                              'Új esemény', () async{
                            Navigator.pushNamed(context, '/create');
                          }),
                          // Create new category button
                          _buildActionButtons(
                              const Icon(Icons.add_circle_outline_rounded,
                                  color: AppColors.antiFlashWhite, size: 50),
                              'Új kategória', () async {
                            Navigator.pushNamed(context, '/category');
                          }),
                        ],
                      ),
                    ],
                  );
                } else {
                  return _buildTaskCategories();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle,
              color: AppColors.antiFlashWhite, size: 60),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfilePage(
                        categorizedTasksAmount: _categorizedTasksAmount,
                      )),
            );
          },
        ),
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

  Widget _buildTaskCategories() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _categorizedTasks.entries
            .where((entry) => entry.key != 'Kesz')
            .map((entry) {
          return TaskCategorySection(title: entry.key, tasks: entry.value);
        }).toList(),
      ),
    );
  }
}

Widget _buildActionButtons(Icon icon, String title, Function onPressed) {
  return Column(
    children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: customBoxDeoration(AppColors.coolGrey, 18),
        child: IconButton(
          icon: icon,
          onPressed: onPressed as void Function()?,
          style: _buttonStyle(AppColors.coolGrey),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        title,
        style: const TextStyle(fontSize: 16, color: AppColors.antiFlashWhite),
      ),
    ],
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
    default:
      return AppColors.antiFlashWhite;
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
  bool _isExpanded = false;

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
        decoration: customBoxDeoration(getColorBasedOnStatus(widget.title), 18),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ExpansionTile(
            title: Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.coolGrey,
                size: 50),
            onExpansionChanged: (bool expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            children: widget.tasks.map((task) {
              return Container(
                margin: const EdgeInsets.all(12),
                // padding: const EdgeInsets.symmetric(horizontal: 24.0),
                decoration: customBoxDeoration(AppColors.coolGrey, 18),
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
                            builder: (context) => TaskDetailsPage(
                                task: task, title: widget.title)),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class LocalDateDisplay extends StatelessWidget {
  const LocalDateDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current date and format it
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 100, color: AppColors.antiFlashWhite.withOpacity(0.2)),
          Text(
            currentDate,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.antiFlashWhite),
          ),
        ],
      ),
    );
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

ButtonStyle _buttonStyle(Color color) {
  return ElevatedButton.styleFrom(
    elevation: 10,
    shadowColor: Colors.black.withOpacity(0.8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    padding: const EdgeInsets.all(16),
    backgroundColor: color,
  );
}
