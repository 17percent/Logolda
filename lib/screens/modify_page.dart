import 'package:flutter/material.dart';
import 'package:logolda/firebase/auth_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/util/styles.dart';
import 'package:logolda/util/alerts.dart';
import 'package:logolda/services/noti_service.dart';

class ModifyPage extends StatefulWidget {
  final String taskId;

  const ModifyPage({super.key, required this.taskId});

  @override
  State<ModifyPage> createState() => _ModifyPageState();
}

class _ModifyPageState extends State<ModifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _notiService = NotiService();

  var _categories = [];
  Map<String, int> _difficultiesAndScores = {};
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDifficulty;
  bool _isLoadingCategories = true;
  bool _isLoadingDifficulties = true;
  DateTime? _startDate;
  String? _startTime;
  DateTime? _dueDate;
  String? _dueTime;
  int? _notificationId;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchDifficultiesAndScores();
    _loadTaskData();
  }

  Future<void> _loadTaskData() async {
    DocumentSnapshot task = await FirebaseFirestore.instance
        .collection('Tasks')
        .doc(widget.taskId)
        .get();
    if (task.exists) {
      setState(() {
        _titleController.text = task['title'];
        _descriptionController.text = task['description'];
        _locationController.text = task['location'];
        _startDate = DateTime.parse(task['startDate']);
        _startTime = task['startTime'];
        _dueDate = DateTime.parse(task['dueDate']);
        _dueTime = task['dueTime'];
        _selectedCategory = task['category'];
        _selectedDifficulty = task['difficulty'];
        _notificationId = task['notificationId'];
      });
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      if (_titleController.text.isEmpty ||
          _descriptionController.text.isEmpty ||
          _locationController.text.isEmpty ||
          _selectedCategory == null ||
          _selectedDifficulty == null) {
        AppAlerts.showSnackBar(context, 'Minden mező kitöltése kötelező!');
        return;
      }

      if (_startDate!.isAfter(_dueDate!) || 
          (_startDate!.day == _dueDate!.day &&
              60 * int.parse(_startTime!.substring(0, 2)) +
              int.parse(_startTime!.substring(3, 5)) >
              60 * int.parse(_dueTime!.substring(0, 2)) +
              int.parse(_dueTime!.substring(3, 5)))) {
        AppAlerts.showSnackBar(
            context, "Az esemény nem kezdőthet később a határidőnél!");
        return;
      }

      try {
        // Canceling the old notification
        await _notiService.cancelNotification(_notificationId!);

        // Scheduling a new notification
        final scheduledDate =
            DateTime.parse(_startDate!.toIso8601String().substring(0, 10));
        final timeParts = _startTime!.split(':');
        final scheduledTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
        final scheduledDateTime = DateTime(
                scheduledDate.year,
                scheduledDate.month,
                scheduledDate.day,
                scheduledTime.hour,
                scheduledTime.minute)
            .subtract(const Duration(minutes: 30));

        await _notiService.scheduleNotification(
          title: _titleController.text.trim(),
          body:
              'Hamarosan kezdődik az esemény! Tekintsd meg az alkalmazásban! ',
          scheduledDate: scheduledDateTime,
          id: _notificationId,
        );

        // adding task to database
        await _firestore.collection('Tasks').doc(widget.taskId).update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'startDate': _startDate!.toIso8601String().substring(0, 10),
          'startTime': _startTime,
          'dueDate': _dueDate!.toIso8601String().substring(0, 10),
          'dueTime': _dueTime,
          'category': _selectedCategory,
          'difficulty': _selectedDifficulty,
          'notificationId': _notificationId,
        });
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/home', (Route<dynamic> route) => false);
        }
      } catch (e) {
        AppAlerts.showSnackBar(context, 'Error saving task: $e');
      }
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime? initialDate,
      ValueChanged<DateTime> onDatePicked) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      onDatePicked(pickedDate);
    }
  }

  static String _formatTimeOfDay(TimeOfDay time) =>
      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  Future<void> _pickTime(BuildContext context, String? initialTime,
      ValueChanged<String> onTimePicked) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      onTimePicked(_formatTimeOfDay(pickedTime));
    }
  }

  Future<void> fetchCategories() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Categories')
          .where('userId', isEqualTo: _authService.getLoggedInUser()?.uid)
          .get();
      setState(() {
        _categories =
            snapshot.docs.map((doc) => doc['name'] as String).toList();
        _isLoadingCategories = false; // Update loading state
      });
    } catch (e) {
      AppAlerts.showSnackBar(context, 'Error fetching categories: $e');
      setState(() {
        _isLoadingCategories = false; // Stop loading spinner even on error
      });
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
        // sorting the map by value
        _difficultiesAndScores = Map.fromEntries(
          _difficultiesAndScores.entries.toList()
            ..sort((e1, e2) => e1.value.compareTo(e2.value)),
        );
        _isLoadingDifficulties = false; // Update loading state
      });
    } catch (e) {
      AppAlerts.showSnackBar(context, 'Error fetching difficulties: $e');
      setState(() {
        _isLoadingDifficulties = false; // Stop loading spinner even on error
      });
    }
  }

  Widget _buildDropDownForCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isLoadingCategories
            ? const CircularProgressIndicator(color: AppColors.springBud)
            : Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration:
                    AppStyles.customBoxDecoration(AppColors.antiFlashWhite, 18),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Icon(
                    Icons.category_rounded,
                    color: AppColors.coolGrey,
                    size: 50,
                  ),
                  items: _categories
                      .map<DropdownMenuItem<String>>((dynamic category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  dropdownColor: AppColors.antiFlashWhite,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.coolGrey),
                  iconSize: 50,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: "Michroma"),
                  isExpanded: true,
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropDownForDifficulties() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isLoadingDifficulties
            ? const CircularProgressIndicator(color: AppColors.springBud)
            : Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration:
                    AppStyles.customBoxDecoration(AppColors.antiFlashWhite, 18),
                child: DropdownButton<String>(
                  value: _selectedDifficulty,
                  hint: const Icon(
                    Icons.speed_rounded,
                    color: AppColors.coolGrey,
                    size: 50,
                  ),
                  items: _difficultiesAndScores.keys
                      .map<DropdownMenuItem<String>>((dynamic diff) {
                    return DropdownMenuItem<String>(
                      value: diff,
                      child: Text(diff),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDifficulty = newValue;
                    });
                  },
                  dropdownColor: AppColors.antiFlashWhite,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.coolGrey),
                  iconSize: 50,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: "Michroma"),
                  isExpanded: true,
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDateTimePicker(
    BuildContext context,
    DateTime? date,
    String? time,
    ValueChanged<DateTime> onDatePicked,
    ValueChanged<String> onTimePicked,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              decoration:
                  AppStyles.customBoxDecoration(AppColors.antiFlashWhite, 18),
              child: ElevatedButton(
                onPressed: () => _pickDate(context, date, onDatePicked),
                style: AppStyles.customButtonStyle(AppColors.antiFlashWhite),
                child: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.coolGrey, size: 50),
              ),
            ),
            const SizedBox(width: 20),
            Container(
              decoration:
                  AppStyles.customBoxDecoration(AppColors.antiFlashWhite, 18),
              child: ElevatedButton(
                onPressed: () => _pickTime(context, time, onTimePicked),
                style: AppStyles.customButtonStyle(AppColors.antiFlashWhite),
                child: const Icon(Icons.schedule_rounded,
                    color: AppColors.coolGrey, size: 50),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateTimeText(date?.toIso8601String().substring(0, 10)),
            _buildDateTimeText(time),
          ],
        ),
      ],
    );
  }

   Widget _buildDateTimeText(String? text) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Text(
        text ?? '',
        style: const TextStyle(color: AppColors.antiFlashWhite, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceCadet,
      appBar: AppBar(
        backgroundColor: AppColors.coolGrey,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left_outlined,
              size: 60, color: AppColors.antiFlashWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.edit_rounded,
                      size: 100,
                      color: AppColors.antiFlashWhite.withOpacity(0.2)),
                  const Text('Módosítás',
                      style: TextStyle(
                          fontSize: 28, color: AppColors.antiFlashWhite)),
                ],
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Cím'),
                  _buildTextField(_titleController, 'Esemény címe'),
                  const SizedBox(height: 16),
                  _buildLabel('Leírás'),
                  _buildTextField(_descriptionController, 'Esemény leírása',
                      maxLines: 5),
                  const SizedBox(height: 16),
                  _buildLabel('Helyszín'),
                  _buildTextField(_locationController, 'Esemény helyszíne'),
                  const SizedBox(height: 16),
                  _buildLabel('Kezdő időpont'),
                  _buildDateTimePicker(
                    context,
                    _startDate,
                    _startTime,
                    (date) => setState(() => _startDate = date),
                    (time) => setState(() => _startTime = time),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Záró időpont'),
                  _buildDateTimePicker(
                    context,
                    _dueDate,
                    _dueTime,
                    (date) => setState(() => _dueDate = date),
                    (time) => setState(() => _dueTime = time),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Kategória"),
                      _buildDropDownForCategories(),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Nehézség"),
                      _buildDropDownForDifficulties(),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: Container(
                        decoration: AppStyles.customBoxDecoration(
                            AppColors.springBud, 18),
                        child: ElevatedButton(
                          onPressed: _saveTask,
                          style:
                              AppStyles.customButtonStyle(AppColors.springBud),
                          child: const Icon(Icons.save_rounded,
                              size: 50, color: AppColors.spaceCadet),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text,
          style:
              const TextStyle(color: AppColors.antiFlashWhite, fontSize: 20)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Container(
      decoration: AppStyles.customBoxDecoration(AppColors.antiFlashWhite, 18),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.coolGrey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.coolGrey, width: 3.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:
                const BorderSide(color: AppColors.springBud, width: 3.0),
          ),
          fillColor: AppColors.antiFlashWhite,
          filled: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
