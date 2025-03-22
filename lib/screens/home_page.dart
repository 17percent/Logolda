import 'package:flutter/material.dart';
import 'package:logolda/screens/profile_page.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/util/styles.dart';
import 'package:logolda/util/alerts.dart';
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

  String? _selectedFilter;

  late Future<List<Task>> _userTasks;
  late Map<String, List<Task>> _categorizedTasksByDate = {};
  late Map<String, List<Task>> _categorizedTasksByCategory = {};
  late Map<String, List<Task>> _categorizedTasksByDiff = {};
  final Map<String, int> _categorizedTasksAmount = {
    'Esedékes': 0,
    'Közelgő': 0,
    'Függő': 0,
    'Lejárt': 0,
    'Kész': 0,
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
      _categorizedTasksByDate =
          _categorizeTasksByDate(tasks); // Categorize the tasks by Date
      _categorizedTasksByCategory =
          _categorizeTasksByCategory(tasks); // Categorize the tasks by Category
      _categorizedTasksByDiff =
          _categorizeTasksByDiff(tasks); // Categorize the tasks by Difficulty
    });
    _updateCategorizedTasksAmount();
    return tasks;
  }

  Future _updateCategorizedTasksAmount() async {
    for (var entry in _categorizedTasksByDate.entries) {
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
        if (mounted) {
          AppAlerts.showSnackBar(context, 'Error fetching tasks: $e');
        }
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
        AppAlerts.showSnackBar(context, 
            "Invalid date format for task '${task.title}': $startDateString");
      }
    }

    return {
      'Esedékes': todayTasks,
      'Közelgő': threeDaysLaterTasks,
      'Függő': futureTasks,
      'Lejárt': pastTasks,
      'Kész': doneTasks,
    };
  }

  Map<String, List<Task>> _categorizeTasksByCategory(List<Task> tasks) {
    final categorizedTasks = <String, List<Task>>{};
    for (var task in tasks) {
      final isDone = task.isDone;
      final category = task.category;
      if (category.isEmpty) continue;

      if (categorizedTasks.containsKey(category) && !isDone) {
        categorizedTasks[category]!.add(task);
      } else if (!isDone) {
        categorizedTasks[category] = [task];
      }
    }
    return categorizedTasks;
  }

  Map<String, List<Task>> _categorizeTasksByDiff(List<Task> tasks) {
    final categorizedTasks = <String, List<Task>>{};
    for (var task in tasks) {
      final isDone = task.isDone;
      final diff = task.difficulty;
      if (diff.isEmpty) continue;

      if (categorizedTasks.containsKey(diff) && !isDone) {
        categorizedTasks[diff]!.add(task);
      } else if (!isDone) {
        categorizedTasks[diff] = [task];
      }
    }
    return categorizedTasks;
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
            Container(
                margin: const EdgeInsets.fromLTRB(30, 10, 30, 30),
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Szűrés',
                    style: TextStyle(
                        color: AppColors.antiFlashWhite, fontSize: 24)),
                Row(
                  children: [
                    _buildActionButtons(
                      const Icon(Icons.calendar_month_rounded, color: AppColors.antiFlashWhite, size: 36),
                      () {
                      setState(() {
                        _selectedFilter = 'Dátum';
                      });
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildActionButtons(
                      const Icon(Icons.category_rounded, color: AppColors.antiFlashWhite, size: 36),
                      () {
                      setState(() {
                        _selectedFilter = 'Katgeória';
                      });
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildActionButtons(
                      const Icon(Icons.speed_rounded, color: AppColors.antiFlashWhite, size: 36),
                      () {
                      setState(() {
                        _selectedFilter = 'Nehézség';
                      });
                      },
                    ),
                  ],
                ),
              ],
            )),
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
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                        decoration: AppStyles.customBoxDecoration(
                            AppColors.antiFlashWhite, 18),
                        child: const Text('Indulhat a logolás!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: AppColors.spaceCadet),
                            textAlign: TextAlign.center),
                      ),
                      const Divider(
                        color: AppColors.antiFlashWhite,
                        thickness: 2,
                        indent: 45,
                        endIndent: 45,
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                              child: const Text(
                                  'Az első lépések megkezdéséhez tekintsd meg a bevezetőt!',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: AppColors.antiFlashWhite),
                                  textAlign: TextAlign.center),
                            ),
                            const SizedBox(height: 10),
                            _buildActionButtons(
                                const Icon(Icons.school_rounded,
                                    color: AppColors.antiFlashWhite,
                                    size: 50), () async {
                              Navigator.pushNamed(context, '/intro');
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (_selectedFilter == 'Katgeória') {
                  return _buildTaskCategories(_categorizedTasksByCategory);
                } else if (_selectedFilter == 'Nehézség') {
                  return _buildTaskCategories(_categorizedTasksByDiff);
                } else {
                  return _buildTaskCategories(_categorizedTasksByDate);
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
          _buildDrawerItem('Bevezető', Icons.school_rounded,
              () => Navigator.pushNamed(context, '/intro')),
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

  Widget _buildTaskCategories(Map<String, List<Task>> categorizedTasks) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categorizedTasks.entries
            .where((entry) => entry.key != 'Kész')
            .map((entry) {
          return TaskCategorySection(title: entry.key, tasks: entry.value);
        }).toList(),
      ),
    );
  }
}

Widget _buildActionButtons(Icon icon, Function onPressed) {
  return Column(
    children: [
      Container(
        decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
        child: IconButton(
          icon: icon,
          onPressed: onPressed as void Function()?,
          style: AppStyles.customButtonStyle(AppColors.coolGrey),
        ),
      ),
    ],
  );
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
        decoration: AppStyles.customBoxDecoration(
            AppStyles.getColorBasedOnStatus(widget.title), 18),
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
                decoration:
                    AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
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
