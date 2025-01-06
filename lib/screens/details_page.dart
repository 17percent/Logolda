import 'package:flutter/material.dart';
import 'package:logolda/screens/modify_page.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/models/task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailsPage extends StatefulWidget {
  const TaskDetailsPage({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
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
                    // Taking user to Home page
                    await Navigator.pushReplacementNamed(context, '/home');
                    // Sending info to screen
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
            onPressed: () async {
              await Navigator.pushReplacementNamed(context, '/home');
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
                decoration: const BoxDecoration(
                  border: Border(
                    bottom:
                        BorderSide(color: AppColors.antiFlashWhite, width: 2),
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
                buildActionButtons(),
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
            onPressed: () {},
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
                    location: _task.location,
                    startDate: _task.startDate,
                    startTime: _task.startTime,
                    dueDate: _task.dueDate,
                    dueTime: _task.dueTime,
                    category: _task.category,
                    difficulty: _task.difficulty,
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

  Future<void> deleteTask(String id) async {
    try {
      await _firestore.collection('Tasks').doc(id).delete();
    } catch (e) {
      _showSnackBar('Error deleting task: $e');
    }
  }
}

Container buildTaskDetailsContainer(String title, String value) {
  return Container(
    margin: const EdgeInsets.all(10),
    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
    decoration: customBoxDeoration(AppColors.antiFlashWhite, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            color: AppColors.coolGrey,
          ),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.antiFlashWhite)),
        ),
        const SizedBox(width: 10),
        Text(value,
            style: const TextStyle(fontSize: 16, color: AppColors.spaceCadet)),
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
