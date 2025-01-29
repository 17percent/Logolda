import 'package:flutter/material.dart';
import 'package:logolda/screens/modify_page.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/models/task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logolda/firebase/auth_handler.dart';

class TaskDetailsPage extends StatefulWidget {
  const TaskDetailsPage({super.key, required this.task, required this.title});

  final Task task;
  final String title;

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  Map<String, int> _difficultiesAndScores = {};
  late Task _task;
  late String _title;

  @override
  void initState() {
    super.initState();
    fetchDifficultiesAndScores();
    _task = widget.task;
    _title = widget.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceCadet,
      appBar: AppBar(
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.antiFlashWhite, size: 60),
              onPressed: () async {
                bool? confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Törlés megerősítése',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      content: const Text('Biztosan törlöd ezt az eseményt?'),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.coolGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Mégse',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.antiFlashWhite)),
                            )),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.coolGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Törlés',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.antiFlashWhite)),
                            )),
                      ],
                    );
                  },
                );

                if (confirmDelete == true) {
                  await deleteTask(widget.task.id);
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home', (Route<dynamic> route) => false);
                    _showSnackBar("Sikeres törlés!");
                  }
                }
              }),
        ],
        backgroundColor: AppColors.coolGrey,
        toolbarHeight: 80,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined,
                size: 60, color: AppColors.antiFlashWhite),
            onPressed: () {
              Navigator.of(context).pop();
            },
            // Acessibility feature
            // tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        }),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task title
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 10),
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: getColorBasedOnStatus(_title), width: 2),
                  ),
                ),
                child: Text(_task.title,
                    style: const TextStyle(
                        fontSize: 28, color: AppColors.antiFlashWhite))),
            const SizedBox(height: 10),
            // Task description
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(_task.description,
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.antiFlashWhite)),
            ),
            const SizedBox(height: 30),
            // Task details
            Column(
              children: [
                buildTaskDetailsContainer('Helyszín ', _task.location),
                buildTaskDetailsContainer(
                    'Kezdő dátum ', _task.startDate ?? 'N/A'),
                buildTaskDetailsContainer(
                    'Kezdő időpont ', _task.startTime ?? 'N/A'),
                buildTaskDetailsContainer(
                    'Záró dátum ', _task.dueDate ?? 'N/A'),
                buildTaskDetailsContainer(
                    'Záró időpont ', _task.dueTime ?? 'N/A'),
                buildTaskDetailsContainer('Kategória ', _task.category),
                buildTaskDetailsContainer('Nehézség ', _task.difficulty),
                const SizedBox(height: 30),
                if (!_task.isDone) buildActionButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Row buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Check button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: customBoxDeoration(AppColors.springBud, 18),
          child: IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 55),
            onPressed: () async {
              await markTaskAsDone(widget.task.id);
              await updateUserScore();
            },
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(90, 80),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Edit button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: customBoxDeoration(AppColors.coolGrey, 18),
          child: IconButton(
            icon: const Icon(Icons.edit, size: 50),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ModifyPage(taskId: widget.task.id)),
              );
              if (result != null) {
                setState(() {
                  _task = Task(
                    id: widget.task.id,
                    title: result['title'],
                    description: result['description'],
                    location: result['location'],
                    startDate: result['startDate'],
                    startTime: result['startTime'],
                    dueDate: result['dueDate'],
                    dueTime: result['dueTime'],
                    category: result['category'],
                    difficulty: result['difficulty'],
                    isDone: result['isDone'],
                  );
                });
              }
            },
            color: AppColors.antiFlashWhite,
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(90, 80),
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Mark task as done
  Future<void> markTaskAsDone(String taskId) async {
    try {
      await _firestore.collection('Tasks').doc(taskId).update({
        'isDone': true,
      });
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (Route<dynamic> route) => false);
      }
      _showSnackBar("Sikeres archiválás!");
    } catch (e) {
      _showSnackBar('Sikertelen archiválás: $e');
    }
  }

  Future<void> updateUserScore() async {
    final userid = _authService.getLoggedInUser()?.uid;
    try {
      await _firestore.collection('Users').doc(userid).update({
        'seeds': FieldValue.increment(
            _difficultiesAndScores[_task.difficulty] as num),
      });
    } catch (e) {
      _showSnackBar('Error updating user score: $e');
    }
  }

  Future<void> fetchDifficultiesAndScores() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Difficulties').get();
      setState(() {
        _difficultiesAndScores = {
          for (var doc in snapshot.docs) doc['name']: doc['value']
        };
      });
    } catch (e) {
      _showSnackBar('Error fetching difficulties: $e');
      setState(() {});
    }
  }

  // Delete task
  Future<void> deleteTask(String id) async {
    try {
      await _firestore.collection('Tasks').doc(id).delete();
    } catch (e) {
      _showSnackBar('Error deleting task: $e');
    }
  }
}

Container buildTaskDetailsContainer(String taskTitle, String value) {
  return Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
    decoration: customBoxDeoration(AppColors.coolGrey, 8),
    child: Row(
      children: [
        Text(taskTitle,
            style:
                const TextStyle(fontSize: 16, color: AppColors.antiFlashWhite),
            softWrap: true,
            overflow: TextOverflow.visible),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.antiFlashWhite,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            alignment: Alignment.centerRight,
            child: Text(value,
                style:
                    const TextStyle(fontSize: 16, color: AppColors.spaceCadet),
                softWrap: true,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.right),
          ),
        ),
      ],
    ),
  );
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
