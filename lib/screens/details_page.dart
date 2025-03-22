import 'package:flutter/material.dart';
import 'package:logolda/screens/modify_page.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/util/styles.dart';
import 'package:logolda/util/alerts.dart';
import 'package:logolda/models/task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logolda/firebase/auth_handler.dart';
import 'package:logolda/services/noti_service.dart';
import 'package:logolda/services/textAnalytics_service.dart';

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
  final _notiService = NotiService();
  final _textAnalyticsService = TextanalyticsService();
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
                    return buildCustomAlertDialog(
                      'Törlés megerősítése',
                      'Biztosan törölni szeretnéd a feladatot?',
                      AppColors.pantoneRed,
                      const Icon(Icons.delete_forever_rounded,
                          color: AppColors.antiFlashWhite, size: 36),
                    );
                  },
                );
                if (confirmDelete == true) {
                  await _notiService
                      .cancelNotification(widget.task.notificationId);
                  await deleteTask(widget.task.id);
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
                padding: const EdgeInsets.only(bottom: 20),
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: AppStyles.getColorBasedOnStatus(_title), width: 2),
                  ),
                ),
                child: Text(_task.title,
                    style: const TextStyle(
                        fontSize: 28, color: AppColors.antiFlashWhite),
                    textAlign: TextAlign.center)),
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
                buildTaskDetailsContainer('Helyszín', _task.location),
                buildTaskDateAndTimeContainer(
                    'Kezdődik',
                    _task.startDate?.substring(2) ?? 'N/A',
                    '${_task.startTime ?? 'N/A'} ${DateTime.now().timeZoneName}'),
                buildTaskDateAndTimeContainer(
                    'Végződik',
                    _task.dueDate?.substring(2) ?? 'N/A',
                    '${_task.dueTime ?? 'N/A'} ${DateTime.now().timeZoneName}'),
                buildTaskDetailsContainer('Kategória', _task.category),
                buildTaskDetailsContainer('Nehézség', _task.difficulty),
                const SizedBox(height: 30),
                if (!_task.isDone) buildActionButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCustomAlertDialog(
      String title, String content, Color color, Icon icon) {
    return AlertDialog(
      title: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: Text(content),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
              child: const Icon(Icons.arrow_circle_left_outlined,
                  color: AppColors.antiFlashWhite, size: 36),
            )),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: AppStyles.customBoxDecoration(color, 18),
            child: icon,
          ),
        ),
      ],
    );
  }

  Row buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Check button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: AppStyles.customBoxDecoration(AppColors.springBud, 18),
          child: IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded, size: 50),
            onPressed: () async {
              bool? confirmCompletion = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return buildCustomAlertDialog(
                    'Archiválás megerősítése',
                    'Biztosan archiválni szeretnéd a feladatot?',
                    AppColors.springBud,
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.spaceCadet, size: 36),
                  );
                },
              );
              if (confirmCompletion == true) {
                await markTaskAsDone(widget.task.id);
                await updateUserScore();
              }
            },
            style: AppStyles.customButtonStyle(AppColors.springBud),
          ),
        ),
        const SizedBox(width: 10),
        // Edit button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
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
                    notificationId: result['notificationId'],
                    isDone: result['isDone'],
                  );
                });
              }
            },
            color: AppColors.antiFlashWhite,
            style: AppStyles.customButtonStyle(AppColors.coolGrey),
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
      await _notiService.cancelNotification(widget.task.notificationId);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (Route<dynamic> route) => false);
      }
      _showSnackBar("Sikeres archiválás!");
    } catch (e) {
      _showSnackBar('Sikertelen archiválás: $e');
    }
  }

  num calculateUserScore(String desc) {
    final smog = _textAnalyticsService.calculateSMOGIndex(desc);
    final cl = _textAnalyticsService.calculateColemanLiauIndex(desc);
    final diffScore = _difficultiesAndScores[_task.difficulty] as num;
    final weight = (smog + cl) / 2;
    final finalScore = diffScore * weight as num;
    return finalScore;
  }

  Future<void> updateUserScore() async {
    final userid = _authService.getLoggedInUser()?.uid;
    var finalScore = calculateUserScore(_task.description);
    if (finalScore <= 0) {
      finalScore = _difficultiesAndScores[_task.difficulty] as num;
    }
    try {
      await _firestore.collection('Users').doc(userid).update({
        'seeds': FieldValue.increment(finalScore),
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
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (Route<dynamic> route) => false);
      }
      _showSnackBar("Sikeres törlés!");
    } catch (e) {
      _showSnackBar('Sikertelen törlés: $e');
    }
  }
}

Container buildTaskDetailsContainer(String title, String value) {
  return Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.fromLTRB(10, 1, 0, 1),
    decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
    child: Row(
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 16, color: AppColors.antiFlashWhite)),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: AppColors.antiFlashWhite,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
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

Container buildTaskDateAndTimeContainer(
    String title, String date, String time) {
  return Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
    decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
    child: Row(
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 16, color: AppColors.antiFlashWhite)),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: AppColors.antiFlashWhite,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(date,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.spaceCadet),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.right),
                const Divider(color: AppColors.spaceCadet, thickness: 1),
                Text(time,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.spaceCadet),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.right),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
