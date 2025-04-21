import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/util/styles.dart';
import 'package:logolda/util/alerts.dart';
import 'package:logolda/firebase/auth_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logolda/services/noti_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _notiService = NotiService();
  String? _currentUserId;
  var _categories = [];
  var _difficulties = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDifficulty;
  bool _isLoadingCategories = true;
  bool _isLoadingDifficulties = true;
  DateTime? _startDate = DateTime.now();
  TimeOfDay? _startTime = TimeOfDay.now();
  DateTime? _dueDate = DateTime.now();
  TimeOfDay? _dueTime = TimeOfDay.now();

  static String _formatTimeOfDay(TimeOfDay time) =>
      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchDifficulties();
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

  Future<void> _pickTime(BuildContext context, TimeOfDay? initialTime,
      ValueChanged<TimeOfDay> onTimePicked) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      onTimePicked(pickedTime);
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

  Future<void> fetchDifficulties() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Difficulties').get();
      setState(() {
        _difficulties = snapshot.docs
            .map((doc) =>
                {'name': doc['name'] as String, 'value': doc['value'] as int})
            .toList();
        _difficulties.sort((a, b) => a['value'].compareTo(b['value']));
        _difficulties =
            _difficulties.map((item) => item['name'] as String).toList();
        _isLoadingDifficulties = false; // Update loading state
      });
    } catch (e) {
      AppAlerts.showSnackBar(context, 'Error fetching difficulties: $e');
      setState(() {
        _isLoadingDifficulties = false; // Stop loading spinner even on error
      });
    }
  }

  Future<void> _addTaskToFirestore() async {
    final taskTitle = _titleController.text.trim();
    final taskDescription = _descriptionController.text.trim();
    final taskLocation = _locationController.text.trim();
    final taskStartDate = _startDate?.toIso8601String().substring(0, 10);
    final taskDueDate = _dueDate?.toIso8601String().substring(0, 10);
    final taskStartTime = _formatTimeOfDay(_startTime!);
    final taskDueTime = _formatTimeOfDay(_dueTime!);


    if (taskTitle.isEmpty ||
        taskDescription.isEmpty ||
        taskLocation.isEmpty ||
        _selectedCategory == null ||
        _selectedDifficulty == null) {
      AppAlerts.showSnackBar(context, 'Minden mező kitöltése kötelező!');
      return;
    }

    if (_startDate!.isAfter(_dueDate!) || 
      (taskStartDate!.compareTo(taskDueDate!) == 0 && (60 * _startTime!.hour + _startTime!.minute) > (60 *_dueTime!.hour + _dueTime!.minute))) {
      AppAlerts.showSnackBar(context, "Az esemény nem kezdőthet később a határidőnél!");
      return;
    }

    try {
      // Creating new document for task
      final docRef = _firestore.collection('Tasks').doc();

      // Scheduling notification for task
      final scheduledDate = DateTime.parse('$taskStartDate');
      final timeParts = taskStartTime.split(':');
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
          id: docRef.id.hashCode,
          title: taskTitle,
          body:
              'Hamarosan kezdődik az esemény! Tekintsd meg az alkalmazásban! ',
          scheduledDate: scheduledDateTime);

      // Adding task to Firestore
      await docRef.set({
        'docid': docRef.id,
        'uid': _currentUserId,
        'title': taskTitle,
        'description': taskDescription,
        'location': taskLocation,
        'startDate': taskStartDate,
        'startTime': taskStartTime,
        'dueDate': taskDueDate,
        'dueTime': taskDueTime,
        'category': _selectedCategory,
        'difficulty': _selectedDifficulty,
        'notificationId': docRef.id.hashCode,
        'isDone': false
      });

      if (mounted) {
        // Taking user to Home page
        Navigator.pushReplacementNamed(context, '/home');
        // Sending info to screen
        AppAlerts.showSnackBar(context, "Sikeres létrehozás!");
      }
    } catch (e) {
      AppAlerts.showSnackBar(context, 'Failed to add task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _currentUserId = _authService.getLoggedInUser()?.uid;

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
                  Icon(Icons.add_task_rounded,
                      size: 100,
                      color: AppColors.antiFlashWhite.withOpacity(0.2)),
                  const Text('Új esemény',
                      style: TextStyle(
                          fontSize: 28, color: AppColors.antiFlashWhite)),
                ],
              ),
            ),
            Column(
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
                        onPressed: _addTaskToFirestore,
                        style: AppStyles.customButtonStyle(AppColors.springBud),
                        child: const Icon(Icons.save_rounded,
                            color: AppColors.spaceCadet, size: 50),
                      ),
                    ),
                  ),
                ),
              ],
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
                  items: _difficulties
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
    TimeOfDay? time,
    ValueChanged<DateTime> onDatePicked,
    ValueChanged<TimeOfDay> onTimePicked,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateTimeText(date?.toIso8601String().substring(0, 10)),
            _buildDateTimeText(_formatTimeOfDay(time!)),
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
}
